# App weight and performance audit

The current app is unnecessarily large to download and install for its 92-product catalog. Images are the dominant cause. Normal shopping is usable on the connected phone, with occasional frame-budget overruns. The 3D start screen has the highest continuous Dart/UI workload of the sampled screens; it stops when the menu opens. The new route highlight is inexpensive on the UI thread.

Follow-up: [step 1 excluded 47 unused image assets](performance-step1-2026-11-10.md), reducing the ARM64 release APK to **115.9 MiB**. Measurements below remain the original pre-optimization baseline.

[Step 2 image optimization](performance-step2-2026-11-10.md) subsequently reduced the ARM64 release APK to **42.4 MiB**. Original phone profiling below has not been rerun after these asset optimizations.

This audit measures the existing application. Application source and product assets were not optimized or removed. The authorized phone test updated the installed app using `adb install -r`; it did not clear data or submit orders. Existing receipts remained available. The phone was returned to the menu, and the audit's ADB forwarding rule was removed.

## Package and asset measurements

Sizes below use MiB: 1 MiB = 1,048,576 bytes. These are local APK/archive measurements, not Play Store download sizes or Android installed-storage estimates.

| Item | Measured size | Meaning |
| --- | ---: | --- |
| Existing universal debug APK | 295.8 MiB | Development artifact; unsuitable as the performance/size baseline |
| New ARM64 release APK | **171.6 MiB** | Optimized, device-specific build measured with `--analyze-size` |
| Images inside release APK | **151.7 MiB, 88.4%** | 142 bundled image-directory files |
| Other compressed Flutter assets | 0.64 MiB | Fonts, manifests and related assets |
| Native libraries in release APK | 18.3 MiB | Engine, compiled Dart and plugin libraries |
| Images with no application image-path reference | **47 files, 55.8 MiB** | Candidates for exclusion from the Flutter bundle |
| Catalog's 92 product images on disk | 91.5 MiB | Used images still need format/size optimization |

`pubspec.yaml` bundles the complete `assets/images/` directory. An audit of literal paths across all application Dart and the catalog found 47 unreferenced files, including old product alternatives and landing artwork. Keep originals outside the bundled directory or use an explicit asset list after verification. This alone identifies approximately 55.8 MiB of avoidable image data; it is not a measured post-optimization APK reduction.

The duplicate `1.png` and `landing2.png` contain identical bytes (2.36 MiB each). Both are already included in the unreferenced total: do not add duplicate savings again. File extensions are misleading: 58 files named `.png` actually contain JPEG data. Counting by real format gives 81 PNGs (145.4 MiB), 60 JPEGs (6.31 MiB), and one small icon. Convert or resize based on actual content and alpha requirements, preserving the product cutouts.

The whole web output directory is about 193.4 MiB, including renderer variants and bundled assets. That is not its first-page network transfer. However, the current eager product preload can eventually request the entire catalog's image files rather than only visible products.

