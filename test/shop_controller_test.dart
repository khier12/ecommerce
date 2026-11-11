import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce/main.dart';

import 'fixtures/legacy_product.dart';

void main() {
  late ShopController shop;
  setUp(() => shop = ShopController(repository: const MenuRepository()));
  tearDown(() => shop.dispose());

  test(
    'Catalog uses unique product IDs, positive prices, and existing photos',
    () {
      expect(shop.products, hasLength(40));
      expect(shop.products.map((product) => product.id).toSet(), hasLength(40));
      expect(
        shop.products.map((product) => product.id),
        unorderedEquals(cafeMenuProductIds),
        reason: 'Every selected product ID must resolve to a catalog entry.',
      );
      for (final product in shop.products) {
        expect(product.price, greaterThan(0), reason: product.name);
        expect(File(product.image).existsSync(), isTrue, reason: product.image);
        expect(ShopController.categories, contains(product.category));
        expect(product.subcategory, isNotEmpty);
      }
    },
  );

  test(
    'Search ignores case and surrounding spaces and combines with category',
    () {
      shop.search('  LATTE  ');
      expect(shop.filteredProducts, isNotEmpty);
      shop.selectCategory('Coffee');
      expect(
        shop.filteredProducts.every((product) => product.category == 'Coffee'),
        isTrue,
      );
      shop.selectCategory('Food');
      expect(shop.filteredProducts, isEmpty);
      shop.search('burger');
      expect(shop.filteredProducts.map((product) => product.name), [
        'Classic Burger',
      ]);
    },
  );

  test(
    'The smaller menu retains featured picks and omits unselected variants',
    () {
      expect(
        shop.products
            .where((product) => product.featured)
            .map((product) => product.id),
        unorderedEquals(
          cafeProducts
              .where((product) => product.featured)
              .map((product) => product.id),
        ),
      );
      for (final query in [
        'Double Classic Burger',
        'Healthtea',
        'White Mocha',
      ]) {
        shop.search(query);
        expect(shop.filteredProducts, isEmpty, reason: query);
      }
      shop.search('');
      shop.selectCategory('Food');
      expect(
        shop.filteredProducts.map((product) => product.subcategory).toSet(),
        unorderedEquals([
          'Quarter Pounder',
          'Sandwiches',
          'Quesadilla',
          'French Fries',
          'Rice Bowls',
          'Pasta',
          'Nachos',
        ]),
        reason: 'The shorter food menu must still offer varied meal types.',
      );
    },
  );

  test(
    'Receipts for products removed from browsing restore unchanged',
    () async {
      const retired = legacyBurger;
      expect(
        shop.products.map((product) => product.id),
        isNot(contains(retired.id)),
      );
      final store = MemoryOrderStore();
      final previous = ShopController(
        repository: const MenuRepository(),
        orderStore: store,
      );
      // A saved bag/receipt holds a product snapshot rather than a menu index.
      previous.addToCart(retired, quantity: 2);
      final saved = await previous.submitOrder(
        customerName: 'Ana Cruz',
        mobileNumber: '09171234567',
        notes: 'Less sauce',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      );
      expect(saved, isNotNull);
      previous.dispose();

      final current = ShopController(
        repository: const MenuRepository(),
        orderStore: store,
      );
      addTearDown(current.dispose);
      await current.restoreOrders();
      expect(current.historyError, isNull);
      final receipt = current.orders.single;
      expect(receipt.reference, saved!.reference);
      expect(receipt.items.single.product.toJson(), retired.toJson());
      expect(receipt.items.single.quantity, 2);
      expect(receipt.total, 360);
      expect(receipt.notes, 'Less sauce');
      expect(File(receipt.items.single.product.image).existsSync(), isFalse);
      expect(current.products, hasLength(40));
      current.addToCart(current.products.first);
      final next = await current.submitOrder(
        customerName: 'Ana Cruz',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      );
      expect(next!.reference, 'SMC-0002');
      expect(current.orders.last.items.single.product.id, retired.id);
    },
  );

  test(
    'Cart merges identical products and keeps same-name variants distinct',
    () {
      final variants = shop.products
          .where((p) => p.name == 'Caramel Macchiato')
          .toList();
      expect(variants, hasLength(2));
      shop.addToCart(variants[0], quantity: 2);
      shop.addToCart(variants[0]);
      shop.addToCart(variants[1]);
      expect(shop.cartItems, hasLength(2));
      expect(shop.cartCount, 4);
      expect(shop.total, variants[0].price * 3 + variants[1].price);
      shop.decrease(variants[1]);
      expect(shop.cartItems, hasLength(1));
      shop.remove(variants[0]);
      expect(shop.cartCount, 0);
      expect(shop.total, 0);
      shop.addToCart(variants[0], quantity: 0);
      expect(shop.cartItems, isEmpty);
    },
  );

  test(
    'Placing demo orders snapshots items and totals with sequential references',
    () async {
      Future<OrderReceipt?> place() => shop.submitOrder(
        customerName: 'Guest',
        mobileNumber: '09171234567',
        notes: '',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      );
      expect(await place(), isNull);
      final first = shop.products.first;
      final second = shop.products[1];
      shop.addToCart(first, quantity: 2);
      shop.addToCart(second);
      final order = (await place())!;
      expect(order.reference, 'SMC-0001');
      expect(order.itemCount, 3);
      expect(order.total, first.price * 2 + second.price);
      expect(shop.cartCount, 0);
      expect(shop.total, 0);
      expect(await place(), isNull);
      shop.addToCart(first, quantity: 4);
      expect(order.items.first.quantity, 2);
      expect(order.total, first.price * 2 + second.price);
      expect(() => order.items.clear(), throwsUnsupportedError);
      final next = (await place())!;
      expect(next.reference, 'SMC-0002');
      expect(next.itemCount, 4);
      expect(next.total, first.price * 4);
    },
  );

  test('Every category filters the expected products and preserves subcategory search', () {
    const expectedCounts = {
      'Coffee': 8,
      'Non-Coffee': 6,
      'Food': 8,
      'Pastries': 6,
      'Ice Blended': 6,
      'More Drinks': 6,
    };
    for (final entry in expectedCounts.entries) {
      shop.selectCategory(entry.key);
      expect(shop.filteredProducts, hasLength(entry.value));
      expect(
        shop.filteredProducts.every((p) => p.category == entry.key),
        isTrue,
      );
    }
    shop.selectCategory('Pastries');
    shop.search('brownies');
    expect(shop.filteredProducts, isNotEmpty);
    expect(
      shop.filteredProducts.every((p) => p.subcategory == 'Brownies'),
      isTrue,
    );
    shop.selectCategory('Food');
    shop.search('quarter pounder');
    expect(shop.filteredProducts, hasLength(1));
    expect(
      shop.filteredProducts.every((p) => p.subcategory == 'Quarter Pounder'),
      isTrue,
    );
  });

  test('Search matches words in any order with repeated whitespace', () {
    shop.search('  LATTE   tiramisu  ');
    expect(shop.filteredProducts.map((p) => p.name), ['Tiramisu Latte']);
    shop.selectCategory('Food');
    expect(shop.filteredProducts, isEmpty);
    shop.search('   ');
    expect(shop.filteredProducts.every((p) => p.category == 'Food'), isTrue);
    expect(shop.filteredProducts, hasLength(8));
  });

  test(
    'Saved receipts restore with the same items and unique references',
    () async {
      final store = MemoryOrderStore();
      final first = ShopController(
        repository: const MenuRepository(),
        orderStore: store,
      );
      first.addToCart(first.products.first, quantity: 2);
      final receipt = await first.submitOrder(
        customerName: '  Juan Dela Cruz  ',
        mobileNumber: '09171234567',
        notes: 'Less ice',
        paymentMethod: PaymentMethod.cash,
        deliveryAddress: '12 Rizal Street, Carmona, Cavite',
      );
      expect(receipt?.reference, 'SMC-0001');
      expect(first.cartCount, 0);
      expect(first.orders, hasLength(1));
      first.dispose();

      final restored = ShopController(
        repository: const MenuRepository(),
        orderStore: store,
      );
      await restored.restoreOrders();
      expect(restored.orders.single.customerName, 'Juan Dela Cruz');
      expect(restored.orders.single.mobileNumber, '09171234567');
      expect(restored.orders.single.notes, 'Less ice');
      expect(restored.orders.single.items.single.quantity, 2);
      expect(restored.orders.single.total, 290);
      restored.addToCart(restored.products.first);
      final next = await restored.submitOrder(
        customerName: 'Ana',
        mobileNumber: '09180000000',
        notes: '',
        paymentMethod: PaymentMethod.digital,
        deliveryAddress: '14 Rizal Street, Carmona, Cavite',
      );
      expect(next?.reference, 'SMC-0002');
      expect(next?.paymentStatus, 'Payment step complete');
      expect(restored.orders.map((order) => order.reference), [
        'SMC-0002',
        'SMC-0001',
      ]);
      restored.dispose();
    },
  );

  test(
    'Storage failure keeps the bag and does not consume a reference',
    () async {
      final failing = ShopController(
        repository: const MenuRepository(),
        orderStore: _FailingOrderStore(),
      );
      failing.addToCart(failing.products.first);
      await expectLater(
        failing.submitOrder(
          customerName: 'Ana',
          mobileNumber: '09180000000',
          notes: '',
          paymentMethod: PaymentMethod.cash,
          deliveryAddress: '12 Rizal Street, Carmona, Cavite',
        ),
        throwsStateError,
      );
      expect(failing.cartCount, 1);
      expect(failing.orders, isEmpty);
      expect(failing.placingOrder, isFalse);
      failing.dispose();
    },
  );

  test(
    'Sorting applies to filtered results without changing catalog order',
    () {
      final originalIds = shop.products.map((p) => p.id).toList();
      shop.selectCategory('Coffee');
      shop.search('latte');
      shop.sortBy(MenuSort.priceLow);
      final ascending = shop.filteredProducts.map((p) => p.price).toList();
      expect(ascending, orderedEquals([...ascending]..sort()));
      shop.sortBy(MenuSort.priceHigh);
      expect(
        shop.filteredProducts.map((p) => p.price),
        orderedEquals(ascending.reversed),
      );
      shop.sortBy(MenuSort.name);
      final names = shop.filteredProducts
          .map((p) => p.name.toLowerCase())
          .toList();
      expect(names, orderedEquals([...names]..sort()));
      expect(shop.products.map((p) => p.id), orderedEquals(originalIds));
      shop.sortBy(MenuSort.recommended);
      expect(shop.filteredProducts.first.name, 'Tiramisu Latte');
    },
  );
}

class _FailingOrderStore implements OrderStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async =>
      throw StateError('Storage unavailable');
}
