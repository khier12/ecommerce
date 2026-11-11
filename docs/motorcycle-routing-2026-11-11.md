# Motorcycle delivery routing — 11 November 2026

Delivery routes now use a conservative scooter profile and reject routes reported to contain highway, toll or ferry segments. The OpenStreetMap map, endpoint markers, moving gold highlight, pause/recenter controls and 30 km delivery radius retain their existing behavior.

## Provider and route checks

The previous public OSRM driving endpoint rejected both `exclude=motorway` and `exclude=motorway,toll` in live checks with HTTP 400 and `InvalidValue`. Routing now defaults to `https://valhalla1.openstreetmap.de/route` using `motor_scooter` costing. Valhalla documents this profile as favoring lower-class roads and respecting scooter/moped access. The app also requests highway/toll/ferry exclusions, sets highway/toll preferences to zero, and excludes motorway/toll/ferry endpoint candidates. These options follow the [Valhalla route API](https://valhalla.github.io/valhalla/api/route/api-reference/).

The public host returned warning 208 that hard exclusions were ignored. The app therefore checks the response independently:

- Both the trip and its leg must explicitly report `has_highway: false`, `has_toll: false` and `has_ferry: false`. Missing or malformed classification flags cause rejection.
- Every maneuver must report `drive` / `motor_scooter`. Highway, toll and ferry maneuver flags are also rejected, even if summary flags disagree.
- The response must contain one leg for the requested two endpoints, kilometer units, valid metrics and a bounded polyline6 shape.
- Rejected responses never enter the route cache and never trigger a car, bicycle or walking fallback. The map retains its pins and offers Retry with a motorcycle-specific unavailable message.

The scooter profile is a conservative choice for this below-400cc delivery use case, rather than an engine-displacement certification. Road/access classification depends on provider and OpenStreetMap data; this is not a guarantee that every real-world restriction is mapped correctly. Snapping can place a route endpoint on a nearby allowed road. Route distance can exceed 30 km even when the destination is inside the existing straight-line delivery radius.

## Integration

The service keeps its eight-second HTTP timeout, 24-entry ten-minute cache, request deduplication and response/geometry validation limits of 512 KiB and 10,000 points. Cache keys now identify the scooter policy, preventing reuse of an old driving-profile result during a retained session. Public requests are spaced at least one second apart and include `X-Client-Id: SmoochCafeFlutter/1.0`.

Use `--dart-define=VALHALLA_ROUTE_URL=https://routing.example.com/route` for a compatible hosted/self-hosted service. This replaces `OSRM_ROUTE_URL`. The endpoint must support Valhalla's native JSON response with the required safety metadata. The public server is intended for limited development use; its operator's usage guidance is in the [Valhalla README](https://github.com/valhalla/valhalla#demo-server). No account key, new runtime package or native map SDK was added.

Polyline6 coordinates use signed arithmetic for negative deltas. This avoids a Dart-to-JavaScript bitwise-sign difference that initially prevented valid westbound/southbound geometry from displaying in the release browser build. The regression test covers both directions; the platform distinction is documented in [Dart's number representation guide](https://dart.dev/resources/language/number-representation#bitwise-operations).

All application Dart remains in `lib/main.dart`. Customer information, order persistence, payment, delivery stages, product data and image assets are unchanged. The route label now reads “Motorcycle delivery · Avoids expressways and toll roads.”

## Validation

- **165 Flutter tests passed**, including 40 route-service tests and eight map/painter tests. Coverage includes request options, restricted/missing road flags, inconsistent leg/maneuver metadata, wrong vehicle profiles, ignored hard exclusions, no fallback, malformed/oversized geometry, negative coordinate deltas, caching, retries, timeout, stale requests and animation lifecycle.
- Static analysis reports no issues. Android ARM64 release and release web builds succeeded; the APK remains approximately 25.6 MiB. The packaged native binary was checked for the new provider and scooter-policy strings.
- Live requests ran through the actual Dart service and parser for the following public sample destinations. Each returned HTTP 200, `motor_scooter` maneuvers and false highway/toll/ferry summary flags:

| Sample destination | Road distance | Shape points |
| --- | ---: | ---: |
| Alabang Town Center | 17.032 km | 761 |
| Santa Rosa local-road crossing | 8.092 km | 266 |
| Bacoor sample | 28.573 km | 1,281 |

- A separate 390 × 844 browser context opened a temporary receipt and loaded the Alabang route in the real release UI. It displayed **17.0 km by road**, with no route HTTP failures, JavaScript page errors or unavailable-route message. This verifies browser requests, CORS, signed shape decoding and map rendering together. The temporary context was closed; the regular preview's saved-order storage remains empty.
- The standalone Chrome unit-test runner could not start because the installed Flutter SDK referenced a missing archive-path `host.dart.js`. This environment issue is not counted as a passing Chrome test run; release-web behavior was verified in the actual browser as described above.

[Exact request options, live summaries and validation results](../artifacts/motorcycle-routing-2026-11-11.json).
