import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child, {bool reduced = false, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.theme,
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: navigator!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Montserrat',
    )..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'))).load();
    await (FontLoader(
      'Playfair',
    )..addFont(rootBundle.load('assets/fonts/PlayfairDisplay.ttf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Card press settles after cancellation and does not intercept Add',
    (tester) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      final product = shop.products.first;
      final card = find.byKey(Key('product-${product.id}'));
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: 260,
              height: 340,
              child: ProductCard(product: product, controller: shop),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final press = find.byType(CafePress).first;
      Iterable<Transform> transforms() => tester.widgetList<Transform>(
        find.descendant(of: press, matching: find.byType(Transform)),
      );
      final gesture = await tester.startGesture(tester.getCenter(card));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        transforms().any((widget) => widget.transform.storage[0] < .999),
        isTrue,
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(
        transforms().every(
          (widget) => (widget.transform.storage[0] - 1).abs() < .001,
        ),
        isTrue,
      );
      expect(shop.cartCount, 0);
      await tester.tap(find.byKey(Key('add-${product.id}')));
      await tester.pumpAndSettle();
      expect(shop.cartCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduced motion keeps press feedback static and the action usable',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Center(
            child: CafePress(
              lift: true,
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Choose'),
              ),
            ),
          ),
          reduced: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Choose')),
      );
      await tester.pump(const Duration(milliseconds: 120));
      for (final transform
          in tester
              .widgetList<Transform>(
                find.descendant(
                  of: find.byType(CafePress),
                  matching: find.byType(Transform),
                ),
              )
              .take(2)) {
        expect(transform.transform.storage[0], 1);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'Entrance caches its child and finishes without restarting on parent rebuild',
    (tester) async {
      var builds = 0;
      Widget content() => CafeReveal(
        key: const Key('entrance'),
        child: Builder(
          builder: (_) {
            builds++;
            return const Text('Ready to browse');
          },
        ),
      );
      await tester.pumpWidget(host(content()));
      final start = builds;
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(builds, start);
      await tester.pumpWidget(host(content()));
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(CafeReveal),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Discover shortcut selects its real category and preserves the bag and sort',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.search('latte');
      shop.sortBy(MenuSort.priceHigh);
      shop.addToCart(shop.products.first);
      await tester.pumpWidget(
        host(MenuScreen(controller: shop), reduced: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      final shortcut = find.byKey(const Key('discover-Pastries'));
      await tester.ensureVisible(shortcut);
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Browse Pastries. 6 items.'),
        findsOneWidget,
      );
      semantics.dispose();
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(shop.category, 'Pastries');
      expect(shop.query, isEmpty);
      expect(shop.sort, MenuSort.priceHigh);
      expect(shop.cartCount, 1);
      expect(
        shop.filteredProducts.every(
          (product) => product.category == 'Pastries',
        ),
        isTrue,
      );
      expect(
        tester
            .widget<TabBar>(find.byKey(const Key('category-filters')))
            .controller!
            .index,
        ShopController.categories.indexOf('Pastries'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Discover fits a 320px screen at 2x text with all contact actions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CafeSection(
                onBrowse: () {},
                onCategory: (_) {},
                products: const MenuRepository().products,
              ),
            ),
          ),
          reduced: true,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Call cafe'), findsOneWidget);
      expect(find.byTooltip('Email cafe'), findsOneWidget);
      expect(
        find.text('447 JM Loyola Street, Carmona, Cavite'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Success animation is finite and immediately complete for reduced motion',
    (tester) async {
      await tester.pumpWidget(host(const Center(child: CafeSuccessSeal())));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(
        host(
          const Center(child: CafeSuccessSeal(key: Key('reduced'))),
          reduced: true,
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      final dynamic painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byKey(const Key('order-success-seal')),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter;
      expect(painter.progress, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
