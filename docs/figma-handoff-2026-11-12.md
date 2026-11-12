# Smooch Cafe Figma handoff

[Open the Figma design](https://www.figma.com/design/vy2fN8RIvWKCornJvCfeXi?node-id=7-6)

The current Flutter interface has been recreated as editable Figma Design layouts. This is a design reconstruction and a representative prototype, not an automatic Dart-to-Figma conversion or a second working application.

## Contents

- **01 · Mobile app:** 32 mobile screens/states at 390 × 844, plus a file guide. Includes welcome, the full catalog and six category states, search empty state, sorting, product details, Discover, empty/filled bag, empty/filled order history, cash/GCash checkout, validation, map picker, payment review/processing/success/failure, the five order stages, rider arrival, and the route/receipt detail.
- **02 · Source assets:** all 40 catalog photos, original brand logo, motorcycle image, coffee scene preview and map imagery. Includes reusable product card and primary button components. The app palette is stored as 19 local color variables.
- **03 · Tablet and desktop:** menu layouts at 768 × 1024 and 1440 × 1000, using three and five product columns.

Montserrat and Playfair Display match the source project. Text, vector icons, layout containers, buttons and product cards are editable. Product photos, the coffee scene and map tiles are raster content assets; no complete app-screen screenshot is embedded as a UI substitute. WebP originals were converted to PNG copies for reliable Figma rendering; application assets were not replaced.

## Prototype

Use **Present** in Figma and select one of these flows:

1. **Smooch Cafe · Full journey:** starts at Welcome.
2. **GCash payment flow:** starts at checkout with GCash selected.
3. **Order tracking · 39 seconds:** Confirmed → Preparing → Rider assigned at 10-second intervals, On the way for 8 seconds, then rider arrival for 1 second before Delivered.

Category tabs, navigation, bag/checkout actions, payment choices, retry/failure paths, location picker, order-history entries and tracking states have prototype connections. The Tiramisu Latte card represents the product-details layout. The prototype uses fixed example order information; forms, search, quantities, sorting, map coordinates and payment do not execute application logic.

The coffee scene is a static preview. Map tiles are static previews with separately editable rider markers. Real Flutter animations, GPS, live map interaction, routing and data persistence remain in the Flutter project. Figma does not automatically synchronize future Dart edits.

## Verification

- Read back all 32 mobile frames and confirmed they are on the mobile page.
- Confirmed all rendered text uses Montserrat or Playfair Display.
- Verified 156 image-filled nodes use the known product, logo, scene, map or rider assets.
- Inspected the mobile welcome, menu/category, checkout, payment, tracking and route compositions, plus tablet and desktop menu previews.
- Validated the prototype destinations through the Figma API; the full Figma presentation flow has not been manually played end to end.

No Flutter source, app dependencies, assets or business logic were changed for this handoff. Local screenshots under `artifacts/figma-*` document source references and visual checks. Temporary transfer scripts and PNG copies are under the ignored `.dart_tool/figma-export/` directory.
