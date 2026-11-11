// Import the supplied website's names, prices, categories, and image paths.
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { posix } from 'node:path';
import { syncFlutterAssets } from './sync_flutter_assets.mjs';
import { resolveProductImage } from './product_image_assets.mjs';
import { menuProductIds, verifySelectedProducts } from './menu_selection.mjs';

const root = new URL('../', import.meta.url);
const target = new URL('lib/main.dart', root);
const main = readFileSync(target, 'utf8');
const selectedIds = menuProductIds(main);
const imageFiles = new Set(readdirSync(new URL('assets/images/', root)));
const sourcePath = new URL('SmoochCafe/pages/products.html', root);
if (!existsSync(sourcePath)) {
  throw Error('Optional source website is missing: SmoochCafe/pages/products.html. Edit the product data in lib/main.dart directly, or restore the source website before importing. No files changed.');
}
const source = readFileSync(sourcePath, 'utf8');
const decode = (text) => text.replaceAll('&amp;', '&').replaceAll('&#39;', "'").replaceAll('&quot;', '"');
const cards = source.split(/<div class="product-card" data-name="([^"]+)" data-price="([^"]+)">/);
const food = ['Quarter Pounder', 'Sandwiches', 'Quesadilla', 'French Fries', 'Fries', 'Rice Bowls', 'Pasta', 'Nachos'];
const pastry = ['Brownies', 'Cookies', 'Muffins', 'Cakes'];
const descriptions = {
  'Tiramisu Latte': 'Espresso-based latte with tiramisu-inspired cream. A little coffee, a little dessert, and a whole lot of comfort.',
  'Classic Burger': 'A juicy quarter-pound patty with cheese and fresh veggies. Your comfort-food favorite, made to pair with a Smooch drink.',
  'Chocolate Bliss': 'A fudgy chocolate brownie with a rich, moist center. The perfect little companion to your favorite coffee.',
  'Spanish Latte': 'Espresso and milk with a sweet, creamy finish. A comforting coffee for slow afternoons.',
  'Strawberry Matcha': 'Earthy matcha meets sweet strawberry and milk for a colorful sip of happiness.',
};
const featured = ['Tiramisu Latte', 'Classic Burger', 'Chocolate Bliss', 'Spanish Latte', 'Strawberry Matcha', 'Basque Cheesecake'];
const products = [];
for (let i = 1; i < cards.length; i += 3) {
  const [name, price, body] = [decode(cards[i]), Number(cards[i + 1]), cards[i + 2]];
  const subcategory = decode(body.match(/<div class="product-tag">([^<]+)/)[1]).trim();
  const id = `${subcategory}-${name}`.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  // Unselected products may no longer have local photos. Skip them before
  // resolving images so reimporting cannot restore the retired assortment.
  if (!selectedIds.has(id)) continue;
  const image = resolveProductImage(posix.basename(decode(body.match(/<img src="([^"]+)"/)[1])), imageFiles);
  const category = food.includes(subcategory) ? 'Food' : pastry.includes(subcategory) ? 'Pastries' : ['Coffee', 'Non-Coffee', 'Ice Blended'].includes(subcategory) ? subcategory : 'More Drinks';
  if (!existsSync(new URL(image, root))) throw Error(`Missing image: ${image}`);
  if (!imageFiles.has(image.slice(image.lastIndexOf('/') + 1))) throw Error(`Image filename case mismatch: ${image}`);
  const description = descriptions[name] ?? {
    Food: `A comforting pick from our ${subcategory.toLowerCase()} menu. Pair it with your favorite handcrafted drink.`,
    Pastries: `A sweet little moment from our ${subcategory.toLowerCase()} selection. Enjoy it with a hot or iced coffee.`,
    Coffee: 'Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.',
    'Non-Coffee': 'Skip the espresso and find a little happiness in our non-coffee drink selection.',
    'Ice Blended': 'A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.',
    'More Drinks': `A refreshing little break from our ${subcategory.toLowerCase()} selection. A delicious way to complete your order.`,
  }[category];
  products.push({ id, name, price, category, subcategory, description, image, featured: featured.includes(name) });
}
verifySelectedProducts(products, selectedIds);
products.sort((a, b) => (a.featured ? featured.indexOf(a.name) : 100) - (b.featured ? featured.indexOf(b.name) : 100));
const dart = (value) => typeof value === 'string' ? JSON.stringify(value).replaceAll('$', '\\$') : String(value);
const output = ['// BEGIN CAFE CATALOG', '// Generated from SmoochCafe/pages/products.html by tools/import_menu.mjs.', 'const cafeProducts = <Product>[',
  ...products.map((product) => `  Product(\n${Object.entries(product).map(([key, value]) => `    ${key}: ${dart(value)},`).join('\n')}\n  ),`), '];', '// END CAFE CATALOG'].join('\n');
const startMarker = '// BEGIN CAFE CATALOG';
const endMarker = '// END CAFE CATALOG';
const start = main.indexOf(startMarker);
const end = main.indexOf(endMarker);
if (start < 0 || end < start || main.indexOf(startMarker, start + 1) !== -1 || main.indexOf(endMarker, end + 1) !== -1) {
  throw Error('Expected one matching pair of cafe catalog markers in lib/main.dart. No files changed.');
}
writeFileSync(target, main.slice(0, start) + output + main.slice(end + endMarker.length));
syncFlutterAssets();
console.log(`Imported ${products.length} products; all image paths verified.`);
console.log('Categories:', [...new Set(products.map((p) => p.category))].join(', '));
console.log('Catalog section:', fileURLToPath(target));
