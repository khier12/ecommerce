import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce/main.dart';

void main() {
  testWidgets(
    '3D idle motion continues, pauses offscreen and resumes on return',
    (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      CoffeeScenePainter scene() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const Key('coffee-scene'), skipOffstage: false),
                  )
                  .painter!
              as CoffeeScenePainter;

      await tester.pumpWidget(const MiniShopApp());
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));
      final initial = scene().idlePhase;
      await tester.pump(const Duration(milliseconds: 700));
      expect(scene().progress, 1);
      expect(scene().idlePhase, isNot(initial));
      expect(find.byType(MenuScreen), findsNothing);
      // Cross more than one idle-loop boundary; the intro stays completed.
      final firstLoop = scene().idlePhase;
      await tester.pump(const Duration(milliseconds: 12300));
      expect(scene().idlePhase, isNot(firstLoop));
      expect(scene().progress, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = scene().idlePhase;
      await tester.pump(const Duration(seconds: 2));
      expect(scene().idlePhase, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scene().idlePhase, isNot(paused));

      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      final hidden = scene().idlePhase;
      await tester.pump(const Duration(seconds: 2));
      expect(scene().idlePhase, hidden);

      await tester.tap(find.byTooltip('Back to start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final returned = scene().idlePhase;
      await tester.pump(const Duration(milliseconds: 600));
      expect(scene().idlePhase, isNot(returned));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ORDER NOW, search, details, quantity changes, and empty cart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MiniShopApp());
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byKey(const Key('coffee-scene')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pumpAndSettle();
    expect(find.byType(StartScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(MenuScreen))).canPop(),
      isTrue,
    );

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'tiramisu latte');
    await tester.pumpAndSettle();
    final product = find.byKey(const Key('product-coffee-tiramisu-latte'));
    await Scrollable.ensureVisible(tester.element(product), alignment: .5);
    await tester.pumpAndSettle();
    expect(product.hitTestable(), findsOneWidget);
    await tester.tap(product);
    await tester.pumpAndSettle();
    expect(find.text('Tiramisu Latte'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Increase quantity'));
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('Add to bag • ₱290.00'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('details-add-to-cart')));
    await tester.tap(find.byKey(const Key('details-add-to-cart')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cart-total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-total'))).data,
      '₱319.00',
    );
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-total'))).data,
      '₱464.00',
    );
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-total'))).data,
      '₱319.00',
    );
    await tester.tap(find.byTooltip('Remove Tiramisu Latte'));
    await tester.pumpAndSettle();
    expect(find.text('A little empty, for now.'), findsOneWidget);
    expect(find.byKey(const Key('cart-total')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Order history and cafe tabs work on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ShopController(repository: const MenuRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: MenuScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet.'), findsOneWidget);
    await tester.tap(find.text('Browse the menu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-category-pages')), findsOneWidget);
    controller.addToCart(controller.products.first);
    await controller.submitOrder(
      customerName: 'Juan Dela Cruz',
      mobileNumber: '09171234567',
      notes: '',
      paymentMethod: PaymentMethod.cash,
      deliveryAddress: '12 Rizal Street, Carmona, Cavite',
    );
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-SMC-0001')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-SMC-0001')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery for Juan Dela Cruz'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-shopping')));
    await tester.pumpAndSettle();
    expect(find.text('Your orders'), findsOneWidget);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Discover Smooch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 700),
    const Size(768, 1024),
    const Size(900, 900),
    const Size(1440, 900),
  ]) {
    testWidgets('3D start screen and menu fit ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MiniShopApp());
      await tester.pump(const Duration(milliseconds: 1800));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -550));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Start screen waits for ORDER NOW and pushes a MaterialPageRoute',
    (tester) async {
      await tester.pumpWidget(const MiniShopApp());
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pumpAndSettle();
      final menuContext = tester.element(find.byType(MenuScreen));
      expect(ModalRoute.of(menuContext), isA<MaterialPageRoute<void>>());
      expect(ModalRoute.of(menuContext)!.settings.name, MenuScreen.routeName);
      expect(Navigator.of(menuContext).canPop(), isTrue);
      await tester.tap(find.byTooltip('Back to start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('enter-store')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Repeated ORDER NOW taps open one menu and Back preserves the bag',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MiniShopApp());
      final enter = tester
          .widget<FilledButton>(find.byKey(const Key('enter-store')))
          .onPressed!;
      enter();
      enter();
      await tester.pumpAndSettle();
      final shop = tester
          .widget<MenuScreen>(find.byType(MenuScreen))
          .controller;
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
      expect(shop.total, 145);
      await tester.tap(find.byTooltip('Back to start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MenuScreen>(find.byType(MenuScreen)).controller,
        same(shop),
      );
      expect(shop.cartCount, 1);
      expect(shop.total, 145);
      expect(find.byKey(const Key('view-bag-summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduced motion keeps a still start screen and enters only on tap',
    (tester) async {
      final controller = ShopController(repository: const MenuRepository());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: StartScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byTooltip('View cart').hitTestable(), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Disposing an active start screen cancels its animation', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniShopApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'Material menu transition covers the start screen before enabling controls',
    (tester) async {
      await tester.pumpWidget(const MiniShopApp());
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('enter-store')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('splash-fade-cover')))
            .opacity,
        allOf(greaterThan(0), lessThan(1)),
      );
      expect(
        tester.widget<Opacity>(find.byKey(const Key('menu-reveal'))).opacity,
        0,
      );
      expect(find.byTooltip('View cart').hitTestable(), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('splash-fade-cover')))
            .opacity,
        1,
      );
      expect(
        tester.widget<Opacity>(find.byKey(const Key('menu-reveal'))).opacity,
        allOf(greaterThan(0), lessThan(1)),
      );
      expect(find.byTooltip('View cart').hitTestable(), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(StartScreen), findsNothing);
      expect(find.byTooltip('View cart').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Start screen supports larger text with a reachable ORDER NOW button',
    (tester) async {
      final controller = ShopController(repository: const MenuRepository());
      addTearDown(controller.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: StartScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(find.byKey(const Key('enter-store')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('enter-store')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
