import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce/main.dart';

void main() {
  testWidgets(
    'Failed and cancelled digital payment preserve the bag; success saves an order',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.addToCart(shop.products.first, quantity: 2);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: MenuScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('View cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-checkout')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer-name')),
        'Juan Dela Cruz',
      );
      await tester.enterText(
        find.byKey(const Key('customer-mobile')),
        '09171234567',
      );
      await tester.enterText(
        find.byKey(const Key('delivery-address')),
        '12 Rizal Street, Carmona, Cavite',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('payment-digital'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment-digital')));
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('place-order'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('place-order')));
      await tester.pumpAndSettle();
      expect(find.byType(DemoPaymentScreen), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'\b(demo|simulat\w*)\b', caseSensitive: false),
        ),
        findsNothing,
      );
      expect(find.text('GCash wallet'), findsOneWidget);
      expect(find.text('Checkout mobile ending 4567'), findsOneWidget);
      expect(find.byKey(const Key('payment-amount')), findsOneWidget);
      expect(find.textContaining('Payment preview only.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const Key('simulate-payment-failure')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payment-failure')), findsOneWidget);
      expect(shop.cartCount, 2);
      expect(shop.orders, isEmpty);
      await tester.tap(find.byKey(const Key('cancel-payment')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(shop.cartCount, 2);
      await tester.tap(find.byKey(const Key('place-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-with-gcash')));
      await tester.pump();
      expect(find.byKey(const Key('payment-processing')), findsOneWidget);
      expect(shop.orders, isEmpty);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payment-success')), findsOneWidget);
      expect(shop.orders, isEmpty);
      await tester.tap(find.byKey(const Key('continue-after-payment')));
      await tester.pumpAndSettle();
      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(find.text('GCash · Payment step complete'), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'\b(demo|simulat\w*)\b', caseSensitive: false),
        ),
        findsNothing,
      );
      expect(shop.cartCount, 0);
      expect(shop.orders, hasLength(1));
      await tester.tap(find.byKey(const Key('continue-shopping')));
      await tester.pumpAndSettle();
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
    },
  );

  testWidgets('Featured carousel and category pages both swipe smoothly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: MenuScreen(controller: shop),
      ),
    );
    await tester.pumpAndSettle();
    final carousel = find.byKey(const Key('featured-carousel'));
    expect(carousel, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(carousel));
    await tester.drag(carousel, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(carousel).controller!.page, closeTo(1, .01));
    final tabs = tester
        .widget<TabBar>(find.byKey(const Key('category-filters')))
        .controller!;
    await tester.tap(find.byKey(const Key('category-Coffee')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tabs.animation!.value, greaterThan(0));
    expect(tabs.animation!.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(shop.category, 'Coffee');
    expect(tabs.index, 1);
    expect(shop.filteredProducts, hasLength(8));
    expect(carousel, findsNothing);
    await tester.drag(
      find.byKey(const Key('menu-category-pages')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(shop.category, 'Non-Coffee');
    expect(tabs.index, 2);
    expect(shop.filteredProducts, hasLength(6));
    await tester.drag(
      find.byKey(const Key('menu-category-pages')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    expect(shop.category, 'Coffee');
    expect(tabs.index, 1);
    for (var index = 1; index < ShopController.categories.length - 1; index++) {
      await tester.drag(
        find.byKey(const Key('menu-category-pages')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
    }
    expect(shop.category, 'More Drinks');
    expect(
      find.byKey(const Key('category-More Drinks')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion changes categories without a running transition',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
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
      await tester.tap(find.byKey(const Key('category-Coffee')));
      await tester.pump();
      expect(shop.category, 'Coffee');
      expect(
        tester
            .widget<TabBar>(find.byKey(const Key('category-filters')))
            .controller!
            .index,
        1,
      );
      final tabs = tester
          .widget<TabBar>(find.byKey(const Key('category-filters')))
          .controller!;
      expect(tabs.animation!.value, 1);
      expect(tabs.indexIsChanging, isFalse);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
