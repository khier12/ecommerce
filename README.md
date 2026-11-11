# Smooch Cafe

A Flutter cafe shopping app adapted from the supplied **SmoochCafe** website and MiniShop starter code.

## Run

Use the installed Flutter SDK (Dart 3.13.1 or compatible):

```sh
flutter pub get
flutter run
```

For a browser preview, run `flutter run -d chrome`. For Android, connect a device or start an emulator, then select it with `flutter run`.

An installable debug APK is available after `flutter build apk --debug` at `build/app/outputs/flutter-apk/app-debug.apk`. Release web output is generated in `build/web/`.

## Included

- An interactive 3D Start Screen with a glazed teal mug, heart latte art, curved Smooch logo, floating cream saucer, orbiting beans, steam, and studio lighting. The 2.4-second entrance runs alongside immediately readable copy and a usable ORDER NOW button. Hover or drag horizontally to tilt the scene; releasing it gently returns it to rest. Idle motion loops seamlessly, pauses in the menu/background, and resumes on return. Reduced motion shows a complete still scene. Wide screens place the copy and scene side by side; animation rebuilds remain isolated from the static layout. See the [3D scene implementation and checks](docs/starting-scene-2026-11-01.md).
- ORDER NOW opens the menu using `Navigator.push()` and `MaterialPageRoute`. Back returns to the Start Screen; the bag remains available when entering again. Rapid taps open one menu. Reduced-motion settings show a still composition.
- On Android and iOS, a coordinated 600 ms transition fades through teal before gently revealing the menu. Browser and desktop routes open immediately. At most six initial menu thumbnails are preloaded during the intro; the remaining images load through the existing lazy grids and pages as customers browse.
- A curated 40-product menu from the supplied website: Coffee 8, Non-Coffee 6, Food 8, Pastries 6, Ice Blended 6 and More Drinks 6. Original names, prices and photos are retained for these products. All six featured picks remain available. Old receipts retain their saved product details; retired photos use a cafe icon. See [the selection and validation](docs/menu-selection-2026-11-11.md).
- Search and a horizontally scrollable category tab rail stay visible above the menu. The selected category scrolls into view and has a moving teal underline; there are no category arrows. Tapping the active category keeps it selected. Choose All to browse every category, or use Reset to clear search, category, and sorting together.
- Product grids follow horizontal swipes using `TabBarView`, keeping the active tab and displayed products in sync. The featured-product carousel remains on All and shows untinted product photos beside a dark text panel. Reduced-motion settings make category taps jump directly to the selected page.
- Search matches words in any order and ignores extra whitespace. Clearing search preserves the chosen category and sort order.
- Every `Product.category` matches a filter choice. Descriptive product labels, such as Quarter Pounder or Brownies, are kept in `Product.subcategory` and remain searchable.
- Product details with a persistent quantity/Add to bag footer, an Order History tab with saved receipts, and browsing positions retained when switching tabs.
- Compact product cards with shorter photos, price/Add controls side by side, and up to five columns on wide screens. Cards adapt for larger text and retain in-bag quantities and a persistent bag summary with Philippine peso totals. Adding an item sends its photo along a curved path to the bag icon, briefly shows a teal “Added” confirmation, and pulses the bag icon. Product details returns to the menu after the flight. Reduced-motion settings skip the movement.
- Shared cart with quantities, item removal, Undo, and a live badge. Bag contents and totals use a comfortable reading width on desktop.
- The bag leads to delivery-only checkout with required name, Philippine mobile number, and delivery address, plus optional notes and cash or a GCash-style payment preview. Choose a destination by tapping an OpenStreetMap map or request GPS location with **Use GPS**. The selected pin is saved with the order and shown on its receipt. Check and edit the street and house number before ordering. The wallet screen shows the checkout amount and masked mobile, then previews processing, success, failure, or cancellation. It never asks for a PIN or OTP, is not connected to GCash, and takes no money. The bag stays intact until an order is saved successfully.
- Checkout groups contact, delivery, and payment details, supports autofill, and keeps the order total beside the primary action. Invalid submissions scroll to the first field needing attention; errors update as the customer corrects them. A delivery pin can be moved or removed, and manual address edits are preserved. Failed saving leaves the bag intact.
- Delivery receipts show five stages: Confirmed, Preparing, Rider assigned, On the way, and Delivered. The first three transitions occur at 10-second intervals. A motorcycle waits at the store during Rider assigned, travels along the road for 8 seconds during On the way, and waits at the destination for one second before Delivered. One timeline drives the receipt status and motorcycle; order history and reopened receipts catch up from the saved order time. Older pickup receipts remain readable in history; new orders are delivery-only. The receipt also shows customer details, address and destination map when available, payment method/status, products, quantities, and total. References continue in sequence. These stages still run locally: no order is sent to the cafe, no real rider is assigned or tracked, and no real payment is taken. Digital receipts say **Payment step complete**. Customer-facing text uses natural order labels without the words demo, simulated, or simulation; the wallet retains its payment-preview notice.
- Discover presents Coffee, Food, and Pastries as compact image shortcuts with real item counts. One grouped Visit Smooch panel holds the original location, hours, phone, email, and delivery area. Collection shortcuts open the matching menu category, clear the previous search, and retain the bag and sort preference. Contact actions open the device's phone or email application. Repeated introductions, the promotional story panel, and redundant decorative labels have been removed.
- Responsive phone, tablet, and desktop layouts, plus widget previews at the end of `lib/main.dart`.
- Scroll-aware edge fades hint at sideways browsing, scrolling content clears system controls, and long pages use a single scrollbar. Tapping the active main destination returns to the top; tapping Our menu again at the top focuses search. The active page supplies the iPhone tap-to-top scroll controller.
- Checkout groups Philippine mobile digits as you type, supports a multiline address, and dismisses the keyboard while scrolling or opening Sort. Peso amounts, counts, and receipt dates follow the device locale; changing numeric values use tabular figures. Text selection uses the cafe teal, and enlarged text is supported up to 2×.
- Supported phones provide subtle haptic feedback for important actions and results. Discover includes the installed version. A branded error fallback adapts to the failed widget's space and hides technical details in release builds.
- Product cards and primary actions use subtle spring press feedback; cards also lift on desktop hover. Featured picks scale gently with horizontal swipes, and a sliding teal capsule stays synchronized with the category pages. Product photos fade in when needed, with 640-pixel decode requests for browsing and 1024-pixel requests for detail images on supported native platforms.
- Shared section headings, larger featured photography, gold cafe-pick accents, and consistent rounded surfaces give the app a warmer editorial style. The bag has a refreshed summary heading; checkout steps have numbered icon headers. A finite drawn checkmark and ring confirm a new order, while tracking segments follow the shared order timeline. Reduced-motion settings skip decorative movement and preserve order timing.
- The 3D Start Screen is the only introduction. The extra startup logo, loading message, and progress bar have been removed. Web, Android, and iOS use a plain matching teal background while Flutter initializes, with no artificial wait. Browser initialization failures offer Reload; successful startup goes straight to the 3D screen. Browser tab titles follow pages, products, and main destinations, including Back navigation.

