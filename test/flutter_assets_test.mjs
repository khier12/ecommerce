import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {basename, dirname, join, resolve} from 'node:path';
import {requiredImageAssets, renderFlutterAssets, syncFlutterAssets} from '../tools/sync_flutter_assets.mjs';

const fontSection = `  fonts:
    - family: Montserrat
      fonts:
        - asset: assets/fonts/Montserrat.ttf
`;
const initialPubspec = `name: asset_fixture
flutter:
  uses-material-design: true
  assets:
    - assets/images/
${fontSection}`;

function bundledPaths(pubspec) {
  return pubspec.split(/\r?\n/)
    .map(line => line.match(/^    - ("assets\/images\/.*")$/)?.[1])
    .filter(Boolean)
    .map(value => JSON.parse(value));
}

function project(t, source, imageNames) {
  const root = mkdtempSync(join(tmpdir(), 'smooch-assets-'));
  t.after(() => {
    // Only remove the directly-created test directory inside the OS temp root.
    assert.equal(dirname(resolve(root)), resolve(tmpdir()));
    assert.ok(basename(root).startsWith('smooch-assets-'));
    rmSync(root, {recursive: true, force: true});
  });
  mkdirSync(join(root, 'lib'), {recursive: true});
  mkdirSync(join(root, 'assets/images'), {recursive: true});
  writeFileSync(join(root, 'lib/main.dart'), source);
  writeFileSync(join(root, 'pubspec.yaml'), initialPubspec);
  for (const name of imageNames) {
    writeFileSync(join(root, 'assets/images', name), `original image: ${name}`);
  }
  return root;
}

test('image extraction preserves apostrophes, ampersands, and both Dart quote styles', () => {
  const source = String.raw`
    const first = "assets/images/Hershey's Crinkles 1.png";
    const second = 'assets/images/Ham & Cheese.png';
    const repeated = 'assets/images/Hershey\'s Crinkles 1.png';
  `;
  assert.deepEqual(requiredImageAssets(source), [
    'assets/images/Ham & Cheese.png',
    "assets/images/Hershey's Crinkles 1.png",
  ]);
});

test('allowlist retains the logo and preload-only image references', () => {
  const source = `
    const product = 'assets/images/Latte.png';
    const preload = <String>{
      'assets/images/logo.png',
      'assets/images/landing1.png',
      'assets/images/Ice Blended Choco Hazelnut transparent.png',
    };
    final logo = rootBundle.load('assets/images/logo.png');
  `;
  const paths = requiredImageAssets(source);
  assert.equal(paths.length, 4);
  assert.ok(paths.includes('assets/images/logo.png'));
  assert.ok(paths.includes('assets/images/landing1.png'));
  assert.ok(paths.includes('assets/images/Ice Blended Choco Hazelnut transparent.png'));
});

test('rendering quotes filenames safely, preserves fonts, and is idempotent', () => {
  const paths = ["assets/images/Hershey's Crinkles 1.png", 'assets/images/Ham & Cheese.png'];
  const rendered = renderFlutterAssets(initialPubspec, paths);
  assert.deepEqual(bundledPaths(rendered), [...paths].sort());
  assert.ok(rendered.endsWith(fontSection));
  assert.ok(rendered.includes('  uses-material-design: true\n'));
  assert.equal(rendered.includes('    - assets/images/\n'), false);
  assert.equal(renderFlutterAssets(rendered, paths), rendered);
});

test('initial allowlist generation preserves CRLF line endings', () => {
  const original = initialPubspec.replaceAll('\n', '\r\n');
  const rendered = renderFlutterAssets(original, ['assets/images/Latte.png']);
  assert.equal(rendered.replaceAll('\r\n', '').includes('\n'), false);
  assert.ok(rendered.endsWith(fontSection.replaceAll('\n', '\r\n')));
  assert.equal(renderFlutterAssets(rendered, ['assets/images/Latte.png']), rendered);
});

for (const [label, requested] of [
  ['missing image', 'Missing.png'],
  ['incorrect filename case', 'latte.png'],
]) {
  test(`sync refuses ${label} before writing the pubspec`, t => {
    const root = project(t, `const image = 'assets/images/${requested}';`, ['Latte.png']);
    const file = join(root, 'pubspec.yaml');
    const before = readFileSync(file, 'utf8');
    assert.throws(() => syncFlutterAssets({projectRoot: root}), /missing image|case mismatch/i);
    assert.equal(readFileSync(file, 'utf8'), before);
  });
}

test('catalog changes are detected in check mode and sync without deleting originals', t => {
  const root = project(t, "const image = 'assets/images/Old.png';", ['Old.png', 'New.png']);
  const file = join(root, 'pubspec.yaml');
  const oldOriginal = readFileSync(join(root, 'assets/images/Old.png'));
  const newOriginal = readFileSync(join(root, 'assets/images/New.png'));
  const initial = syncFlutterAssets({projectRoot: root});
  assert.equal(initial.bundled, 1);
  assert.deepEqual(bundledPaths(readFileSync(file, 'utf8')), ['assets/images/Old.png']);
  assert.equal(syncFlutterAssets({projectRoot: root, check: true}).changed, false);

  writeFileSync(join(root, 'lib/main.dart'), "const image = 'assets/images/New.png';");
  const beforeCheck = readFileSync(file, 'utf8');
  assert.throws(() => syncFlutterAssets({projectRoot: root, check: true}), /out of date/i);
  assert.equal(readFileSync(file, 'utf8'), beforeCheck);

  const result = syncFlutterAssets({projectRoot: root});
  assert.equal(result.changed, true);
  assert.equal(result.bundled, 1);
  assert.equal(result.excluded, 1);
  assert.deepEqual(bundledPaths(readFileSync(file, 'utf8')), ['assets/images/New.png']);
  assert.deepEqual(readdirSync(join(root, 'assets/images')).sort(), ['New.png', 'Old.png']);
  assert.deepEqual(readFileSync(join(root, 'assets/images/Old.png')), oldOriginal);
  assert.deepEqual(readFileSync(join(root, 'assets/images/New.png')), newOriginal);
});

test('sync includes image references from every Dart file under lib', t => {
  const root = project(t, "const logo = 'assets/images/logo.png';", ['logo.png', 'Extra.png']);
  mkdirSync(join(root, 'lib/screens'));
  writeFileSync(join(root, 'lib/screens/extra.dart'), "const image = 'assets/images/Extra.png';");
  const result = syncFlutterAssets({projectRoot: root});
  assert.equal(result.bundled, 2);
  assert.deepEqual(bundledPaths(readFileSync(join(root, 'pubspec.yaml'), 'utf8')), [
    'assets/images/Extra.png',
    'assets/images/logo.png',
  ]);
});

test('unsupported dynamic and parent-directory paths fail instead of silently dropping images', () => {
  assert.throws(() => requiredImageAssets("const image = 'assets/images/$name.png';"), /dynamic image paths/i);
  assert.throws(() => requiredImageAssets("const image = 'assets/images/../hidden.png';"), /invalid image path/i);
});
