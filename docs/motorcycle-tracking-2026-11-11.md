# Motorcycle tracking — 11 November 2026

The subsequent [rider artwork and alignment update](rider-direction-2026-11-11.md) replaces the teal badge described here with the user's supplied PNG, centers it on the road and adds direction changes. The timeline below remains unchanged; validation results below record this earlier implementation.

The repeating yellow route highlight has been replaced by a teal motorcycle marker. The existing teal road, cafe and destination pins, scooter routing policy, 30 km delivery area, payment and stored receipt format remain in place. All application Dart remains in `lib/main.dart`.

## Order timing

| Time after placing order | Status | Motorcycle |
| --- | --- | --- |
| 0–10 seconds | Confirmed | Hidden |
| 10–20 seconds | Preparing | Hidden |
| 20–30 seconds | Rider assigned | Stationary at Smooch Cafe |
| 30–40 seconds | On the way | Travels once along the validated road |
| 40–41 seconds | On the way | Stationary at the destination; arrival copy appears |
| 41 seconds onward | Delivered | Remains at the destination |

The confirmation screen owns one `OrderTimeline` shared by the tracking panel and route map. Timers update milestone states; an animation controller drives only the motorcycle transform during travel. Order history uses the same saved-time calculation. The one-second arrival interval is part of the timeline, including receipts without a map pin. Legacy pickup orders retain their original three-stage timing.

Opening an order mid-trip resumes the saved elapsed position. Late route responses join the current position rather than restarting the ride. The animation does not loop. If no validated road is available, the app does not invent a straight-line journey: the rider can appear at the store or at the completed delivery endpoint, while the map offers Retry.

## Motion and lifecycle

The road is projected and measured when geometry or the map camera changes. Each animation frame samples the cached path metric and translates a cached motorcycle badge; the map, route service, product data and receipt layout do not rebuild per frame. Camera fitting leaves space above endpoint pins for the rider badge. The full-route recenter control remains available; the decorative highlight's pause/play control has been removed.

Reduced motion disables continuous travel and shows static positions, with the destination shown at the arrival milestone. Background and disabled-ticker states stop frame animation. Resuming catches up with the current order time. Timers, observers and animation controllers are disposed by their owners.

This remains the app's local order presentation, not a connection to a restaurant backend or live rider GPS. Provider road duration does not control the accelerated order timeline. No new package, map provider, account key or persisted field was added.

## Verification

- Route tests cover store waiting, road movement, a stationary arrival interval of exactly 999 ms followed by Delivered at 1,000 ms, no replay, static reduced-motion behavior, lifecycle catch-up, delayed road responses and saved orders.
- The path test checks that the motorcycle passes through road corners rather than cutting across them.
- Existing route safety, stale responses, retry, disposal and narrow/large-text map-fitting checks remain in place.
- All **168 Flutter tests passed**, including 11 route-map/path tests. Static analysis and `git diff --check` passed. Release web and Android ARM64 builds succeeded; the APK is 26,804,180 bytes (about 25.6 MiB).
- An isolated 390 × 844 release-browser context exercised a receipt against the real Alabang scooter route. Screenshots show the rider [at the store](../artifacts/motorcycle-assigned-2026-11-11.png), [on the way](../artifacts/motorcycle-on-the-way-2026-11-11.png), [at arrival](../artifacts/motorcycle-arrived-2026-11-11.png) and [after delivery](../artifacts/motorcycle-delivered-2026-11-11.png). Browser semantics reported a 1,003.5 ms arrival-to-delivered interval, within frame/scheduler timing of the exact 1,000 ms logical delay. No JavaScript page errors or unavailable-route message occurred. The isolated context was closed; the regular preview's saved-order storage remains empty.

[Machine-readable validation results](../artifacts/motorcycle-tracking-2026-11-11.json).
