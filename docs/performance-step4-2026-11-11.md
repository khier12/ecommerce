# Performance step 4: reduce 3D scene allocations

The 3D starting scene now reuses working vectors, logo geometry, index storage and draw paints. **44 before/after raster comparisons were byte-identical**, with zero changed color channels across 30,377,600 channel comparisons. The mug, latte art, logo, beans, steam, lighting, entrance, idle motion and tilt retain their existing appearance and movement in the checked poses.

## Changes

- Replaced object-producing vector operations in the 2,092-vertex mesh projection and lighting loop with two retained scratch vectors. Screen coordinates are written directly into the existing position buffer. The scalar calculations preserve the original operation order.
- Packed calculated color channels directly into the existing integer color buffer, replacing per-vertex `Color` construction and its captured channel-calculation closure.
- Cached the logo's 95 curved surface samples and 72-quad topology. Normals and local coordinates are calculated once rather than rebuilt each frame. Texture coordinates update only when the logo texture dimensions change.
- Replaced the logo's growable index list, per-quad temporary lists and `Uint16List.fromList` with a retained 432-index buffer and 73 bounded prefix views. Dynamic face visibility still selects the appropriate triangles in the original order.
- Reused the foreground flags, depth comparator and mesh/logo `Paint` objects. Depth sorting, face culling, shading, perspective and mesh resolution remain unchanged.
- Preserved immutable native `Vertices` creation/disposal at draw time, shader/image lifecycle, animation controllers, gesture springs, pause/resume and reduced-motion handling. This is a reduction in temporary work, not an allocation-free rendering claim.

All application changes are confined to the renderer in `lib/main.dart`. The viewport and lifecycle code, static studio mesh, catalog, images, menu, checkout, payment and saved-order storage are unchanged. No runtime dependency or bundled asset was added. Reusable scratch state belongs to each scene instance; shared logo geometry is read-only.

## Validation

- **147 Flutter tests passed**; static analysis reported no issues.
- Before editing, the original renderer was captured locally. Both versions rendered the same 11 poses at 320 × 360 and 500 × 460, with real textures and with the untextured fallback: **44 scenarios**. These include entrance progress 0, .12, .5 and 1, idle quarter phases and loop endpoints, extreme tilt in both directions and reduced motion. Every RGBA byte matched.
- The new permanent `scene_buffer_reuse_test.dart` keeps one viewport alive through eight phase/size/motion changes and compares its rendered pixels against a fresh renderer at each step. It detects stale projection, color, UV or index data when buffers are reused.
- Existing tests cover hover/drag recovery, vertical scrolling, live reduced-motion changes, pause/resume, disposal, safe small bounds, the seamless idle loop and ORDER NOW navigation.
- Android ARM64 release and release web builds succeeded. The APK remains approximately **25.6 MiB**; asset synchronization still reports 41 images with no excluded source files left behind.
- A 1440 × 900 browser check confirmed that normal frames change, reduced-motion frames remain identical, and ORDER NOW → menu → Back works without JavaScript page errors. The rendered textured mug was also inspected visually.

The optimization removes source-level object construction from hot loops. Dart's JIT/AOT compiler may already eliminate some temporary expressions, so these changes are not presented as a measured percentage reduction in allocation rate. A local diagnostic recorded additional frames, but its timing and heap snapshots are not treated as phone FPS, garbage-collection pause or RAM benchmarks. No new physical-device, battery or thermal measurements were made.

[Exact pose definitions, source hashes and per-render hashes](../artifacts/performance-step4-2026-11-11.json). The updated APK is at `build/app/outputs/flutter-apk/app-release.apk`.
