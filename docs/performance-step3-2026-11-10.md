# Performance step 3: preload the initial menu only

Startup now schedules **at most six unique product thumbnails**, instead of all 92 product photos. The remaining photos load through the existing lazy product grid and category/carousel pages as customers browse, including Flutter's normal viewport cache buffer.

## Behavior

- The small preview follows the selected category, search and sort. For All without a search, the first two featured carousel images take priority within the same six-image budget. Fewer matches mean fewer preloads; an empty result means none.
- Decodes run sequentially with a short scheduling gap and the same 640-pixel thumbnail cache key as `ProductImage`. Menu cards reuse warmed images; details retain their existing 1024-pixel decode request.
- Pending work stops when ORDER NOW opens the menu, the app backgrounds, or the start screen is disposed. An already-started decode may finish, but cannot start another while the screen is covered or the app is inactive.
- Returning to the start screen prepares a new bounded preview for the current filters. Resuming the app continues an interrupted preview. The release-notes dialog also prevents warming while it covers the start screen and resumes scheduling when dismissed.
- Logo rendering, the 3D scene, menu transitions, product data, shopping, payment and saved orders retain their existing behavior. All application Dart remains in `lib/main.dart`. No runtime dependency was added.

The previous preload queue was also the only application reference to `landing1.png` and `Ice Blended Choco Hazelnut transparent.png`. These two undisplayed artworks are now excluded from the generated bundle declarations. Their source files remain in `assets/images/`; no source image was deleted in this step. All 92 product images and the displayed logo remain bundled.

## Results

| Measurement | Before step 3 | After step 3 |
| --- | ---: | ---: |
| Scheduled startup product preloads | 92 | At most 6 |
| Bundled image files | 95 | 93 |
| Source image files | 95 | 95 |
| ARM64 release APK | 44,467,003 bytes / 42.4 MiB | 40,009,613 bytes / 38.2 MiB |

This removes **93.5% of scheduled product preloads** and reduces the APK by **4,457,390 bytes**. The package reduction comes from excluding the two undisplayed artworks, rather than the act of delaying decodes. All existing step-2 WebP files retain their hashes and the entire catalog block is unchanged.

These are loading and package measurements. No new physical-device RAM, FPS, cold-start, battery or thermal measurements were made; a proportional reduction in RAM or startup time is not claimed.

## Validation

- **141 Flutter tests passed**, including ten new widget tests that record actual AssetImage loads through Flutter's image cache. They cover the six-image limit after waiting, filtered/sorted previews, carousel priority, empty search results, background/resume, navigation, in-flight decodes, disposal, failed images, returning with changed filters, cache reuse and loading a late product on demand.
- **17 Node tests passed**; static analysis reported no issues and image-declaration synchronization passed.
- Android ARM64 release and release web builds succeeded. Exact file sets and hashes were checked in both packaged outputs: 93 images, matching source bytes, with both former preload-only images absent.
- A 390 × 844 browser check observed only the six initial product image requests while waiting on the start screen. Opening the menu reused them. Selecting More Drinks and scrolling requested additional images on demand; the final Matcha Affogato details opened successfully. No JavaScript page errors or asset HTTP failures occurred. Reduced motion was enabled for this browser check; the existing Flutter tests also cover the animated start/menu flows.
- Source verification confirmed the catalog is unchanged and all optimized product image hashes still match the step-2 record.

[Exact verification results](../artifacts/performance-step3-2026-11-10.json). The updated APK is at `build/app/outputs/flutter-apk/app-release.apk`.
