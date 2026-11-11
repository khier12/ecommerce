import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {tmpdir} from 'node:os';
import {join, dirname, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {menuProductIds, verifySelectedProducts} from '../tools/menu_selection.mjs';

const selection = "const cafeMenuProductIds = <String>{\n  // Keep the coffee pick.\n  'coffee-latte',\n};";

test('menu selection parses IDs independently of the catalog and comments', () => {
  assert.deepEqual([...menuProductIds('prefix\n' + selection + '\nsuffix')], ['coffee-latte']);
  assert.deepEqual([...menuProductIds(selection.replaceAll('\n', '\r\n'))], ['coffee-latte']);
});

test('missing, empty, duplicate selections fail before importing', () => {
  assert.throws(() => menuProductIds('no selection'));
  assert.throws(() => menuProductIds('const cafeMenuProductIds = <String>{\n};'));
  assert.throws(() => menuProductIds(selection + '\n' + selection));
  assert.throws(() => menuProductIds(selection.replace("  'coffee-latte',", "  'coffee-latte',\n  'coffee-latte',")));
});

test('every selected ID must resolve exactly once', () => {
  const ids = menuProductIds(selection);
  assert.doesNotThrow(() => verifySelectedProducts([{id:'coffee-latte'}], ids));
  assert.throws(() => verifySelectedProducts([], ids), /missing/);
  assert.throws(() => verifySelectedProducts([{id:'coffee-latte'}, {id:'coffee-latte'}], ids), /duplicate/);
  assert.throws(() => verifySelectedProducts([{id:'coffee-mocha'}], ids), /Unexpected/);
});

test('import skips retired products before resolving their deleted photos', t => {
  const root = fs.mkdtempSync(join(tmpdir(), 'smooch-selected-menu-'));
  t.after(() => {
    assert.equal(dirname(resolve(root)), resolve(tmpdir()));
    assert.ok(root.includes('smooch-selected-menu-'));
    fs.rmSync(root, {recursive:true, force:true});
  });
  for (const folder of ['tools', 'lib', 'assets/images', 'SmoochCafe/pages']) fs.mkdirSync(join(root, folder), {recursive:true});
  for (const tool of ['import_menu.mjs','menu_selection.mjs','sync_flutter_assets.mjs','product_image_assets.mjs']) {
    fs.copyFileSync(new URL('../tools/' + tool, import.meta.url), join(root,'tools',tool));
  }
  const main = '// BEGIN CAFE CATALOG\nold catalog\n// END CAFE CATALOG\n' + selection;
  fs.writeFileSync(join(root,'lib/main.dart'), main);
  fs.writeFileSync(join(root,'pubspec.yaml'), 'flutter:\n  assets:\n    - assets/images/\n');
  fs.writeFileSync(join(root,'assets/images/Latte.webp'), 'fixture');
  const card = (name, image) => `<div class="product-card" data-name="${name}" data-price="70"><img src="../images/${image}"><div class="product-tag">Coffee</div></div>`;
  const source = join(root,'SmoochCafe/pages/products.html');
  fs.writeFileSync(source, card('Latte','Latte.png') + card('Retired Coffee','Deleted.png'));
  const imported = spawnSync(process.execPath, [join(root,'tools/import_menu.mjs')], {encoding:'utf8', windowsHide:true});
  assert.equal(imported.status, 0, imported.stderr);
  const updated = fs.readFileSync(join(root,'lib/main.dart'),'utf8');
  assert.ok(updated.includes('assets/images/Latte.webp'));
  assert.ok(!updated.includes('Deleted.png'));
  assert.ok(updated.endsWith(selection));
  // Missing selected products must leave the previous working catalog intact.
  fs.writeFileSync(source, card('Retired Coffee','Deleted.png'));
  const missing = spawnSync(process.execPath, [join(root,'tools/import_menu.mjs')], {encoding:'utf8', windowsHide:true});
  assert.notEqual(missing.status, 0);
  assert.equal(fs.readFileSync(join(root,'lib/main.dart'),'utf8'), updated);
});
