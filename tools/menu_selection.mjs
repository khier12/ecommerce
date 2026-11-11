// Keep build-time imports aligned with the menu selection in main.dart.
export function menuProductIds(source) {
  const matches = [...source.matchAll(/const cafeMenuProductIds = <String>\{([\s\S]*?)\n\};/g)];
  if (matches.length !== 1) throw Error('Expected one cafeMenuProductIds selection; no files changed.');
  const entries = [...matches[0][1].matchAll(/^\s*'([a-z0-9]+(?:-[a-z0-9]+)*)',\s*$/gm)].map(match => match[1]);
  const ids = new Set(entries);
  if (!ids.size || ids.size !== entries.length) throw Error('Menu selection is empty or contains duplicate IDs; no files changed.');
  return ids;
}

export function verifySelectedProducts(products, selectedIds) {
  const seen = new Set();
  for (const product of products) {
    if (!selectedIds.has(product.id) || seen.has(product.id)) throw Error(`Unexpected or duplicate imported product: ${product.id}`);
    seen.add(product.id);
  }
  const missing = [...selectedIds].filter(id => !seen.has(id));
  if (missing.length) throw Error(`Selected products missing from source: ${missing.join(', ')}. No files changed.`);
}