The bag is kept in memory during the app session. Completed receipts and the next reference number are stored locally on the device with `shared_preferences`. History has loading/error feedback and retry for read failures; corrupt individual records are skipped while valid receipts are retained. References are also checked against restored records. The app has no backend or account system, so history does not sync across devices.

The map needs internet access. GPS permission is requested only after the customer chooses **Use GPS** or **Use my location**; manually placing a pin does not request it. A manual pin takes precedence over a pending GPS response. Address suggestions first use OpenStreetMap/Nominatim, with device geocoding as a fallback on Android, iOS, and macOS. Blank or serialized `null` address parts are omitted. Lookup failures still allow a valid pin, and accepting a suggestion is explicit when the customer has typed an address. Delivery pins must be within a 30 km radius of the configured cafe location in Carmona. GPS, map selection and checkout share this straight-line distance limit. Browser GPS requires HTTPS or localhost. If location access is unavailable, customers can still enter the delivery address manually. Set `MAP_TILE_URL` with `--dart-define` to use a different compatible tile provider for larger deployments.

Receipts with a delivery pin show a road route from the configured cafe origin using Valhalla's conservative scooter profile over the existing OpenStreetMap map. Routes with reported highway, toll or ferry segments, missing road classifications or another travel profile are rejected. The app requests expressway/toll exclusions and validates the result because the public host can ignore hard-exclusion settings; it never falls back to a car/bicycle/walking route. The supplied transparent motorcycle artwork follows the teal road for 8 seconds during On the way, without a background disk or shadow. Its center stays on the visible line, and its heading eases through turns; westbound travel mirrors the side-view rider to keep it upright. The marker and line share the same road vertices without added endpoint shortcuts. **Full route** fits the complete road more tightly inside a responsive 280–340 pixel map, with safe room for the markers and attribution. Resizing refits automatically, and a clearer rider status and distance summary sits below the map; there is no playback control that can desynchronize the status. Reduced motion uses static rider positions and preserves the arrival timing. Requests are cached and deduplicated; failures keep the endpoint pins and offer Retry. A late route result joins the current trip position rather than restarting it. Set `VALHALLA_ROUTE_URL` with `--dart-define` to select a compatible service; this replaces `OSRM_ROUTE_URL`. The default public endpoint is for limited development use; configure suitable hosting before a public rollout. Road/access accuracy depends on OpenStreetMap data. See [motorcycle routing and setup](docs/motorcycle-routing-2026-11-11.md) and [motorcycle motion and status timing](docs/motorcycle-tracking-2026-11-11.md), plus [rider artwork, direction and alignment](docs/rider-direction-2026-11-11.md) and [delivery-map framing and design](docs/delivery-map-polish-2026-11-11.md).