The size analysis attributed about 306 KiB of decompressed AOT symbols to the application's `main.dart`. Procedural 3D code and a long source file do not explain the 151.7 MiB image bundle. Removing major UI features or rewriting the architecture would miss the largest size problem. Measurement follows [Flutter's app-size guidance](https://docs.flutter.dev/perf/app-size).

## Physical-phone measurements

Device: vivo V2417, Android 16, ARM64, 1080 × 2400 display. The active display mode was 60 Hz. Tests used a profile build, native `Flutter.Frame` events through the VM Service, and Android `dumpsys meminfo`. UI and raster durations are evaluated separately against the 16.67 ms frame budget. This follows [Flutter's profiling guidance](https://docs.flutter.dev/tools/devtools/performance); debug timing is not representative.

| Scenario | Window / frames | UI p95 | Raster p95 | UI or raster >16.67 ms |
| --- | ---: | ---: | ---: | ---: |
| Steady 3D start | 20 s / 1,182 | 11.14 ms | 14.32 ms | 17 / 1,182 — **1.44%** |
| Menu category changes and scrolling | 20 s / 630 | 8.11 ms | 14.07 ms | 12 / 630 — **1.90%** |
| Animated route, map visible | 20 s / 1,195 | 1.72 ms | 12.50 ms | 1 / 1,195 — **0.08%** |
| Idle menu | 10 s / 0 new frames | — | — | No unnecessary redraw observed |

The menu scenario automatically performed 13 category taps, horizontal swipes, vertical scrolls and carousel interactions within the capture window. Its frames occur primarily during the first 11.75 seconds; the remaining static time is expected. Dividing those frames by the entire window would give a misleading FPS number. Likewise, zero newly scheduled idle frames is desirable and does not mean zero display FPS.

There were occasional spikes: worst UI/raster durations were 19.22/31.91 ms for the 3D scene, 38.76/24.61 ms for menu interactions, and 2.44/17.50 ms for the route sample. These short samples establish neither universal 60 FPS nor failure on weaker phones. UI and raster durations must not be added together to calculate the over-budget percentages. Battery drain, sustained thermals, 120 Hz behavior, and low-end devices were not benchmarked.

Whole-process PSS snapshots were approximately **121 MiB** on the start screen, **191 MiB** after menu browsing, and **163 MiB** on the receipt/map. These are individual snapshots with image/engine caches, not leak measurements. Dart heap statistics exclude native/GPU resources; values reported for related isolates must not be summed.

The first browsing attempt is excluded because most gestures happened after its capture window. The initial Android launch wait is also excluded because the phone was locked; this audit does not claim a reliable cold-start time. The 3D sample produced numerous GC notifications, predominantly idle collections; these are not evidence of GC stalls.

## Flutter Widget Performance Audit

### Performance Score

**7 / 10 — qualitative source-audit rating, not a benchmark result.**

### Performance Maturity Level

Level 3 — mostly optimized browsing, with targeted image-loading and animation work remaining.

### Key Performance Strengths

- Product grids, bag items and order history use lazy builders ([main.dart:4114](../lib/main.dart#L4114), [main.dart:5199](../lib/main.dart#L5199), [main.dart:5480](../lib/main.dart#L5480)).
- Shared product images request 640-pixel browsing decodes and 1024-pixel detail decodes. Discover uses the same image widget ([main.dart:2539](../lib/main.dart#L2539)).
- Route motion repaints an isolated custom painter instead of rebuilding the map on each tick. It honors pause, reduced motion, lifecycle and ticker state ([main.dart:6091](../lib/main.dart#L6091), [main.dart:6373](../lib/main.dart#L6373)).
- The 3D loop stops when the menu opens; retained scene buffers are bounded and disposed. The idle-menu sample confirms no continuous redraw from the covered scene.

### Critical Performance Issues

**Startup image warming — MEDIUM.** StartScreen precaches the entire catalog plus a landing image that is not displayed ([main.dart:2965](../lib/main.dart#L2965)). Warming continues after navigating into the menu because the screen remains mounted. It has no foreground/route visibility guard. All 640-pixel catalog decodes would total approximately 157.4 MiB of RGBA pixels if retained together; this is a theoretical sum, not observed simultaneous RAM. Warming everything risks decode work and cache churn. Precache only initial/adjacent visible products and suspend background warming when leaving the start page.

**Continuous 3D allocations/work — MEDIUM.** Projection, shading and face sorting happen each idle frame, and the logo recreates index lists and typed arrays ([main.dart:9500](../lib/main.dart#L9500), [main.dart:9679](../lib/main.dart#L9679)). Its measured mean UI work was 6.92 ms per scheduled frame. Reuse logo topology and numeric buffers, reduce temporary vectors, and remeasure while preserving the continuous animation.

**Broad cart notification rebuilds — LOW to MEDIUM.** MenuScreen rebuilds its scaffold and recalculates category projections on shop notifications, including cart-only changes ([main.dart:3577](../lib/main.dart#L3577), [main.dart:3730](../lib/main.dart#L3730)). With 92 products the filtering itself is small. Narrow cart listeners and cache category results before undertaking larger state-management changes.

**Animation outside the visible viewport — LOW to MEDIUM.** Route flow keeps ticking when scrolled out of view in the receipt. The start scene similarly lacks viewport visibility gating. Add visibility-based suspension in addition to the existing lifecycle/navigation controls.

### Technical Debt Indicators

- Large screen build methods increase rebuild scope, but keeping code in one `main.dart` is the user's chosen layout and is not itself a runtime defect.
- A paused start route intentionally retains textures/buffers for Back navigation; this is not a demonstrated memory leak.
- No full-resolution Discover image bypass, eager product grid, or per-frame map network request was found.

### Strategic Performance Recommendations

1. Exclude verified unused images from the bundle while preserving the originals.
2. Optimize used image formats/resolutions and limit startup preloading.
3. Reuse 3D per-frame data and pause decorative motion only when not visible.
4. Narrow cart rebuilds after the larger image costs are addressed.

## Flutter Runtime Performance Audit

### Runtime Performance Score

**7 / 10 — qualitative source-audit rating for the current bounded catalog.**

### Runtime Performance Maturity Level

Level 3 — bounded catalog work, asynchronous I/O, and routing caches; history needs a growth strategy.

### Key Runtime Strengths

- Search/sort operates over 92 local products; no evidence warrants treating it as a heavy CPU task.
- Routing has a 24-entry ten-minute cache, in-flight deduplication and explicit retries. Requests occur on load/input changes rather than animation ticks.
- GPS is on demand; no continuous location stream or high-frequency network polling was found.
- Tracking transitions run every ten seconds and stop at completion.

### Detected CPU Bottlenecks

**Unbounded history persistence — MEDIUM as history grows.** Restoring orders decodes/sorts all stored receipts, and each new order serializes the full history, including product metadata ([main.dart:1747](../lib/main.dart#L1747), [main.dart:1792](../lib/main.dart#L1792)). The `orders` getter also copies the list on each access, including visible rows ([main.dart:1629](../lib/main.dart#L1629), [main.dart:5486](../lib/main.dart#L5486)). Use one immutable view per build and incremental or paginated storage when history grows. Do not discard existing orders as a performance fix. Current samples do not establish a history stall.

**Bounded route parsing — LOW to MEDIUM potential.** JSON decoding and construction of up to 10,000 route points run on the main isolate. The 512 KiB check happens after HTTP has buffered the body; it is a parsing acceptance limit rather than a transport memory limit. Profile worst-case payloads before adding isolate complexity.

### Async Workflow Issues

- Full-catalog startup warming continues across navigation and should be scoped to current demand.
- Reverse-geocoding responses have no size guard/result cache; this is a lower-priority bounded-interaction concern, not measured normal-use overhead.

### Memoization Opportunities

- Stable order-history views and cached category projections avoid unrelated repeated copies/computation.
- Existing bounded routing cache is appropriate and should remain.

### Event Loop Risks

No recursive microtask loop, enormous async fan-out or rapid polling was found. Heavy history growth is the main future synchronous-work concern.

### Strategic Runtime Recommendations

Address the image bundle and startup warming first, then history growth. Introduce background parsing only for demonstrated large-payload stalls. No full application rewrite or removal of shopping/map functionality is justified by this audit.

## Evidence

[Machine-readable measurements and asset candidates](../artifacts/performance-audit-2026-11-10.json) contain exact byte counts, sample summaries, gesture timestamps, and measurement limitations. Raw frame captures remain in `.dart_tool/profile-*.json` in this workspace. The release-size analysis was generated with `flutter build apk --release --target-platform android-arm64 --analyze-size`; the phone ran a separately built profile APK.
