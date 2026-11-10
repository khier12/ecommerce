# Performance step 2: compress and resize product images

The ARM64 release APK decreased from **115.9 MiB to 42.4 MiB**, a further **63.4% reduction**. The 92 catalog product-image files decreased from **91.5 MiB to 18.1 MiB** (80.2%). All 92 products retain their original names, prices, categories, descriptions, IDs and photo compositions.

## Image treatment

- Replaced 49 large actual PNG files with `.webp` images using the official libwebp 1.6.0 encoder, photo preset, quality 94, method 6, sharper RGB-to-YUV conversion, and lossless alpha settings. Color profiles are copied when present.
- Resized 12 portraits proportionally to a maximum 1024-pixel edge. The other 37 optimized square images retain 1024 × 1024 resolution. Images are neither cropped nor upscaled.
- Kept the other 43 already compressed product images byte-for-byte. Some retain `.png` filenames despite containing JPEG data; Flutter decoding is verified against their actual contents.
- Kept all three nonproduct startup/logo files byte-for-byte, including the transparent image and logo. The 49 optimized source PNGs were opaque RGB images.
- Updated only the 49 catalog image paths in application Dart, then synchronized the explicit asset declarations. The image directory and bundle each contain exactly 95 required images, with no duplicate original PNGs.

The compression is lossy. Pilot comparisons covered grainy food posters, cup logos and smooth drink photography before choosing quality 94. All 49 outputs were also compared with lossless same-size reference pixels: minimum luminance SSIM 0.985813, minimum RGB SSIM 0.895591, mean RGB SSIM 0.960063. These metrics are supplementary evidence rather than a claim of pixel-identical images; fine colored grain contributes to the lower RGB scores. Product text and composition were reviewed visually at image and application size.

The encoding settings follow the [official cwebp reference](https://developers.google.com/speed/webp/docs/cwebp). The encoder was a temporary build-time utility, adding no Flutter runtime dependency.

## Size comparison

Both APK measurements used the same ARM64 release analysis command as step 1. MiB means 1,048,576 bytes; these are local APK sizes, not Play Store download estimates.

| Measurement | Before step 2 | After step 2 |
| --- | ---: | ---: |
| Release APK | 121,478,522 bytes / 115.9 MiB | 44,467,003 bytes / 42.4 MiB |
| All 92 product-image files | 95,995,552 bytes / 91.5 MiB | 18,983,941 bytes / 18.1 MiB |
| Required image files | 95 | 95 |
| Product entries | 92 | 92 |

The APK is **77,011,519 bytes smaller** than the step 1 APK. This stage changes asset files and their catalog paths; startup preload behavior and animation logic remain as measured in the original audit. No new frame-rate, battery or cold-start measurements were made for this stage.

## Importing and maintenance

`tools/product_image_assets.mjs` resolves a website's original PNG filename to an existing WebP variant with the same exact filename stem. If no optimized variant exists, it retains the original file. Missing or case-mismatched files still fail validation. The original source website is absent, so its complete import was not rerun; fixture tests cover the PNG-to-WebP resolution behavior.

`tools/optimize_product_images.mjs` stages large PNG catalog images for review using `cwebp`. It skips small files, JPEG content and already optimized WebP files. Supplying `--apply` replaces the staged catalog paths, synchronizes `pubspec.yaml`, and removes the superseded PNGs after validating source hashes and target paths. Stage first when optimizing new photos:

```sh
node tools/optimize_product_images.mjs --encoder /path/to/cwebp
# Review the staged images and plan before applying.
node tools/optimize_product_images.mjs --encoder /path/to/cwebp --apply
flutter pub get
```

The default staging/report files are under `.dart_tool/product-image-optimization/`. Original versions of the replaced tracked PNGs remain recoverable through version control.

## Validation

- **131 Flutter tests passed**, including loading/decoding every required image and checking the native metadata resolution of the optimized WebP images.
- **17 Node tests passed**. Six additional importer-image tests cover optimized alternatives, original fallback, filename case, spaces, apostrophes, ampersands and already optimized paths.
- Static analysis and JavaScript syntax checks passed.
- An application-source comparison confirmed that only product image-path literals changed in `lib/main.dart`.
- Hash verification confirmed all 43 unchanged product images and all three nonproduct files retain their pre-step-2 bytes.
- ARM64 release and release web builds succeeded. Both deployed bundles contain exactly 95 images, including 49 WebP files, with each packaged image matching its source hash. Old product PNGs are absent from the APK.
- The updated release APK installed successfully on the connected Android phone with `adb install -r`; the optimized Tiramisu photo was observed in the native menu/detail flow. No order was submitted or device data cleared.
- Browser checks opened the optimized Tiramisu Latte and BBQ Fries detail pages with no asset-load failures or JavaScript page errors. These checks verify portrait/logo and textured poster rendering at app size.

Previews: [Tiramisu detail](../artifacts/step2-tiramisu-detail-phone.png), [BBQ Fries detail](../artifacts/step2-bbq-detail-phone.png). [Exact measurements and per-image records](../artifacts/performance-step2-2026-11-10.json) include dimensions, byte counts, hashes and comparison metrics.