Release notes live in the `releaseNotes` map in `main.dart`. On a future version upgrade, relevant notes appear once on the Start Screen; first installation skips the dialog. Add an entry matching the next release's version when preparing that release. This implementation keeps the current `1.0.0+1` version. The `smooch_last_seen_version` preference is separate from saved receipts.

The 1200 × 630 share card is ready at `web/og-image.png`. There is no public URL yet, so crawler metadata is intentionally waiting for hosting. Once a public HTTPS URL is known, run `node tools/configure_web_preview.mjs <public-HTTPS-URL>` and rebuild web. The tool writes static Open Graph/X tags, preserves hosted subpaths, and can be rerun without duplicating tags. After deployment, verify that the page and absolute image URL are publicly accessible. This tool does not publish the app.

## Design

The app retains the website's dark teal `#0A4952`, teal `#0E6F7A`, and original coral `#F04C45` branding. Shopping screens use warm ivory `#F6F3ED`, white cards, and ink `#163B3D` for easier scanning. Primary buttons use deeper coral `#C23F38` for 5.17:1 contrast with white labels. The 3D splash retains its dark teal atmosphere. The wallet screen uses blue to evoke the GCash payment flow and marks itself as a preview.

Montserrat and Playfair Display are bundled locally, with their open font licenses in `assets/fonts/`. The supplied logo and photos are bundled as Flutter assets. See [the visual and animation polish report](docs/ui-motion-polish-2026-11-01.md) for the latest redesign and validation, and [the earlier design implementation report](docs/improvements/design/implementation.md) for the 25-plan work. The [complete application audit](docs/application-audit-2026-10-29.md) and [earlier menu UI/UX audit](docs/menu-ui-ux-audit.md) record earlier changes, assignment compliance, and color measurements.

## Code

```text
lib/
  main.dart                  Complete application, following the starter layout
```

All application Dart code is in `lib/main.dart`, just like the supplied base code. `main()` runs `MiniShopApp`. Section comments separate colors/theme, product models and data, shopping state, the main application, shared widgets, Start Screen/transition, menu/filter controls, product cards, product details, cart, checkout, payment preview, order history/confirmation, cafe information, the 3D painter, and widget previews. There are no local Dart imports or `part` files.

