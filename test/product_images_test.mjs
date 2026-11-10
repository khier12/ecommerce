import test from 'node:test';
import assert from 'node:assert/strict';
import {resolveProductImage} from '../tools/product_image_assets.mjs';

test('website PNG references resolve to the optimized image after source replacement', () => {
  assert.equal(resolveProductImage('Tiramisu Latte 5.png', new Set(['Tiramisu Latte 5.webp'])), 'assets/images/Tiramisu Latte 5.webp');
});

test('already compressed originals remain usable when there is no WebP alternative', () => {
  assert.equal(resolveProductImage('Chocolate Bliss 2.png', new Set(['Chocolate Bliss 2.png'])), 'assets/images/Chocolate Bliss 2.png');
});

test('an optimized variant takes precedence when an export also includes the original', () => {
  assert.equal(resolveProductImage('BBQ Fries.png', new Set(['BBQ Fries.png', 'BBQ Fries.webp'])), 'assets/images/BBQ Fries.webp');
});

test('imported optimized paths remain stable', () => {
  assert.equal(resolveProductImage('../images/Classic Burger.webp', new Set(['Classic Burger.webp'])), 'assets/images/Classic Burger.webp');
});

test('punctuation and spaces survive optimized website path resolution', () => {
  const names = ["Hershey's Crinkles 1", 'Grilled Ham & Cheese Sandwich', 'Burger Steak Rice Bowl '];
  for (const name of names) {
    assert.equal(resolveProductImage(`../images/${name}.png`, new Set([`${name}.webp`])), `assets/images/${name}.webp`);
  }
});

test('missing and case-mismatched images fail rather than creating a broken catalog path', () => {
  assert.throws(() => resolveProductImage('Missing.png', new Set()), /Missing product image/);
  assert.throws(() => resolveProductImage('Latte.webp', new Set(['latte.webp'])), /case mismatch/);
});
