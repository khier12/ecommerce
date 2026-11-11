# Curated menu — 11 November 2026

The customer menu now contains **40 products**, reduced from 92. The selection preserves the six featured picks and offers distinct drink flavors and food types. Product names, IDs, prices, descriptions and photos are unchanged.

| Category | Before | Now |
| --- | ---: | ---: |
| Coffee | 13 | 8 |
| Non-Coffee | 6 | 6 |
| Food | 34 | 8 |
| Pastries | 21 | 6 |
| Ice Blended | 8 | 6 |
| More Drinks | 10 | 6 |
| **Total** | **92** | **40** |

## Selected products

- **Coffee:** Tiramisu Latte, Spanish Latte, Americano, Latte, French Vanilla Latte, Mocha Latte, Caramel Macchiato, Dirty Matcha Latte.
- **Non-Coffee:** Strawberry Matcha, Chocolate, Strawberry Latte, Matcha Latte, Ube Latte, Ube Matcha.
- **Food:** Classic Burger, Classic Chicken, Cheese Quesadilla, BBQ Fries, Sisig, Chicken Teriyaki, Carbonara, Beef Nachos. The eight choices cover burgers, sandwiches, quesadillas, fries, rice bowls, pasta and nachos.
- **Pastries:** Chocolate Bliss, Basque Cheesecake, Biscoff Blondies, OG Cookies, Hershey's Crinkles, Choco Chip Muffin. These cover brownies, cookies, muffins and cakes.
- **Ice Blended:** Mocha, Caramel Macchiato, Choco Hazelnut, Strawberry, Matcha, Ube.
- **More Drinks:** Chocolate Lava, Strawberry Lava, Bottled Water, Calamansi Juice, Affogato, Matcha Affogato.

This is a selection for variety and a shorter browse flow, rather than a sales-based ranking. No sales figures were supplied.

## Implementation and compatibility

`cafeMenuProductIds` in `lib/main.dart` defines the selection outside the generated catalog block. `MenuRepository` caches one immutable projection in the original catalog order, so featured ordering stays familiar. All production menu, search, sorting, category pages, carousel and Discover counts use the repository. The existing six-thumbnail preload limit remains in effect.

Following the requested unused-image cleanup, the catalog now contains only these 40 records. Saved receipts retain their own original product snapshots, quantities and totals, and reference numbering continues. Product images resolve active IDs to the current filename, while retired IDs use a cafe icon without requesting deleted assets. No customer data is cleared and no payment, delivery or storage logic changes.

The subsequent cleanup deleted 52 retired product photos and two former splash artworks. Source and bundle now contain exactly 40 product photos plus the logo. The website importer replaces only the original catalog block, preserving the menu selection; it skips retired products before image resolution and refuses missing selected IDs before writing. See [the image cleanup results](menu-image-cleanup-2026-11-11.md).

## Validation

- **143 Flutter tests passed**, covering the exact category budgets, unique selected IDs, retained featured picks, food variety, search exclusion, sorting, category swipes, Discover counts, bag, checkout, payment and order history.
- An added compatibility test saves a Double Classic Burger receipt, restores it after menu selection, verifies its unchanged product snapshot, two-item quantity and ₱360 total, then places a selected product under the next reference.
- Bundle tests now decode all 40 selected product photos and the logo, and assert that unused images are physically removed. Image-declaration synchronization passes with exactly 41 bundled images.
- Static analysis reports no issues.
- Android ARM64 release and release web builds succeeded for the initial selection. The follow-up cleanup and its package measurements are recorded separately in the linked cleanup report.
- A 390 × 844 browser check selected All and every category and verified the visible counts: 40, 8, 6, 8, 6, 6 and 6 respectively. No JavaScript errors or asset HTTP failures were recorded.

All application Dart remains in the existing `lib/main.dart` layout.