Product photos and the logo are in `assets/images/`; fonts are in `assets/fonts/`. The 41 files in `assets/images/` are bundled: the 40 selected product photos and logo. The supplied 512-pixel motorcycle PNG is separately bundled in `assets/icons/` and decoded at a bounded size for the map marker. Following menu curation, 52 retired product photos and two former splash artworks were deleted, removing 16.8 MiB of source images. Remaining images retain their optimized bytes from step 2. After adding or changing image paths in Dart, run `node tools/sync_flutter_assets.mjs`, then `flutter pub get`. Synchronization updates declarations without deleting files; the catalog importer runs it automatically and resolves original website PNG names to existing WebP variants. Tests live under `test/` and import `main.dart`. See [the cleanup results](docs/menu-image-cleanup-2026-11-11.md), [step 1](docs/performance-step1-2026-11-10.md) and [step 2](docs/performance-step2-2026-11-10.md).

Step 3 limits startup warming to six unique thumbnails from the current menu preview, respecting filters, sorting and the initial featured carousel. Other photos load as users browse the existing lazy grid/pages. Pending warming stops on navigation/backgrounding and resumes only on the visible start screen. See [step 3 results and loading checks](docs/performance-step3-2026-11-10.md) for its earlier 38.2 MiB release measurement, before the later image cleanup.

Step 4 reduces per-frame 3D renderer object construction using retained working vectors, packed colors, cached logo topology and index storage. All 44 checked before/after renders were byte-identical; see [the optimization and validation](docs/performance-step4-2026-11-11.md).

The original Flutter starter is preserved in `docs/flutter_starter.dart.txt`. The app runs from the catalog in `main.dart` and the bundled assets; the original website folder is optional.

Edit products directly in the `PRODUCT DATA` section of `main.dart`. If the original website is available at `SmoochCafe/pages/products.html`, you can also regenerate the catalog with Node.js:

```sh
node tools/import_menu.mjs
dart format lib/main.dart
```

The importer updates only the `BEGIN CAFE CATALOG` / `END CAFE CATALOG` section inside `main.dart`. It checks image paths, including filename capitalization, and creates separate IDs for similarly named products in different categories. Descriptions are adapted for the app; names, prices, and categories come from the supplied menu.

`cafeMenuProductIds`, outside the importer block, selects the 40 products available for browsing. `MenuRepository` exposes one immutable selection to menu filters, featured picks and Discover counts. The importer skips unselected products before resolving photos and requires every selected ID to exist. To restore a retired item, restore its image and add its ID before importing. Receipts retain their own product snapshots: active IDs use the current image filename, and retired IDs display a cafe icon without requesting deleted files.

## Verify

```sh
dart format lib/main.dart
node tools/sync_flutter_assets.mjs --check
flutter analyze
flutter test
node --test test/web_preview_test.mjs test/flutter_assets_test.mjs test/product_images_test.mjs test/menu_selection_test.mjs
flutter build web
flutter build apk --debug
```

The 173 Flutter tests cover catalog assets and IDs, filters and swipes, inclusive 30 km delivery boundaries, category synchronization, bag/Undo, checkout validation, payment outcomes, storage safety, receipt history, GPS/manual-pin races, address lookup failures, reduced motion, narrow/large-text layouts, localized formatting, phone editing, release notes, navigation reselect and titles, scroll hints/insets, version metadata, and the error fallback. UI tests also verify press cancellation, cached entrance subtrees, Discover navigation and semantics, 320-pixel/2× text layout, and finite order-success motion. A retained-buffer regression test compares eight changing poses/sizes against fresh rendering. Six starting-scene tests cover hover/drag recovery, vertical scrolling, ordering, live reduced-motion changes, safe painter bounds, and byte-identical loop endpoints/static accessible rendering. The routing additions include 40 service tests and 16 route-map/path tests. Ten preload tests validate bounded image loading, lifecycle safety and cache reuse. Four bundle tests validate the image manifest, actual decoding, optimized detail resolution and removal of unused artwork. Twenty-one Node tests cover image synchronization, optimized import paths, selected-menu imports and share-metadata setup. Three legacy-image tests cover cafe-icon fallback, current filename resolution and readable historical receipts after photo removal. Browser checks exercised splash → Discover/menu → details → bag → map/checkout → payment failure/cancellation/success → receipt/history, plus tablet and desktop layouts. Native haptics, the physical iPhone status-bar gesture, GPS accuracy, and native geocoding still require checks on devices; these checks do not establish device frame rates.
