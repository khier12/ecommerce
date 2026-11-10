// Deterministic build-time optimization; no runtime dependency is added.
import fs from 'node:fs';
import {dirname, join, resolve, basename} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {requiredImageAssets, syncFlutterAssets} from './sync_flutter_assets.mjs';
import {imageDimensions} from './product_image_assets.mjs';

const defaultRoot = fileURLToPath(new URL('../', import.meta.url));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const settings = {quality: 94, maxEdge: 1024, minimumSourceBytes: 256 * 1024, alphaQuality: 100};

export function stageProductImages({projectRoot = defaultRoot, encoder = 'cwebp'} = {}) {
  const mainPath = join(projectRoot, 'lib/main.dart');
  const main = fs.readFileSync(mainPath, 'utf8');
  const catalog = main.split('// BEGIN CAFE CATALOG')[1]?.split('// END CAFE CATALOG')[0];
  if (!catalog) throw Error('Catalog markers are missing.');
  const productPaths = requiredImageAssets(catalog);
  const staging = join(projectRoot, '.dart_tool/product-image-optimization');
  fs.mkdirSync(join(staging, 'originals'), {recursive: true});
  fs.mkdirSync(join(staging, 'optimized'), {recursive: true});
  const beforeMain = join(staging, 'main.before.dart');
  const beforePubspec = join(staging, 'pubspec.before.yaml');
  fs.writeFileSync(beforeMain, main);
  const pubspec = fs.readFileSync(join(projectRoot, 'pubspec.yaml'), 'utf8');
  fs.writeFileSync(beforePubspec, pubspec);
  const version = spawnSync(encoder, ['-version'], {encoding: 'utf8', windowsHide: true});
  if (version.status !== 0) throw Error('Provide a working cwebp binary with --encoder.');
  const plan = {projectRoot, settings, encoderVersion: version.stdout.trim(), beforeMain, beforePubspec,
    mainHash: hash(Buffer.from(main)), pubspecHash: hash(Buffer.from(pubspec)), productCount: productPaths.length,
    beforeProductBytes: 0, afterProductBytes: 0, images: [], unchanged: [], applied: false};
  for (const source of productPaths) {
    const input = fs.readFileSync(join(projectRoot, source));
    plan.beforeProductBytes += input.length;
    const info = imageDimensions(input);
    if (info?.format !== 'png' || input.length < settings.minimumSourceBytes) {
      plan.afterProductBytes += input.length;
      plan.unchanged.push({source, bytes: input.length, sha256: hash(input)});
      continue;
    }
    const target = source.replace(/\.png$/i, '.webp');
    if (target === source || fs.existsSync(join(projectRoot, target))) throw Error(`Refusing to overwrite image: ${target}`);
    const original = join(staging, 'originals', basename(source));
    const output = join(staging, 'optimized', basename(target));
    fs.writeFileSync(original, input);
    const resize = Math.max(info.width, info.height) > settings.maxEdge
      ? ['-resize', ...(info.width >= info.height ? [String(settings.maxEdge), '0'] : ['0', String(settings.maxEdge)])] : [];
    const args = ['-quiet', '-preset', 'photo', '-q', String(settings.quality), '-m', '6', '-sharp_yuv',
      '-alpha_q', String(settings.alphaQuality), '-metadata', 'icc', '-exact', '-mt', ...resize, original, '-o', output];
    const encoded = spawnSync(encoder, args, {encoding: 'utf8', windowsHide: true});
    if (encoded.status !== 0) throw Error(encoded.stderr || `Encoding failed: ${source}`);
    const result = fs.readFileSync(output), dimensions = imageDimensions(result);
    const scale = Math.min(1, settings.maxEdge / Math.max(info.width, info.height));
    if (!dimensions || dimensions.format !== 'webp' || Math.max(dimensions.width, dimensions.height) > settings.maxEdge ||
        Math.abs(dimensions.width - Math.round(info.width * scale)) > 1 ||
        Math.abs(dimensions.height - Math.round(info.height * scale)) > 1 || (info.alpha && !dimensions.alpha)) {
      throw Error(`Dimensions or transparency changed unexpectedly: ${source}`);
    }
    if (result.length >= input.length * .9) throw Error(`Insufficient size reduction; review rather than replacing: ${source}`);
    plan.images.push({source, target, original, output, sourceBytes: input.length, bytes: result.length,
      before: info, after: dimensions, sourceSha256: hash(input), sha256: hash(result), resized: scale < 1});
    plan.afterProductBytes += result.length;
    if (plan.images.length % 10 === 0) console.log(`Staged ${plan.images.length} product images.`);
  }
  return plan;
}

