import 'dart:convert';

import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AI Feature #3: Smart Natural-Language Search', () {
    test('parses budget, category, and flavor intents cleanly', () {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);

      shop.search('sweet iced coffee under 150');
      expect(shop.smartSearchSummary, isNotNull);
      expect(shop.filteredProducts, isNotEmpty);
      expect(
        shop.filteredProducts.every(
          (p) => p.category == 'Coffee' && p.price <= 150,
        ),
        isTrue,
      );

      shop.search('non-coffee drinks below 120');
      expect(shop.smartSearchSummary, contains('Non-Coffee'));
      expect(shop.filteredProducts, isNotEmpty);
      expect(
        shop.filteredProducts.every(
          (p) => p.category != 'Coffee' && p.price <= 120,
        ),
        isTrue,
      );

      shop.search('chocolate pastry under 100');
      expect(shop.filteredProducts, isNotEmpty);
      expect(
        shop.filteredProducts.every(
          (p) => p.category == 'Pastries' && p.price <= 100,
        ),
        isTrue,
      );

      // Plain non-intent queries preserve exact match behavior.
      shop.search('Double Classic Burger');
      expect(shop.smartSearchSummary, isNull);
      expect(shop.filteredProducts, isEmpty);
    });

    testWidgets('shows AI Smart Search badge on MenuScreen', (tester) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: MenuScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('menu-search')),
        'coffee under 120',
      );
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('smart-search-badge')), findsOneWidget);
      expect(shop.filteredProducts, isNotEmpty);
      expect(
        shop.filteredProducts.every(
          (p) => p.category == 'Coffee' && p.price <= 120,
        ),
        isTrue,
      );
    });
  });

  group('AI Feature #2: Craving / Mood Picker', () {
    test('builds valid available combos for every mood', () {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);

      for (final mood in SmoochCravingMood.values) {
        final combo = shop.moodCombo(mood);
        expect(combo.products, isNotEmpty, reason: mood.label);
        expect(
          combo.products.every((p) => p.available),
          isTrue,
          reason: mood.label,
        );
        if (mood == SmoochCravingMood.budget) {
          expect(combo.totalPrice, lessThanOrEqualTo(150));
        }
      }
    });

    testWidgets('selecting mood reveals combo and adds combo to bag', (
      tester,
    ) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: MenuScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-craving-picker')), findsOneWidget);
      await tester.drag(
        find.byKey(const PageStorageKey('products-All')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai-craving-picker')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-craving-sheet')), findsOneWidget);
      expect(find.byKey(const Key('ai-combo-card')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mood-chip-sweet')));
      await tester.pumpAndSettle();
      final expectedCount = shop.moodCombo(SmoochCravingMood.sweetTooth).products.length;

      await tester.tap(find.byKey(const Key('ai-add-combo')));
      await tester.pumpAndSettle();

      expect(shop.cartCount, expectedCount);
    });
  });

  group('AI Feature #1: Ask Smooch Barista Assistant', () {
    test('answers store FAQs, pairings, and menu requests locally', () async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);

      final hoursReply = await shop.barista.aiService.askBarista(
        prompt: 'What are your opening hours?',
        shop: shop,
      );
      expect(hoursReply.text, contains('2:00 PM'));
      expect(hoursReply.usedLiveAi, isFalse);

      final deliveryReply = await shop.barista.aiService.askBarista(
        prompt: 'Do you deliver to Biñan?',
        shop: shop,
      );
      expect(deliveryReply.text, contains('30 km'));
      expect(deliveryReply.text, contains('₱29.00'));

      final pairReply = await shop.barista.aiService.askBarista(
        prompt: 'What pairs well with Classic Burger?',
        shop: shop,
      );
      expect(pairReply.recommendations, isNotEmpty);

      final offTopicReply = await shop.barista.aiService.askBarista(
        prompt: 'Write Python code for bubble sort',
        shop: shop,
      );
      expect(offTopicReply.text.toLowerCase(), contains('smooch cafe'));
      expect(offTopicReply.recommendations, isEmpty);
    });

    test('uses Gemini API when configured and falls back cleanly on error', () async {
      final sampleId = const MenuRepository().products.first.id;
      final mockOk = MockClient((request) async {
        expect(request.url.host, 'generativelanguage.googleapis.com');
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'reply': 'Try our signature Tiramisu Latte!',
                        'productIds': [sampleId],
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final liveAi = SmoochAiService(client: mockOk, apiKey: 'test-key');
      final shop = ShopController(
        repository: const MenuRepository(),
        aiService: liveAi,
      );
      addTearDown(shop.dispose);

      final liveReply = await liveAi.askBarista(
        prompt: 'Recommend a coffee',
        shop: shop,
      );
      expect(liveReply.usedLiveAi, isTrue);
      expect(liveReply.text, 'Try our signature Tiramisu Latte!');
      expect(liveReply.recommendations.map((p) => p.id), [sampleId]);

      // Error fallback
      final mockFail = MockClient((_) async => http.Response('err', 500));
      final failAi = SmoochAiService(client: mockFail, apiKey: 'test-key');
      final fallbackReply = await failAi.askBarista(
        prompt: 'coffee under 120',
        shop: shop,
      );
      expect(fallbackReply.usedLiveAi, isFalse);
      expect(fallbackReply.recommendations, isNotEmpty);
    });

    testWidgets('opens Barista chat sheet and adds recommended item to bag', (
      tester,
    ) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: MenuScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ask-barista-fab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('barista-chat-sheet')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('barista-input')),
        'Coffee under 120',
      );
      await tester.tap(find.byKey(const Key('barista-send')));
      await tester.pumpAndSettle();

      final lastMsg = shop.barista.messages.last;
      expect(lastMsg.fromUser, isFalse);
      expect(lastMsg.recommendations, isNotEmpty);

      final firstRec = lastMsg.recommendations.first;
      final addBtn = find.byKey(Key('barista-add-${firstRec.id}'));
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(shop.quantityOf(firstRec), 1);
    });

    testWidgets('Ask Barista is accessible across tabs and secondary screens', (
      tester,
    ) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: MenuScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();

      // Still visible when switching to Saved, Order history, and Discover tabs.
      for (final label in ['Saved', 'Order history', 'Discover']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('ask-barista-fab')), findsOneWidget);
      }

      // Also accessible from CartScreen AppBar.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: CartScreen(controller: shop),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('barista-appbar-button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('barista-appbar-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('barista-chat-sheet')), findsOneWidget);
    });
  });
}
