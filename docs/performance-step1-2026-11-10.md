# Performance step 1: exclude unused image assets

Follow-up: [step 2 compressed and resized the large product images](performance-step2-2026-11-10.md), reducing the release APK further to **42.4 MiB**. The measurements in this report describe step 1.

The ARM64 release APK decreased from **171.6 MiB to 115.9 MiB**, saving **55.8 MiB (32.5%)**. The initial exclusion stage retained all 142 original files. At the user's subsequent request, the 47 verified unused originals were physically removed; the source directory now contains the 95 required images. The initial exclusion measurements below remain the baseline for this follow-up.

## Change

`pubspec.yaml` now explicitly lists the 95 image paths used by the application: all 92 catalog product photos, the Smooch logo, and the two other images referenced by the existing startup preload. The 47 verified unused files are excluded from the deployed image bundle. Product names, prices, image paths and the rest of `lib/main.dart` are unchanged.

`tools/sync_flutter_assets.mjs` generates the image declarations from Dart paths under `lib/`. It checks files and exact filename capitalization before writing, supports spaces/apostrophes/ampersands, and preserves the fonts section. `--check` reports stale declarations without writing. The catalog importer invokes the helper after regenerating product data, so future imported images enter the bundle too.

When editing products or image references manually:

```sh
node tools/sync_flutter_assets.mjs
flutter pub get
```

The original source website is optional and was absent, so a complete website import was not rerun. Isolated tool tests verify catalog changes, manifest synchronization, retained originals and validation failures.

## Size comparison

Both APKs used `flutter build apk --release --target-platform android-arm64 --analyze-size --no-pub` with the same app code and dependency versions. MiB means 1,048,576 bytes; these are local release APK sizes.

| Measurement | Before | After |
| --- | ---: | ---: |
| Release APK | 179,976,579 bytes / 171.6 MiB | 121,478,522 bytes / 115.9 MiB |
| Packaged image files | 142 | 95 |
| Excluded original files | 0 | 47 |
| Original image files on disk | 142 | 142 |

The APK is **58,498,057 bytes smaller**. The excluded source images total 58,490,667 bytes; manifest/archive overhead accounts for the small difference.

## Validation

- **130 Flutter tests passed**, including three new real-bundle tests. Every required image is present in `AssetManifest`, loads from `rootBundle`, and decodes successfully. This includes `Hershey's Crinkles 1.png` and the startup/logo images.
- **11 Node tests passed**, including nine asset-tool tests for quoting, exact filename case, retained startup references, catalog synchronization, stale check mode, recursive Dart scanning, unchanged originals, fonts, and CRLF handling.
- Static analysis and `git diff --check` passed.
- APK ZIP inspection found exactly 95 images after decoding Flutter's URI-encoded archive keys. All 47 excluded images are absent. Each retained image and both bundled fonts match the original source bytes.
- All 142 original image hashes still match the pre-change inventory.
- Release web build succeeded. Its deployed image directory also contains exactly the required 95 files; each matches its original bytes.
- Browser checks exercised the start page, menu, Coffee filtering, searching/opening Hershey's Crinkles, and Discover. No missing-asset responses or JavaScript page errors were captured.
- No Android phone was connected during this step's final smoke check, so the new APK was built and inspected rather than installed on hardware. The earlier audit's phone timings describe the pre-exclusion build.

[Exact package verification](../artifacts/performance-step1-2026-11-10.json) records the byte counts and integrity checks. [Original audit](performance-audit-2026-11-10.md) preserves the baseline measurements and remaining priorities.

## Follow-up: remove unused originals

The 47 unused files were removed from `assets/images/`, freeing **58,490,667 bytes (55.8 MiB)** in the source folder. Before deletion, their paths and SHA-256 hashes were checked against the original audit and against current Dart/pubspec references. Every deletion target resolved to a file directly inside this project's image directory. No directories were deleted.

The remaining 95 image hashes match the pre-cleanup inventory. The required bundle paths are unchanged, so the previously measured **115.9 MiB** release APK gets no further size reduction from source cleanup alone. The synchronization helper still does not automatically delete files during future catalog imports.

The bundle regression now verifies that the source directory contains exactly the required images, and still loads/decodes every catalog and startup image. [Cleanup record](../artifacts/unused-image-cleanup-2026-11-10.json) lists the removed files and integrity results.

After physical removal, all **130 Flutter tests** and **11 Node tests** passed again; static analysis and whitespace checks were clean.
