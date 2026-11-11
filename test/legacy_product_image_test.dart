import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/legacy_product.dart';

class _ImageRequestGuard extends CachingAssetBundle {
  final imageRequests = <String>[];

  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/images/')) {
      imageRequests.add(key);
      throw StateError('Unexpected request for retired photo: $key');
    }
    return rootBundle.load(key);
  }
}

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

  testWidgets(
    'A retired photo uses an accessible cafe icon without loading a missing asset',
    (tester) async {
      final guard = _ImageRequestGuard();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: guard,
            child: const SizedBox(
              width: 60,
              height: 60,
              child: ProductImage(product: legacyBurger),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(guard.imageRequests, isEmpty);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
      expect(find.bySemanticsLabel(legacyBurger.name), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'An older filename for an active product resolves to its current photo',
    (tester) async {
      final product = cafeProducts.first;
      final saved = Product.fromJson({
        ...product.toJson(),
        'image': 'assets/images/Tiramisu Latte 5.png',
      });
      await tester.pumpWidget(MaterialApp(home: ProductImage(product: saved)));
      await tester.pumpAndSettle();
      final provider =
          tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect((provider.imageProvider as AssetImage).assetName, product.image);
      expect(provider.width, ProductImage.thumbnailCacheWidth);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Historical receipt details remain readable after its product photo is deleted',
    (tester) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.addToCart(legacyBurger, quantity: 2);
      final receipt = (await shop.submitOrder(
        customerName: 'Ana Cruz',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      ))!;
      final guard = _ImageRequestGuard();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          builder: (context, child) => DefaultAssetBundle(
            bundle: guard,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
          home: OrderConfirmationScreen(order: receipt, fromHistory: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(legacyBurger.name));
      await tester.pumpAndSettle();
      expect(find.text(legacyBurger.name), findsOneWidget);
      expect(find.text('₱360.00'), findsWidgets);
      expect(find.text('2 × ₱180.00'), findsOneWidget);
      expect(guard.imageRequests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
