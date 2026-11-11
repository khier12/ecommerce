import 'dart:math' as math;

import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart' show FlutterMap, TapPosition;
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  LatLng northOfCafe(double km) => LatLng(
    CheckoutValidation.deliveryCenter.latitude + km / 6371 * 180 / math.pi,
    CheckoutValidation.deliveryCenter.longitude,
  );

  test(
    'The 30 km delivery boundary is inclusive and rejects locations beyond it',
    () {
      expect(CheckoutValidation.deliveryRadiusLabel, '30 km');
      for (final distance in [0.0, 10.0, 20.0, 29.999, 30.0]) {
        expect(
          CheckoutValidation.isWithinDeliveryArea(northOfCafe(distance)),
          isTrue,
          reason: '$distance km',
        );
      }
      for (final distance in [30.001, 31.0, 50.0]) {
        expect(
          CheckoutValidation.isWithinDeliveryArea(northOfCafe(distance)),
          isFalse,
          reason: '$distance km',
        );
      }
    },
  );

  test(
    'Ordering accepts a 25 km pin and preserves the bag for a pin beyond 30 km',
    () async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.addToCart(shop.products.first);
      Future<OrderReceipt?> place(LatLng pin) => shop.submitOrder(
        customerName: 'Ana Cruz',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Example Street, delivery address',
        deliveryLatitude: pin.latitude,
        deliveryLongitude: pin.longitude,
      );
      expect(await place(northOfCafe(31)), isNull);
      expect(shop.cartCount, 1);
      expect(shop.orders, isEmpty);
      final point = northOfCafe(25);
      final saved = await place(point);
      expect(saved, isNotNull);
      expect(saved!.deliveryPoint, point);
      expect(saved.reference, 'SMC-0001');
      expect(shop.cartCount, 0);
    },
  );

  testWidgets('Map pin controls and labels use the 30 km delivery area', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DeliveryMapPicker()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Delivery available within 30 km of Carmona. Tap to place your pin.',
      ),
      findsOneWidget,
    );
    final map = tester.widget<FlutterMap>(
      find.byKey(const Key('delivery-map')),
    );
    final confirm = find.byKey(const Key('confirm-delivery-pin'));
    for (final distance in [25.0, 30.0]) {
      map.options.onTap!(
        const TapPosition(Offset.zero, null),
        northOfCafe(distance),
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    }
    map.options.onTap!(const TapPosition(Offset.zero, null), northOfCafe(31));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(
      find.text(
        'This location is outside our 30 km delivery area around Carmona.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('Delivery area accepts Carmona and rejects distant locations', () {
    expect(
      CheckoutValidation.isWithinDeliveryArea(const LatLng(14.3158, 121.0561)),
      isTrue,
    );
    expect(
      CheckoutValidation.isWithinDeliveryArea(const LatLng(14.7, 121.0)),
      isFalse,
    );
    expect(CheckoutValidation.isWithinDeliveryArea(null), isFalse);
  });

  OrderReceipt receipt(
    DateTime createdAt, {
    FulfillmentMethod fulfillment = FulfillmentMethod.delivery,
  }) => OrderReceipt(
    reference: 'SMC-0001',
    items: const [],
    customerName: 'Juan Dela Cruz',
    mobileNumber: '09171234567',
    notes: '',
    paymentMethod: PaymentMethod.cash,
    createdAt: createdAt,
    fulfillment: fulfillment,
    deliveryAddress: fulfillment == FulfillmentMethod.delivery
        ? '12 Rizal Street, Carmona, Cavite'
        : '',
  );

  test('Delivery finishes exactly one second after the rider arrives', () {
    final placedAt = DateTime.utc(2026, 1, 1, 12);
    final order = receipt(placedAt);
    expect(order.stageAt(placedAt), OrderStage.confirmed);
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 9))),
      OrderStage.confirmed,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 10))),
      OrderStage.preparing,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 19))),
      OrderStage.preparing,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 20))),
      OrderStage.riderAssigned,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 30))),
      OrderStage.onTheWay,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 38))),
      OrderStage.onTheWay,
    );
    expect(order.riderProgressAt(placedAt.add(const Duration(seconds: 30))), 0);
    expect(
      order.riderProgressAt(placedAt.add(const Duration(seconds: 34))),
      .5,
    );
    expect(order.riderProgressAt(placedAt.add(const Duration(seconds: 38))), 1);
    expect(
      order.stageAt(placedAt.add(const Duration(milliseconds: 38999))),
      OrderStage.onTheWay,
    );
    expect(
      order.stageAt(placedAt.add(const Duration(seconds: 39))),
      OrderStage.delivered,
    );
    final restored = OrderReceipt.fromJson(order.toJson());
    expect(restored.fulfillment, FulfillmentMethod.delivery);
    expect(restored.deliveryAddress, '12 Rizal Street, Carmona, Cavite');
    expect(
      restored.stageAt(placedAt.add(const Duration(minutes: 2))),
      OrderStage.delivered,
    );
  });

  test('Older pickup receipts keep a matching three-stage timeline', () {
    final placedAt = DateTime.utc(2026, 1, 1, 12);
    final legacy =
        receipt(placedAt, fulfillment: FulfillmentMethod.pickup).toJson()
          ..remove('fulfillment')
          ..remove('deliveryAddress');
    final restored = OrderReceipt.fromJson(legacy);
    expect(restored.fulfillment, FulfillmentMethod.pickup);
    expect(restored.stages, [
      OrderStage.confirmed,
      OrderStage.preparing,
      OrderStage.readyForPickup,
    ]);
    expect(
      restored.stageAt(placedAt.add(const Duration(seconds: 20))),
      OrderStage.readyForPickup,
    );
  });

  test('A delivery order cannot be saved without a delivery address', () async {
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    shop.addToCart(shop.products.first);
    final missingAddress = await shop.submitOrder(
      customerName: 'Ana Cruz',
      mobileNumber: '09171234567',
      notes: '',
      paymentMethod: PaymentMethod.cash,
      deliveryAddress: '',
    );
    expect(missingAddress, isNull);
    expect(shop.cartCount, 1);
    expect(shop.orders, isEmpty);
    final saved = await shop.submitOrder(
      customerName: 'Ana Cruz',
      mobileNumber: '09171234567',
      notes: '',
      paymentMethod: PaymentMethod.cash,
      deliveryAddress: '  12 Rizal Street, Carmona  ',
      deliveryLatitude: 14.3158,
      deliveryLongitude: 121.0561,
    );
    expect(saved?.deliveryAddress, '12 Rizal Street, Carmona');
    expect(saved?.reference, 'SMC-0001');
    final restored = OrderReceipt.fromJson(saved!.toJson());
    expect(restored.deliveryLatitude, 14.3158);
    expect(restored.deliveryLongitude, 121.0561);
  });

  testWidgets('Receipt timeline includes the one-second arrival hold', (
    tester,
  ) async {
    final order = receipt(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: OrderConfirmationScreen(order: order),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-stage-confirmed')), findsOneWidget);
    expect(
      find.text('Follow your order from our kitchen to your door.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('order-stage-preparing')), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('order-stage-riderAssigned')), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('order-stage-onTheWay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('order-stage-delivered')), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const Key('order-stage-delivered')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order History updates its status while open', (tester) async {
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    shop.addToCart(shop.products.first);
    await shop.submitOrder(
      customerName: 'Juan Dela Cruz',
      mobileNumber: '09171234567',
      notes: '',
      paymentMethod: PaymentMethod.cash,
      deliveryAddress: '12 Rizal Street, Carmona, Cavite',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: OrderHistoryScreen(controller: shop),
      ),
    );
    await tester.pumpAndSettle();
    final status = find.byKey(const Key('order-stage-SMC-0001'));
    expect(tester.widget<Text>(status).data, 'Confirmed');
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<Text>(status).data, 'Preparing');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Checkout is delivery-only and requires an address', (
    tester,
  ) async {
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    shop.addToCart(shop.products.first);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: CheckoutScreen(controller: shop),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fulfillment-pickup')), findsNothing);
    expect(find.byKey(const Key('fulfillment-delivery')), findsNothing);
    await tester.enterText(find.byKey(const Key('customer-name')), 'Ana Cruz');
    await tester.enterText(
      find.byKey(const Key('customer-mobile')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your delivery address'), findsOneWidget);
    expect(shop.orders, isEmpty);
    await tester.enterText(
      find.byKey(const Key('delivery-address')),
      '12 Rizal Street, Carmona, Cavite',
    );
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pumpAndSettle();
    expect(shop.orders.single.fulfillment, FulfillmentMethod.delivery);
    expect(find.text('Rider assigned'), findsOneWidget);
    expect(find.text('Ready for pickup'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS fills the editable address and saves the map pin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    shop.addToCart(shop.products.first);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: CheckoutScreen(
          controller: shop,
          locationService: const _FakeLocationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gps = find.byKey(const Key('use-gps-address'));
    await tester.ensureVisible(gps);
    await tester.pumpAndSettle();
    await tester.tap(gps);
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryMapPicker), findsOneWidget);
    expect(find.textContaining('14.31580'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delivery-pin')));
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryMapPicker), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('delivery-address')))
          .controller!
          .text,
      '12 Rizal Street, Carmona, Cavite',
    );
    expect(find.byKey(const Key('checkout-delivery-pin')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('customer-name')), 'Ana Cruz');
    await tester.enterText(
      find.byKey(const Key('customer-mobile')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pumpAndSettle();
    expect(shop.orders.single.deliveryLatitude, 14.3158);
    expect(shop.orders.single.deliveryLongitude, 121.0561);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Map address suggestion preserves manual text and can be applied',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.addToCart(shop.products.first);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: CheckoutScreen(
            controller: shop,
            locationService: const _FakeLocationService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const manualAddress = 'Unit 2, Example Street, Carmona';
      await tester.enterText(
        find.byKey(const Key('delivery-address')),
        manualAddress,
      );
      final gpsButton = find.byKey(const Key('use-gps-address'));
      await tester.ensureVisible(gpsButton);
      await tester.pumpAndSettle();
      await tester.tap(gpsButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delivery-pin')));
      await tester.pumpAndSettle();
      final addressField = tester.widget<TextFormField>(
        find.byKey(const Key('delivery-address')),
      );
      expect(addressField.controller!.text, manualAddress);
      final useSuggestion = find.byKey(const Key('use-suggested-address'));
      expect(useSuggestion, findsOneWidget);
      await tester.ensureVisible(useSuggestion);
      await tester.pumpAndSettle();
      await tester.tap(useSuggestion);
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('delivery-address')))
            .controller!
            .text,
        '12 Rizal Street, Carmona, Cavite',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Map tap places a delivery pin without GPS', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DeliveryMapPicker()));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('confirm-delivery-pin'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    final map = tester.widget<FlutterMap>(
      find.byKey(const Key('delivery-map')),
    );
    map.options.onTap!(
      const TapPosition(Offset.zero, null),
      const LatLng(14.3158, 121.0561),
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(find.textContaining('Pin:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeLocationService extends DeliveryLocationService {
  const _FakeLocationService();

  @override
  Future<LatLng> currentLocation() async => const LatLng(14.3158, 121.0561);

  @override
  Future<String?> addressFor(LatLng point) async =>
      '12 Rizal Street, Carmona, Cavite';
}
