import 'dart:async';

import 'package:ecommerce/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget staticFrame(Widget child) => MaterialApp(
  theme: AppTheme.theme,
  scrollBehavior: const AlwaysScrollbarBehavior(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: child,
);

TextEditingValue typedPhone(String value) {
  final formatter = PhMobileInputFormatter();
  var result = TextEditingValue.empty;
  for (final char in value.split('')) {
    final next = result.text + char;
    result = formatter.formatEditUpdate(
      result,
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );
  }
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    await (FontLoader(
      'Montserrat',
    )..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'))).load();
    await (FontLoader(
      'Playfair',
    )..addFont(rootBundle.load('assets/fonts/PlayfairDisplay.ttf'))).load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Smooch Cafe',
      packageName: 'com.example.ecommerce',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  test(
    'Currency/count formatting uses locale separators without changing PHP',
    () {
      expect(pesos(1234567.5, locale: 'en_PH'), '₱1,234,567.50');
      expect(countText(1234567, locale: 'en_PH'), '1,234,567');
      expect(pesos(1234.5, locale: 'de_DE'), contains('1.234,50'));
      expect(pesos(1234.5, locale: 'de_DE'), contains('₱'));
      expect(countText(1234567, locale: 'de_DE'), '1.234.567');
      expect(pesos(0, locale: 'not_a_locale'), '₱0.00');
    },
  );

  test(
    'Order dates localize for list and detail without altering the instant',
    () {
      final date = DateTime(2026, 10, 31, 14, 45);
      expect(orderDate(date, locale: 'en_US'), contains('Oct 31, 2026'));
      expect(
        orderDate(date, detailed: true, locale: 'en_US'),
        contains('October 31, 2026'),
      );
      expect(orderDate(date, locale: 'de_DE'), contains('31. Okt. 2026'));
      expect(date.hour, 14);
    },
  );

  test('Missing API strings never become address suggestions', () {
    for (final value in <String?>[null, '', ' ', 'null', ' NULL ']) {
      expect(value.isUsable, isFalse);
      expect(value.usableText, isNull);
      expect(value.orPlaceholder(), '-');
    }
    expect('  Carmona, Cavite  '.usableText, 'Carmona, Cavite');
  });

  test(
    'Philippine phone formatting supports typing and pasting both prefixes',
    () {
      expect(typedPhone('09171234567').text, '0917 123 4567');
      expect(typedPhone('+639171234567').text, '+63 917 123 4567');
      expect(typedPhone('+6').text, '+6');
      final formatter = PhMobileInputFormatter();
      for (final raw in ['09171234567', '+639171234567', '+63 917-123-4567']) {
        final formatted = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: raw,
            selection: TextSelection.collapsed(offset: raw.length),
          ),
        );
        expect(CheckoutValidation.mobile(formatted.text), isNull);
        expect(normalizedMobile(formatted.text), normalizedMobile(raw));
      }
      expect(readablePhMobile('+639171234567'), '+63 917 123 4567');
      expect(readablePhMobile('09171234567'), '0917 123 4567');
      expect(readablePhMobile('legacy value'), 'legacy value');
    },
  );

  test('Phone editing preserves a middle caret and composing text', () {
    final formatter = PhMobileInputFormatter();
    const old = TextEditingValue(
      text: '0917 123 4567',
      selection: TextSelection.collapsed(offset: 3),
    );
    final edited = formatter.formatEditUpdate(
      old,
      const TextEditingValue(
        text: '097 123 4567',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(edited.selection.baseOffset, lessThan(edited.text.length));
    const composing = TextEditingValue(
      text: '091',
      composing: TextRange(start: 0, end: 3),
    );
    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, composing),
      composing,
    );
  });

  test('Release notes compare versions semantically and reject bad/downgrade values', () {
    expect(unseenChanges('0.9.0', '1.0.0'), releaseNotes['1.0.0']);
    expect(unseenChanges('1.0.0', '1.0.0'), isEmpty);
    expect(unseenChanges('2.0.0', '1.0.0'), isEmpty);
    expect(unseenChanges('invalid', '1.0.0'), isEmpty);
  });

  testWidgets(
    'An upgrade shows notes once, and first installation skips them',
    (tester) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      await tester.pumpWidget(
        staticFrame(
          StartScreen(controller: shop, versionReader: () async => '1.0.0'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What’s new'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'smooch_last_seen_version',
        ),
        '1.0.0',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      SharedPreferences.setMockInitialValues({
        'smooch_last_seen_version': '0.9.0',
      });
      await tester.pumpWidget(
        staticFrame(
          StartScreen(controller: shop, versionReader: () async => '1.0.0'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What’s new'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString(
          'smooch_last_seen_version',
        ),
        '1.0.0',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        staticFrame(
          StartScreen(controller: shop, versionReader: () async => '1.0.0'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What’s new'), findsNothing);
    },
  );

  testWidgets('A delayed release lookup never opens over the menu', (
    tester,
  ) async {
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    SharedPreferences.setMockInitialValues({
      'smooch_last_seen_version': '0.9.0',
    });
    final version = Completer<String>();
    await tester.pumpWidget(
      staticFrame(
        StartScreen(controller: shop, versionReader: () => version.future),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pumpAndSettle();
    version.complete('1.0.0');
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('What’s new'), findsNothing);
  });

  testWidgets('Active navigation returns to top, then focuses search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    await tester.pumpWidget(staticFrame(MenuScreen(controller: shop)));
    await tester.pumpAndSettle();
    final page = find.byKey(const PageStorageKey('products-All'));
    final scroll = tester.widget<CustomScrollView>(page).controller!;
    await tester.drag(page, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    await tester.tap(find.text('Our menu'));
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
    await tester.tap(find.text('Our menu'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('menu-search')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(shop.category, 'All');
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS primary controller follows the visible category and cafe', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final shop = ShopController(repository: const MenuRepository());
    addTearDown(shop.dispose);
    await tester.pumpWidget(staticFrame(MenuScreen(controller: shop)));
    await tester.pumpAndSettle();
    final scaffold = find.byType(Scaffold);
    expect(
      PrimaryScrollController.of(tester.element(scaffold)),
      tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('products-All')),
          )
          .controller,
    );
    await tester.tap(find.text('Coffee').first);
    await tester.pumpAndSettle();
    expect(
      PrimaryScrollController.of(tester.element(scaffold)),
      tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('products-Coffee')),
          )
          .controller,
    );
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(
      PrimaryScrollController.of(tester.element(scaffold)),
      tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('menu-tab-cafe')),
          )
          .controller,
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Browser titles follow pushes, tabs, Back and fresh menu entry', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MiniShopApp());
    await tester.pumpAndSettle();
    final observer =
        tester
                .widget<MaterialApp>(find.byType(MaterialApp))
                .navigatorObservers!
                .single
            as CafeRouteTitles;
    expect(observer.title.value, 'Welcome · Smooch Cafe');
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Our menu · Smooch Cafe');
    await tester.tap(find.text('Coffee').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PopupMenuButton<MenuSort>).first);
    await tester.tap(find.byKey(const Key('menu-search')));
    await tester.pumpAndSettle();
    final searchFocus = tester
        .widget<TextField>(find.byKey(const Key('menu-search')))
        .focusNode!;
    expect(searchFocus.hasFocus, isTrue);
    await tester.tap(find.byType(PopupMenuButton<MenuSort>).first);
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Our menu · Smooch Cafe');
    expect(searchFocus.hasFocus, isFalse);
    Navigator.of(tester.element(find.byType(MenuScreen))).pop();
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Our menu · Smooch Cafe');
    expect(searchFocus.hasFocus, isFalse);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Discover · Smooch Cafe');
    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Your bag · Smooch Cafe');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Discover · Smooch Cafe');
    await Navigator.of(tester.element(find.byType(MenuScreen))).maybePop();
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Welcome · Smooch Cafe');
    await tester.ensureVisible(find.byKey(const Key('enter-store')));
    await tester.tap(find.byKey(const Key('enter-store')));
    await tester.pumpAndSettle();
    expect(observer.title.value, 'Our menu · Smooch Cafe');
  });

  testWidgets(
    'Checkout formats a phone, allows address newlines and dismisses keyboard on drag',
    (tester) async {
      final shop = ShopController(repository: const MenuRepository());
      addTearDown(shop.dispose);
      shop.addToCart(shop.products.first);
      await tester.pumpWidget(staticFrame(CheckoutScreen(controller: shop)));
      await tester.pumpAndSettle();
      final mobile = find.byKey(const Key('customer-mobile'));
      await tester.enterText(mobile, '+639171234567');
      expect(
        tester.widget<TextFormField>(mobile).controller!.text,
        '+63 917 123 4567',
      );
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('delivery-address')),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.textInputAction, TextInputAction.newline);
      expect(editable.maxLines, 2);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(shop.orders, isEmpty);
    },
  );

  testWidgets(
    'Friendly fallback fits full, compact and unbounded slots without app ancestors',
    (tester) async {
      final details = FlutterErrorDetails(
        exception: StateError('Synthetic test failure'),
        stack: StackTrace.current,
      );
      for (final size in [const Size(400, 700), const Size(40, 40)]) {
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: FriendlyErrorView(details: details),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            child: FriendlyErrorView(details: details),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('App version label uses installed metadata', (tester) async {
    await tester.pumpWidget(
      staticFrame(const Scaffold(body: AppVersionLabel())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Smooch Cafe 1.0.0 (7)'), findsOneWidget);
  });

  testWidgets('Horizontal hints follow available content at both edges', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    Widget frame(double contentWidth) => staticFrame(
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 80,
            child: HorizontalScrollFade(
              child: SingleChildScrollView(
                controller: scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: contentWidth, height: 80),
              ),
            ),
          ),
        ),
      ),
    );
    HorizontalEdgeFade fade() =>
        tester.widget<HorizontalEdgeFade>(find.byType(HorizontalEdgeFade));
    await tester.pumpWidget(frame(900));
    await tester.pumpAndSettle();
    expect(fade().fadeStart, isFalse);
    expect(fade().fadeEnd, isTrue);
    scroll.jumpTo(300);
    await tester.pumpAndSettle();
    expect(fade().fadeStart, isTrue);
    expect(fade().fadeEnd, isTrue);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(fade().fadeStart, isTrue);
    expect(fade().fadeEnd, isFalse);
    await tester.pumpWidget(frame(250));
    await tester.pumpAndSettle();
    expect(fade().fadeStart, isFalse);
    expect(fade().fadeEnd, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scroll-end padding follows system inset and minimum', (
    tester,
  ) async {
    for (final inset in [0.0, 34.0, 52.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(viewPadding: EdgeInsets.only(bottom: inset)),
            child: const BottomPadding(minimum: 24),
          ),
        ),
      );
      final spacer = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(BottomPadding),
          matching: find.byType(SizedBox),
        ),
      );
      expect(spacer.height, inset < 24 ? 24 : inset);
    }
  });

  testWidgets(
    'App text scaling preserves 2x and caps only larger preferences',
    (tester) async {
      for (final scale in [1.0, 1.6, 2.0, 3.0]) {
        late double effective;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Builder(
                builder: (context) => cafeTextScaleBuilder(context, child),
              ),
            ),
            home: Builder(
              builder: (context) {
                effective = MediaQuery.textScalerOf(context).scale(10) / 10;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(effective, scale > 2 ? 2 : scale);
      }
    },
  );
}
