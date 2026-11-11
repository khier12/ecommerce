# Unused image cleanup — 11 November 2026

Deleted **54 unused images** from `assets/images/`: the 52 retired product photos and two former splash artworks. Only the **40 selected product photos and logo** remain, both on disk and in the Flutter asset declarations. Kept photos retain their exact original optimized bytes.

| Measurement | Before | After |
| --- | ---: | ---: |
| Source image files | 95 | 41 |
| Bundled image files | 93 | 41 |
| Source image bytes | 23,566,050 | 5,914,663 |
| ARM64 release APK | 40,009,613 bytes / 38.2 MiB | 26,804,192 bytes / 25.6 MiB |

This removes **16.8 MiB of source images** and **12.6 MiB from the APK**, a further **33.0% package reduction**. The two splash artworks were already excluded from the prior APK, so their source removal does not contribute to the APK difference. APK measurements use the same ARM64 release target; they are local package sizes rather than Play Store download estimates.

## Catalog and old receipts

Removed the 52 retired records from the generated catalog block as well as their photos, leaving exactly the agreed 40 products. Category budgets, featured picks, retained product data and the six-thumbnail preload limit stay unchanged.

Saved receipts contain their own product snapshots and do not depend on retaining retired entries in the current catalog. Their original names, quantities, totals, customer details and references remain readable. `ProductImage` now resolves an active product ID to its current photo, including older receipts that contain obsolete PNG filenames. Retired or unknown IDs render the existing cafe-icon placeholder with the product's accessible label and make no missing-asset request. Receipt data is not rewritten or cleared.

The optional website importer reads `cafeMenuProductIds` before processing products. It skips unselected entries before resolving image files, so the deleted photos are not required for reimporting the selected menu. It verifies every selected ID and rejects duplicates/missing selected products before writing. To restore a retired product later, restore its image and add its ID before importing. The original website is absent in this workspace; importer behavior was verified with a fixture that runs the actual tool.

## Verification

- **146 Flutter tests passed**, including all real image decodes, exact source/bundle file sets, current category counts, filters/swipes, cart, checkout, payment and order history.
- Three image compatibility tests verify an accessible placeholder without requesting a deleted file, current photo lookup for obsolete filenames, and readable historical receipt details after its photo is removed. The saved-receipt test also preserves the old product snapshot and sequential reference numbering.
- **21 Node tests passed**, including selected-menu import with a missing retired image and rejection of a missing selected product without changing the working catalog.
- Static analysis reports no issues; asset synchronization reports 41 bundled images and zero excluded files left in the source directory.
- Android ARM64 release and release web builds succeeded. Both outputs contain exactly 41 images. Every packaged image and every retained source file matches its pre-cleanup SHA-256 hash; all 54 removed source files are absent.
- A 390 × 844 browser check opened the menu, verified all category counts and opened Matcha Affogato details after scrolling. No JavaScript page errors or asset HTTP failures were recorded.

No physical-device RAM, frame rate, battery or cold-start measurement was made in this cleanup. No runtime dependency was added.

[Exact file inventory, hashes and byte counts](../artifacts/menu-image-cleanup-2026-11-11.json). Updated release APK: `build/app/outputs/flutter-apk/app-release.apk`.
