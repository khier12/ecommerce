import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/main.dart';

void main() {
  late ShopController shop;
  setUp(() => shop = ShopController(repository: const MenuRepository()));
  tearDown(() => shop.dispose());

  Future<void> openBag(WidgetTester tester, {bool fromDetails = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    shop.addToCart(shop.products.first, quantity: 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: MenuScreen(controller: shop),
      ),
    );
    await tester.pumpAndSettle();
    if (fromDetails) {
      final product = find.byKey(Key('product-${shop.products.first.id}'));
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
      expect(find.byType(ProductDetailsScreen), findsOneWidget);
    }
    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Place Order opens one confirmation, clears the bag and returns to menu',
    (tester) async {
      await openBag(tester);
      expect(find.text('Review order'), findsNothing);
      await tester.tap(find.byKey(const Key('open-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('place-order'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('place-order')));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter a valid PH mobile number'), findsOneWidget);
      expect(find.text('Enter your delivery address'), findsOneWidget);
      expect(shop.cartCount, 2);
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
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('place-order'))),
      );
      await tester.pumpAndSettle();
      final place = tester
          .widget<FilledButton>(find.byKey(const Key('place-order')))
          .onPressed!;
      place();
      place();
      await tester.pumpAndSettle();
      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(find.byType(CartScreen, skipOffstage: false), findsNothing);
      expect(find.text('Order placed.'), findsOneWidget);
      expect(find.text('Delivery for Juan Dela Cruz'), findsOneWidget);
      expect(find.text('12 Rizal Street, Carmona, Cavite'), findsOneWidget);
      expect(
        find.text('Cash on delivery · Payment due on delivery'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('order-reference')))
            .data,
        'SMC-0001',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('confirmation-total'))).data,
        '₱319.00',
      );
      expect(shop.cartItems, isEmpty);
      expect(shop.total, 0);
      await tester.tap(find.byKey(const Key('continue-shopping')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byType(OrderConfirmationScreen), findsNothing);
      expect(find.byType(CartScreen, skipOffstage: false), findsNothing);
      expect(find.byKey(const Key('view-bag-summary')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'System Back after ordering from product details returns directly to menu',
    (tester) async {
      await openBag(tester, fromDetails: true);
      await tester.tap(find.byKey(const Key('open-checkout')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer-name')),
        'Ana Cruz',
      );
      await tester.enterText(
        find.byKey(const Key('customer-mobile')),
        '+639171234567',
      );
      await tester.enterText(
        find.byKey(const Key('delivery-address')),
        '12 Rizal Street, Carmona, Cavite',
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('place-order'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('place-order')));
      await tester.pumpAndSettle();
      expect(
        find.byType(ProductDetailsScreen, skipOffstage: false),
        findsNothing,
      );
      Navigator.of(tester.element(find.byType(OrderConfirmationScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byType(ProductDetailsScreen), findsNothing);
      expect(find.byType(CartScreen), findsNothing);
      expect(shop.cartCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Long confirmation fits a narrow phone with large text and a reachable total',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final product in shop.products) {
        shop.addToCart(product, quantity: 2);
      }
      final order = (await shop.submitOrder(
        customerName: 'Guest',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      ))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: OrderConfirmationScreen(order: order),
        ),
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('confirmation-total'))),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('confirmation-total'))).data,
        pesos(order.total),
      );
      expect(
        find.byKey(const Key('confirmation-total')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('continue-shopping')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
