# Animated delivery route

Order confirmation and saved order details now show a road route whenever the receipt contains a delivery pin. The map displays a dark teal cafe marker, a coral destination marker, and a teal road route with a white outline. A short gold highlight and directional chevron move from origin toward destination over a 6.5-second cycle. Pause/play and Show full route controls allow customers to stop the movement or restore both endpoints after panning. The footer identifies the highlight as route direction; it does not represent a live rider location or delivery progress.

The origin defaults to the app's existing Carmona location, `CheckoutValidation.deliveryCenter` at 14.3158, 121.0561. `DeliveryRouteMap.origin` can supply another configured cafe coordinate. Confirm the precise branch coordinate before using the app operationally. OSRM snaps the inputs to its road network, so a road endpoint can sit a short distance from a house or interior delivery pin. No destination is guessed for orders without a pin.

## Routing and provider setup

`DeliveryRouteService` requests OSRM driving geometry as GeoJSON with a full overview. Coordinates are sent in longitude/latitude order. It validates route status, geometry, coordinate bounds, distance and optional duration, and rejects responses above 512 KiB or 10,000 points. Requests time out after eight seconds. Successful routes use a bounded cache of 24 entries for ten minutes, with in-flight deduplication. Failed requests can be retried; an unavailable route leaves the map pins visible without inventing a straight road. Existing order persistence, stage timing, GPS permissions, and address selection stay independent from routing.

The default endpoint is `https://router.project-osrm.org/route/v1/driving`. Requests to that public host reserve slots at least one second apart across service instances. Its operator restricts use to reasonable noncommercial cases and does not guarantee availability. Configure an OSRM-compatible service for production using `--dart-define=OSRM_ROUTE_URL=https://routing.example.com/route/v1/driving`. This is separate from the existing `MAP_TILE_URL` setting. Protocol and public-service limits follow the [OSRM API documentation](https://project-osrm.org/docs/v5.24.0/api/) and [official server policy](https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server).

## Motion and accessibility

The route controller belongs to the map state and stops while paused, when the app leaves the foreground, when its route disables tickers, or when reduced motion is enabled. Reduced motion draws a stationary directional accent. Only the highlight's custom painter repaints during its loop; map tiles, marker widgets, route geometry and camera are not rebuilt by animation ticks. Projected path metrics update when the map camera changes. The highlight fills the map bounds, ignores pointer input, and is excluded from accessibility announcements. The endpoint markers have accessible labels. Old asynchronous results cannot overwrite a changed destination or update a disposed widget.

## Verification

- Static analysis: no issues.
- Full Flutter suite: **127 passed**. Added 25 service tests and eight map/painter tests.
- Coverage includes route parsing, invalid/network/timeout responses, bounded cache/expiry, deduplication, retry, stale asynchronous results, lifecycle suspension, reduced motion, pause/play, and map recentering at 320 pixels with 2× text.
- Raster checks confirm that the highlight paints visible pixels and changes between phases. Widget layout checks confirm it fills the full map rather than receiving zero drawing bounds.
- Browser: a live Carmona route loaded with HTTP 200; the road highlight visibly changed between frames, while paused and reduced-motion frames stayed identical. The normal, pause and viewport checks used one routing request. Phone, tablet and desktop previews showed no JavaScript page errors.
- Release web and Android debug APK builds both succeeded after the final layout fix.
- Product catalog and importer markers are unchanged. All application Dart remains in `lib/main.dart`.

Previews: [phone](../artifacts/delivery-route-phone.png), [tablet](../artifacts/delivery-route-tablet.png), [desktop](../artifacts/delivery-route-desktop.png). Physical-device animation performance and iOS rendering were not measured on this Windows host.
