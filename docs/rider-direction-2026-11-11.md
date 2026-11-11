# Rider artwork, direction and alignment — 11 November 2026

The route marker now uses the exact motorcycle PNG supplied by the user. `assets/icons/delivery-motorcycle.png` is an unchanged copy of the supplied `7053332.png`: 512 × 512, transparent, 52,754 bytes. Both files have SHA-256 `42ff82532ba7b97797e3ee1e0a1d9795ddc8be727c73b19e02ee9480e6bdcf69`. It is explicitly declared in `pubspec.yaml`, separately from the 41 product/logo files in `assets/images/`. A 144-pixel decode bounds memory for the 48-logical-pixel map marker.

## Alignment correction

The previous badge's center sat 32 logical pixels above its sampled road position. That made the motorcycle appear to travel beside the route. The new marker's center sits exactly on the road position, and it is drawn above the endpoint pins so they cannot hide it.

The motorcycle now follows only the validated provider road vertices. It no longer adds straight segments between the user pins and the provider's snapped road endpoints. Polyline simplification is disabled for this route, keeping the visible road and motorcycle on identical geometry. The motorcycle reaches the road endpoint nearest the address; the customer's original address pin is retained. An unmapped driveway is not invented as a drivable route.

The existing camera projection is recalculated when the map pans, zooms or rotates. The cached path metric is sampled during animation; the map, HTTP service and receipt layout do not rebuild every frame.

## Direction and timing

The supplied side-view motorcycle faces right. Heading follows the screen direction of the route, including map rotation. Westbound motion mirrors the image and adjusts rotation so the rider remains upright. A small look-around window blends heading across corners; the motorcycle's position stays on the original polyline rather than rounding corners or cutting across them. Repeated points and zero-length paths have stable stationary poses.

The existing shared order timeline is preserved: the rider waits at the store during Rider assigned, travels for 10 seconds during On the way, then remains at the destination for one second before Delivered. Reduced motion, background/resume, disabled tickers, delayed road loading and saved-order catch-up retain their behavior. Routing restrictions, the 30 km area, persistence and payment are unchanged.

## Verification

- All **172 Flutter tests passed**, including 15 route-map/path tests. Static analysis passed.
- Added regression checks measure the rendered marker center against the middle of a known road leg after pan, zoom and 73-degree rotation, within 0.02 logical pixels. Other checks reject endpoint shortcuts, verify all four facing directions and upright westbound travel, and confirm smooth heading without rounding the route position.
- The existing exact 999 ms / 1,000 ms arrival boundary, lifecycle, reduced motion, retry and saved-order tests remain passing.
- The asset synchronizer still reports 41 required product/logo images and zero excluded originals; the motorcycle asset is separately declared. No new runtime dependency was added. All application Dart remains in `lib/main.dart`.
- Release web and Android ARM64 builds passed. The APK is 26,857,068 bytes (about 25.6 MiB), approximately 52.9 KB above the preceding build.
- A 390 × 844 release-browser context loaded the real 17.0 km Alabang scooter route and the motorcycle asset with HTTP 200. Inspected screenshots show the rider [assigned](../artifacts/rider-direction-assigned-2026-11-11.png), [turning](../artifacts/rider-direction-turn-2026-11-11.png), [on the road](../artifacts/rider-direction-on-road-2026-11-11.png) and [delivered](../artifacts/rider-direction-delivered-2026-11-11.png). The observed arrival-to-delivered interval was 1,011 ms, within normal frame/scheduler timing of the exact 1,000 ms logical interval. There were no JavaScript page errors or route-failure messages. The isolated context was closed and the regular preview's saved-order storage remains empty.

[Machine-readable results](../artifacts/rider-direction-2026-11-11.json).