export function applyProductImages(plan) {
  if (plan.applied) throw Error('This optimization plan has already been applied.');
  const root = resolve(plan.projectRoot), imageRoot = join(root, 'assets/images');
  const mainPath = join(root, 'lib/main.dart'), pubspecPath = join(root, 'pubspec.yaml');
  const main = fs.readFileSync(mainPath, 'utf8');
  if (hash(Buffer.from(main)) !== plan.mainHash || hash(fs.readFileSync(pubspecPath)) !== plan.pubspecHash) throw Error('Project changed after staging; review before applying.');
  const replacement = new Map();
  for (const image of plan.images) {
    const source = resolve(root, image.source), target = resolve(root, image.target);
    if (dirname(source) !== imageRoot || dirname(target) !== imageRoot || !image.target.endsWith('.webp')) throw Error('Image target escaped its directory.');
    if (fs.existsSync(target) || hash(fs.readFileSync(source)) !== image.sourceSha256 || hash(fs.readFileSync(image.output)) !== image.sha256) throw Error('An image changed after staging.');
    replacement.set(image.source, image.target);
  }
  const start = main.indexOf('// BEGIN CAFE CATALOG'), finish = main.indexOf('// END CAFE CATALOG');
  const seen = new Set();
  const catalog = main.slice(start, finish).replace(/(image:\s*)(['"])(assets\/images\/.*?)\2/g, (full, prefix, _quote, source) => {
    if (!replacement.has(source)) return full;
    seen.add(source);
    return prefix + JSON.stringify(replacement.get(source));
  });
  if (seen.size !== replacement.size) throw Error('Not every optimized image matches a catalog entry.');
  const updated = main.slice(0, start) + catalog + main.slice(finish);
  const businessDataUnchanged = main.replace(/image:\s*(['"])(assets\/images\/.*?)\1/g, 'image: <asset>') === updated.replace(/image:\s*(['"])(assets\/images\/.*?)\1/g, 'image: <asset>');
  if (!businessDataUnchanged) throw Error('Unexpected non-image catalog change.');
  const required = new Set(requiredImageAssets(updated));
  if (plan.images.some(image => required.has(image.source))) throw Error('An original image is also referenced outside the catalog.');
  for (const image of plan.images) fs.copyFileSync(image.output, join(root, image.target));
  fs.writeFileSync(mainPath, updated);
  syncFlutterAssets({projectRoot: root});
  for (const image of plan.images) fs.unlinkSync(join(root, image.source));
  syncFlutterAssets({projectRoot: root, check: true});
  plan.applied = true;
  plan.catalogBusinessDataUnchanged = businessDataUnchanged;
  return plan;
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  try {
    const args = process.argv.slice(2);
    const argument = (name, fallback) => args.includes(name) ? args[args.indexOf(name) + 1] : fallback;
    const plan = stageProductImages({encoder: argument('--encoder', 'cwebp')});
    if (args.includes('--apply')) applyProductImages(plan);
    const report = argument('--report', '.dart_tool/product-image-optimization/plan.json');
    fs.writeFileSync(report, JSON.stringify(plan, null, 2) + '\n');
    console.log(JSON.stringify({staged: plan.images.length, unchanged: plan.unchanged.length, beforeBytes: plan.beforeProductBytes, afterBytes: plan.afterProductBytes, applied: plan.applied, report}));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
