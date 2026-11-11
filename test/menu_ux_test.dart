import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce/main.dart';

void main() {
  late ShopController shop;
  setUp(() => shop = ShopController(repository: const MenuRepository()));
  tearDown(() => shop.dispose());

  Future<void> openMenu(
    WidgetTester tester, {
    double scale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: MenuScreen(controller: shop),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapCategory(WidgetTester tester, String category) async {
    final tab = find.byKey(Key('category-$category'));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  testWidgets('Visible categories and empty search recovery keep the query', (
    tester,
  ) async {
    await openMenu(tester);
    await tapCategory(tester, 'Food');
    await tester.enterText(
      find.byKey(const Key('menu-search')),
      'tiramisu latte',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matches found.'), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Search all categories')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search all categories'));
    await tester.pumpAndSettle();
    expect(shop.category, 'All');
    expect(find.byKey(const Key('category-All')).hitTestable(), findsOneWidget);
    expect(shop.query, 'tiramisu latte');
    expect(find.text('1 item for “tiramisu latte”'), findsOneWidget);
    expect(find.text('Tiramisu Latte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Search remains reachable after scrolling and tabs preserve position',
    (tester) async {
      await openMenu(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('menu-search')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('category-filters')).hitTestable(),
        findsOneWidget,
      );
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView).first)
          .controller!;
      final position = scroll.offset;
      expect(position, greaterThan(200));
      await tester.tap(find.text('Order history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Our menu'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CustomScrollView>(find.byType(CustomScrollView).first)
            .controller!
            .offset,
        closeTo(position, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Horizontal category rail reaches every category without arrows',
    (tester) async {
      await openMenu(tester);
      expect(find.byTooltip('Previous categories'), findsNothing);
      expect(find.byTooltip('Next categories'), findsNothing);
      for (final category in ShopController.categories) {
        expect(find.byKey(Key('category-$category')), findsOneWidget);
      }
      await tapCategory(tester, 'More Drinks');
      final last = find.byKey(const Key('category-More Drinks'));
      expect(last.hitTestable(), findsOneWidget);
      expect(shop.category, 'More Drinks');
      expect(shop.filteredProducts, hasLength(6));
      expect(
        shop.filteredProducts.every((p) => p.category == 'More Drinks'),
        isTrue,
      );
      await tapCategory(tester, 'More Drinks');
      expect(shop.category, 'More Drinks');
      await tapCategory(tester, 'All');
      expect(shop.category, 'All');
      expect(shop.filteredProducts, hasLength(40));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reset clears search category and sorting while retaining bag and orders',
    (tester) async {
      shop.selectCategory('Coffee');
      shop.search('latte');
      shop.sortBy(MenuSort.priceLow);
      shop.addToCart(shop.products.first);
      await shop.submitOrder(
        customerName: 'Guest',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      );
      shop.addToCart(shop.products.first);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('reset-menu-filters')));
      await tester.pumpAndSettle();
      expect(shop.hasActiveFilters, isFalse);
      expect(shop.query, isEmpty);
      expect(shop.category, 'All');
      expect(shop.sort, MenuSort.recommended);
      expect(shop.filteredProducts, hasLength(40));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('menu-search')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TabBar>(find.byKey(const Key('category-filters')))
            .controller!
            .index,
        0,
      );
      expect(find.byKey(const Key('reset-menu-filters')), findsNothing);
      expect(shop.cartCount, 1);
      expect(shop.total, 145);
      expect(shop.orders, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Clear search preserves category and sort on desktop', (
    tester,
  ) async {
    shop.selectCategory('Coffee');
    shop.sortBy(MenuSort.priceLow);
    shop.search('latte');
    await openMenu(tester, size: const Size(1440, 1000));
    expect(find.byTooltip('Previous categories'), findsNothing);
    expect(find.byTooltip('Next categories'), findsNothing);
    expect(find.byTooltip('Browse categories'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(shop.query, isEmpty);
    expect(shop.category, 'Coffee');
    expect(shop.sort, MenuSort.priceLow);
    expect(shop.filteredProducts, hasLength(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order history replaces Favorites on desktop', (tester) async {
    shop.addToCart(shop.products.first);
    await shop.submitOrder(
      customerName: 'Juan Dela Cruz',
      mobileNumber: '09171234567',
      notes: '',
      paymentMethod: PaymentMethod.cash,
      deliveryAddress: '12 Rizal Street, Carmona, Cavite',
    );
    await openMenu(tester, size: const Size(1024, 768));
    expect(find.text('Favorites'), findsNothing);
    expect(find.byTooltip('Order history'), findsNothing);
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-SMC-0001')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-SMC-0001')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery for Juan Dela Cruz'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-shopping')));
    await tester.pumpAndSettle();
    expect(find.text('Your orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add button updates the persistent bag total and opens cart', (
    tester,
  ) async {
    await openMenu(tester);
    final add = find.byKey(const Key('add-coffee-tiramisu-latte'));
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('view-bag-summary')), findsOneWidget);
    expect(shop.total, 145);
    await Scrollable.ensureVisible(tester.element(add), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('₱290.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('view-bag-summary')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-total'))).data,
      '₱290.00',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Product photo flies toward the bag when Add is tapped', (
    tester,
  ) async {
    await openMenu(tester);
    final add = find.byKey(const Key('add-coffee-tiramisu-latte'));
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    final flight = find.byKey(const Key('cart-flight-coffee-tiramisu-latte'));
    final bag = find.byKey(const Key('cart-pulse'));
    expect(flight, findsOneWidget);
    expect(shop.cartCount, 1);
    final initialDistance =
        (tester.getCenter(flight) - tester.getCenter(bag)).distance;
    await tester.pump(const Duration(milliseconds: 650));
    expect(flight, findsOneWidget);
    expect(
      (tester.getCenter(flight) - tester.getCenter(bag)).distance,
      lessThan(initialDistance),
    );
    await tester.pumpAndSettle();
    expect(flight, findsNothing);
    expect(shop.cartCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Details Add flies to the bag before returning to menu', (
    tester,
  ) async {
    await openMenu(tester);
    final product = find.byKey(const Key('product-coffee-tiramisu-latte'));
    await tester.scrollUntilVisible(
      product,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(product);
    await tester.pumpAndSettle();
    final add = find.byKey(const Key('details-add-to-cart'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    expect(shop.cartCount, 1);
    expect(
      find.byKey(const Key('cart-flight-coffee-tiramisu-latte')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(shop.cartCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add feedback resets while rapid taps still increase the bag', (
    tester,
  ) async {
    await openMenu(tester);
    final add = find.byKey(const Key('add-coffee-tiramisu-latte'));
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    expect(shop.cartCount, 1);
    expect(
      find.descendant(of: add, matching: find.text('Added')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 70));
    final pulse = tester.widget<ScaleTransition>(
      find.byKey(const Key('cart-pulse')),
    );
    expect(pulse.scale.value, greaterThan(1));
    await tester.tap(add);
    await tester.pump();
    expect(shop.cartCount, 2);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      find.descendant(of: add, matching: find.text('Add')),
      findsOneWidget,
    );
    expect(pulse.scale.value, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Featured add button confirms with a checkmark', (tester) async {
    await openMenu(tester);
    final add = find.byKey(const Key('featured-add-coffee-tiramisu-latte'));
    await tester.tap(add);
    await tester.pump();
    expect(shop.cartCount, 1);
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.add)),
      findsOneWidget,
    );
  });

  testWidgets('Reduced motion keeps add feedback without moving controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MenuScreen(controller: shop),
      ),
    );
    final add = find.byKey(const Key('add-coffee-tiramisu-latte'));
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    expect(shop.cartCount, 1);
    expect(
      find.descendant(of: add, matching: find.text('Added')),
      findsOneWidget,
    );
    final feedback = tester.widget<AnimatedScale>(
      find.byKey(const Key('add-feedback-coffee-tiramisu-latte')),
    );
    expect(feedback.duration, Duration.zero);
    expect(feedback.scale, 1);
    expect(
      find.byKey(const Key('cart-flight-coffee-tiramisu-latte')),
      findsNothing,
    );
    expect(
      tester
          .widget<ScaleTransition>(find.byKey(const Key('cart-pulse')))
          .scale
          .value,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu and bag summary accommodate larger text', (tester) async {
    shop.addToCart(shop.products.first);
    await openMenu(tester, scale: 1.6);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-search')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('view-bag-summary')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('Shopping text and primary actions retain at least 4.5:1 contrast', () {
    for (final pair in [
      (AppColors.white, AppColors.action),
      (AppColors.ink, AppColors.canvas),
      (AppColors.secondaryText, AppColors.surface),
      (AppColors.white, AppColors.dark),
    ]) {
      final a = pair.$1.computeLuminance();
      final b = pair.$2.computeLuminance();
      final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      expect(contrast, greaterThanOrEqualTo(4.5));
    }
  });
}
