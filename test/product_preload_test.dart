import 'dart:async';
import 'dart:convert';

import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Record real AssetImage resolutions through the normal Flutter image cache.
// Tiny valid image bytes keep these loading/lifecycle tests independent of the
// catalog's encoding; asset_bundle_test.dart decodes every shipped photo.
class _RecordingBundle extends CachingAssetBundle {
  final requests = <String>[];
  final catalogImages = cafeProducts.map((product) => product.image).toSet();
  String? blockedImage;
  String? failingImage;
  final unblock = Completer<void>();
  final _pixel = ByteData.sublistView(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC',
    ),
  );

  List<String> get productRequests =>
      requests.where(catalogImages.contains).toList();

  @override
  Future<ByteData> load(String key) async {
    if (!key.startsWith('assets/images/')) return rootBundle.load(key);
    requests.add(key);
    if (key == blockedImage) await unblock.future;
    if (key == failingImage) throw StateError('Unavailable product photo');
    return _pixel;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ShopController shop;
  late _RecordingBundle bundle;

  setUpAll(() async {
    await (FontLoader(
      'Montserrat',
    )..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'))).load();
    await (FontLoader(
      'Playfair',
    )..addFont(rootBundle.load('assets/fonts/PlayfairDisplay.ttf'))).load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    shop = ShopController(repository: const MenuRepository());
    bundle = _RecordingBundle();
  });

  tearDown(() {
    shop.dispose();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  Future<void> open(WidgetTester tester, {bool start = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => DefaultAssetBundle(
          bundle: bundle,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
        home: start
            ? StartScreen(controller: shop, versionReader: () async => '1.0.0')
            : MenuScreen(controller: shop),
      ),
    );
  }

  Future<void> advanceLoading(WidgetTester tester, {int frames = 35}) async {
    for (var frame = 0; frame < frames; frame++) {
      await tester.pump(const Duration(milliseconds: 40));
      // Image codec callbacks complete outside the fake widget-test clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
    }
    await tester.pump();
  }

  testWidgets('Waiting on start warms six thumbnails and never the catalog', (
    tester,
  ) async {
    await open(tester);
    await advanceLoading(tester);
    expect(
      bundle.productRequests,
      unorderedEquals(shop.products.take(6).map((product) => product.image)),
    );
    expect(bundle.requests, isNot(contains('assets/images/landing1.png')));
    expect(
      bundle.requests,
      isNot(
        contains('assets/images/Ice Blended Choco Hazelnut transparent.png'),
      ),
    );
    final count = bundle.productRequests.length;
    await advanceLoading(tester, frames: 100);
    expect(bundle.productRequests, hasLength(count));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preload follows the current category and sort order', (
    tester,
  ) async {
    shop.selectCategory('Food');
    shop.sortBy(MenuSort.priceHigh);
    await open(tester);
    await advanceLoading(tester);
    expect(
      bundle.productRequests,
      orderedEquals(
        shop.filteredProducts.take(6).map((product) => product.image),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sorted All keeps the visible carousel within the six-image budget',
    (tester) async {
      shop.sortBy(MenuSort.priceHigh);
      await open(tester);
      await advanceLoading(tester);
      final carousel = shop.products
          .where((product) => product.featured)
          .take(2);
      expect(
        bundle.productRequests.take(2),
        carousel.map((product) => product.image),
      );
      expect(bundle.productRequests, hasLength(6));
      expect(bundle.productRequests.toSet(), hasLength(6));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search preloads only matching products and accepts no matches', (
    tester,
  ) async {
    shop.search('tiramisu latte');
    await open(tester);
    await advanceLoading(tester);
    expect(bundle.productRequests, [shop.filteredProducts.single.image]);
    await tester.pumpWidget(const SizedBox.shrink());
    bundle = _RecordingBundle();
    shop.search('no-such-product');
    await open(tester);
    await advanceLoading(tester);
    expect(bundle.productRequests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Backgrounding pauses the queue, including after an in-flight decode',
    (tester) async {
      bundle.blockedImage = shop.products.first.image;
      await open(tester);
      await advanceLoading(tester, frames: 3);
      expect(bundle.productRequests, [shop.products.first.image]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      bundle.unblock.complete();
      await advanceLoading(tester);
      expect(bundle.productRequests, hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await advanceLoading(tester);
      expect(bundle.productRequests, hasLength(6));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Leaving start stops its queue after an in-flight decode', (
    tester,
  ) async {
    bundle.blockedImage = shop.products.first.image;
    await open(tester);
    await advanceLoading(tester, frames: 3);
    expect(bundle.productRequests, hasLength(1));
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MenuScreen), findsOneWidget);
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    final requestsAfterLeaving = List<String>.of(bundle.productRequests);
    bundle.unblock.complete();
    await advanceLoading(tester, frames: 100);
    expect(bundle.productRequests, requestsAfterLeaving);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Disposing cancels a pending timer and an in-flight preload safely',
    (tester) async {
      await open(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await advanceLoading(tester);
      expect(bundle.productRequests, isEmpty);

      bundle = _RecordingBundle()..blockedImage = shop.products.first.image;
      await open(tester);
      await advanceLoading(tester, frames: 3);
      expect(bundle.productRequests, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      bundle.unblock.complete();
      await advanceLoading(tester);
      expect(bundle.productRequests, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A failed preload does not block ordering or the remaining thumbnails',
    (tester) async {
      bundle.failingImage = shop.products.first.image;
      await open(tester);
      await advanceLoading(tester);
      expect(bundle.productRequests, hasLength(6));
      expect(
        find.byKey(const Key('enter-store')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Returning to start refreshes the small preview after filter changes',
    (tester) async {
      await open(tester);
      await advanceLoading(tester);
      final initial = bundle.productRequests.toSet();
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pumpAndSettle();
      shop.selectCategory('Food');
      shop.sortBy(MenuSort.priceHigh);
      await tester.pumpAndSettle();
      final beforeReturn = bundle.productRequests.toSet();
      final expectedPreview = shop.filteredProducts
          .take(6)
          .map((product) => product.image)
          .toSet();
      Navigator.of(tester.element(find.byType(MenuScreen))).pop();
      await tester.pumpAndSettle();
      await advanceLoading(tester);
      expect(find.byType(StartScreen), findsOneWidget);
      expect(bundle.productRequests.toSet(), containsAll(expectedPreview));
      expect(
        bundle.productRequests.toSet().difference(beforeReturn),
        everyElement(isIn(expectedPreview)),
      );
      expect(initial.length, 6);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Menu reuses warmed thumbnails and loads new photos on demand', (
    tester,
  ) async {
    await open(tester);
    await advanceLoading(tester);
    final firstPhoto = shop.products.first.image;
    expect(
      bundle.productRequests.where((path) => path == firstPhoto),
      hasLength(1),
    );
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pumpAndSettle();
    await advanceLoading(tester);
    expect(
      bundle.productRequests.where((path) => path == firstPhoto),
      hasLength(1),
    );
    expect(
      bundle.productRequests.toSet().length,
      lessThan(shop.products.length),
    );

    final last = shop.products.last;
    expect(bundle.productRequests, isNot(contains(last.image)));
    final category = find.byKey(Key('category-${last.category}'));
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    final list = find.byType(CustomScrollView).first;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(last.id)),
      400,
      scrollable: find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first,
    );
    await advanceLoading(tester);
    expect(bundle.productRequests, contains(last.image));
    expect(find.byKey(ValueKey(last.id)).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
