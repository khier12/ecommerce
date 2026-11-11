import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui'
    as ui
    show
        Image,
        ImageShader,
        PathMetric,
        PictureRecorder,
        instantiateImageCodec,
        Vertices,
        VertexMode;
import 'dart:ui' show FontFeature, PlatformDispatcher, PointerDeviceKind;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_map/flutter_map.dart'
    show
        CameraFit,
        FlutterMap,
        MapCamera,
        MapController,
        MapOptions,
        Marker,
        MarkerLayer,
        Polyline,
        PolylineLayer,
        TileLayer;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:intl/intl.dart' show DateFormat, Intl, NumberFormat;
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  ErrorWidget.builder = (details) => FriendlyErrorView(details: details);
  runApp(MiniShopApp(orderStore: PreferencesOrderStore()));
}

// ============================================================
// FINAL PROJECT STARTER CODE
// Customize this application based on your chosen e-commerce.
//
// The required StartScreen is implemented below. Its ORDER NOW
// button opens MenuScreen using Navigator.push() and
// MaterialPageRoute. All application code remains in this file.
// ============================================================

// ============================================================
// APPLICATION COLORS
// Customize these colors to match your selected e-commerce.
// ======================================
abstract final class AppColors {
  static const dark = Color(0xFF0A4952);
  static const teal = Color(0xFF0E6F7A);
  static const coral = Color(0xFFF04C45);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFFC0D8DA);
  static const line = Color(0xFF39747C);
  static const canvas = Color(0xFFF6F3ED);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF163B3D);
  static const secondaryText = Color(0xFF56696B);
  static const border = Color(0xFFDCE3DF);
  static const action = Color(0xFFC23F38);
  static const softTeal = Color(0xFFE8F0EC);
  static const softCoral = Color(0xFFFBE9E5);
  static const oat = Color(0xFFEEE5D6);
  static const gold = Color(0xFFE9C587);
}

abstract final class CafeMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 320);
  static const entrance = Duration(milliseconds: 640);
  static const spring = SpringDescription(mass: 1, stiffness: 380, damping: 27);
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

abstract final class CafeShape {
  static const card = 22.0;
  static const panel = 28.0;
}

abstract final class AppTheme {
  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.standard,
    fontFamily: 'Montserrat',
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform:
              kIsWeb ||
                  const [
                    TargetPlatform.macOS,
                    TargetPlatform.windows,
                    TargetPlatform.linux,
                    TargetPlatform.fuchsia,
                  ].contains(platform)
              ? const _NoPageTransitionsBuilder()
              : const _CafePageTransitionsBuilder(),
      },
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.action,
      onPrimary: AppColors.white,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.secondaryText,
      outline: AppColors.secondaryText,
      outlineVariant: AppColors.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dark,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.action,
        foregroundColor: AppColors.white,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: AppColors.secondaryText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.teal,
      selectionHandleColor: AppColors.teal,
      selectionColor: AppColors.teal.withValues(alpha: .22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
      prefixIconColor: AppColors.secondaryText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondaryText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.dark,
      contentTextStyle: TextStyle(
        color: AppColors.white,
        fontFamily: 'Montserrat',
      ),
      actionTextColor: AppColors.white,
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.softTeal,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}

TextStyle displayStyle(double size, {Color color = AppColors.ink}) => TextStyle(
  fontFamily: 'Playfair',
  fontSize: size,
  height: 1.12,
  fontWeight: FontWeight.w600,
  color: color,
  letterSpacing: -.8,
);

const cafeNumberFeatures = <FontFeature>[FontFeature.tabularFigures()];

class NumericText extends Text {
  NumericText(
    super.data, {
    super.key,
    TextStyle? style,
    super.textAlign,
    super.maxLines,
    super.overflow,
  }) : super(
         style: (style ?? const TextStyle()).copyWith(
           fontFeatures: cafeNumberFeatures,
         ),
       );
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Duration get reverseTransitionDuration => Duration.zero;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

// Customize MaterialPageRoute transitions while keeping the required
// Navigator.push() / MaterialPageRoute navigation flow.
class _CafePageTransitionsBuilder extends PageTransitionsBuilder {
  const _CafePageTransitionsBuilder();

  @override
  Duration get transitionDuration => StartScreen.transitionDuration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 450);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    if (route.settings.name == MenuScreen.routeName) {
      return _MenuTransition(animation: animation, child: child);
    }
    return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

// ============================================================
// PRODUCT, CART, AND ORDER MODELS
// ============================================================
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.image,
    this.featured = false,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final String subcategory;
  final String description;
  final String image;
  final bool featured;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'subcategory': subcategory,
    'description': description,
    'image': image,
    'featured': featured,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    price: json['price'] as int,
    category: json['category'] as String,
    subcategory: json['subcategory'] as String,
    description: json['description'] as String,
    image: json['image'] as String,
    featured: json['featured'] as bool? ?? false,
  );
}

@immutable
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;
  int get total => product.price * quantity;

  Map<String, Object?> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
  );
}

String displayLocale() =>
    Intl.canonicalizedLocale(PlatformDispatcher.instance.locale.toString());

final _currencyFormats = <String, NumberFormat>{};
final _countFormats = <String, NumberFormat>{};

String pesos(num amount, {String? locale}) {
  final key = locale ?? displayLocale();
  final formatter = _currencyFormats.putIfAbsent(key, () {
    try {
      return NumberFormat.currency(
        locale: key,
        name: 'PHP',
        symbol: '\u20b1',
        decimalDigits: 2,
      );
    } catch (_) {
      return NumberFormat.currency(
        locale: 'en_PH',
        name: 'PHP',
        symbol: '\u20b1',
        decimalDigits: 2,
      );
    }
  });
  return formatter.format(amount);
}

String countText(num count, {String? locale}) {
  final key = locale ?? displayLocale();
  final formatter = _countFormats.putIfAbsent(key, () {
    try {
      return NumberFormat.decimalPattern(key);
    } catch (_) {
      return NumberFormat.decimalPattern('en_PH');
    }
  });
  return formatter.format(count);
}

String normalizedMobile(String value) => value.replaceAll(RegExp(r'[\s-]'), '');

MaskTextInputFormatter phPhoneMask({
  required bool international,
  String? initialText,
}) => MaskTextInputFormatter(
  mask: international ? '+## ### ### ####' : '#### ### ####',
  initialText: initialText,
  filter: {'#': RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.eager,
);

class PhMobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final compact = normalizedMobile(newValue.text);
    final international = compact.startsWith('+');
    if (international && compact.length <= 3) return newValue;
    return phPhoneMask(
      international: international,
      initialText: oldValue.text,
    ).formatEditUpdate(oldValue, newValue);
  }
}

String readablePhMobile(String raw) {
  final clean = normalizedMobile(raw);
  if (!RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(clean)) return raw;
  return phPhoneMask(international: clean.startsWith('+')).maskText(clean);
}

extension UsableDisplayString on String? {
  String? get usableText {
    final value = this?.trim();
    return value == null || value.isEmpty || value.toLowerCase() == 'null'
        ? null
        : value;
  }

  bool get isUsable => usableText != null;
  String orPlaceholder([String placeholder = '-']) => usableText ?? placeholder;
}

abstract final class CheckoutValidation {
  static String? name(String? value) =>
      (value ?? '').trim().length < 2 ? 'Enter your name' : null;
  static String? mobile(String? value) =>
      RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(normalizedMobile(value ?? ''))
      ? null
      : 'Enter a valid PH mobile number';
  static String? address(String? value) =>
      (value ?? '').trim().length < 8 ? 'Enter your delivery address' : null;

  static const deliveryCenter = LatLng(14.3158, 121.0561);
  static const deliveryRadiusKm = 30;
  static const deliveryRadiusLabel = '$deliveryRadiusKm km';

  static bool isWithinDeliveryArea(LatLng? point) {
    if (point == null ||
        !point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      return false;
    }
    const earthRadiusKm = 6371.0;
    final latitudeDelta =
        (point.latitude - deliveryCenter.latitude) * math.pi / 180;
    final longitudeDelta =
        (point.longitude - deliveryCenter.longitude) * math.pi / 180;
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(deliveryCenter.latitude * math.pi / 180) *
            math.cos(point.latitude * math.pi / 180) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final distanceKm = earthRadiusKm * 2 * math.asin(math.sqrt(a));
    // Include the boundary despite floating-point roundoff in the distance.
    return distanceKm <= deliveryRadiusKm + 1e-9;
  }
}

String orderDate(DateTime value, {bool detailed = false, String? locale}) {
  DateFormat make(String code) =>
      (detailed ? DateFormat.yMMMMd(code) : DateFormat.yMMMd(code)).add_jm();
  DateFormat formatter;
  try {
    formatter = make(locale ?? displayLocale());
  } catch (_) {
    formatter = make('en_US');
  }
  return formatter.format(value.toLocal());
}

enum FulfillmentMethod { pickup, delivery }

enum OrderStage {
  confirmed,
  preparing,
  riderAssigned,
  onTheWay,
  delivered,
  readyForPickup,
}

extension OrderStageDetails on OrderStage {
  String get label => switch (this) {
    OrderStage.confirmed => 'Confirmed',
    OrderStage.preparing => 'Preparing',
    OrderStage.riderAssigned => 'Rider assigned',
    OrderStage.onTheWay => 'On the way',
    OrderStage.delivered => 'Delivered',
    OrderStage.readyForPickup => 'Ready for pickup',
  };

  String get message => switch (this) {
    OrderStage.confirmed =>
      'The restaurant has received and accepted your order.',
    OrderStage.preparing =>
      'The kitchen is preparing and packaging your order.',
    OrderStage.riderAssigned =>
      'A delivery partner has been assigned and picked up your order.',
    OrderStage.onTheWay => 'Your rider is heading to your delivery address.',
    OrderStage.delivered => 'Your order has arrived at your address.',
    OrderStage.readyForPickup => 'Your order is ready for collection.',
  };
}

@immutable
class OrderReceipt {
  OrderReceipt({
    required this.reference,
    required List<CartItem> items,
    required this.customerName,
    required this.mobileNumber,
    required this.notes,
    required this.paymentMethod,
    required this.createdAt,
    this.fulfillment = FulfillmentMethod.pickup,
    this.deliveryAddress = '',
    this.deliveryLatitude,
    this.deliveryLongitude,
  }) : items = List.unmodifiable(items);

  final String reference;
  final List<CartItem> items;
  final String customerName;
  final String mobileNumber;
  final String notes;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final FulfillmentMethod fulfillment;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  LatLng? get deliveryPoint =>
      deliveryLatitude != null &&
          deliveryLongitude != null &&
          deliveryLatitude!.isFinite &&
          deliveryLongitude!.isFinite &&
          deliveryLatitude!.abs() <= 90 &&
          deliveryLongitude!.abs() <= 180
      ? LatLng(deliveryLatitude!, deliveryLongitude!)
      : null;
  List<OrderStage> get stages => fulfillment == FulfillmentMethod.delivery
      ? const [
          OrderStage.confirmed,
          OrderStage.preparing,
          OrderStage.riderAssigned,
          OrderStage.onTheWay,
          OrderStage.delivered,
        ]
      : const [
          OrderStage.confirmed,
          OrderStage.preparing,
          OrderStage.readyForPickup,
        ];

  OrderStage stageAt(DateTime now) {
    final elapsedSeconds = now.difference(createdAt).inSeconds;
    final index = (elapsedSeconds ~/ 10).clamp(0, stages.length - 1);
    return stages[index];
  }

  String get paymentStatus => paymentMethod == PaymentMethod.cash
      ? fulfillment == FulfillmentMethod.delivery
            ? 'Payment due on delivery'
            : 'Payment due at pickup'
      : 'Payment step complete';
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get total => items.fold(0, (sum, item) => sum + item.total);

  Map<String, Object?> toJson() => {
    'reference': reference,
    'items': items.map((item) => item.toJson()).toList(),
    'customerName': customerName,
    'mobileNumber': mobileNumber,
    'notes': notes,
    'paymentMethod': paymentMethod.name,
    'createdAt': createdAt.toIso8601String(),
    'fulfillment': fulfillment.name,
    'deliveryAddress': deliveryAddress,
    'deliveryLatitude': deliveryLatitude,
    'deliveryLongitude': deliveryLongitude,
  };

  factory OrderReceipt.fromJson(Map<String, dynamic> json) => OrderReceipt(
    reference: json['reference'] as String,
    items: (json['items'] as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    customerName: json['customerName'] as String? ?? '',
    mobileNumber: json['mobileNumber'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    paymentMethod: PaymentMethod.values.byName(
      json['paymentMethod'] as String? ?? 'cash',
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    fulfillment: FulfillmentMethod.values.byName(
      json['fulfillment'] as String? ?? 'pickup',
    ),
    deliveryAddress: json['deliveryAddress'] as String? ?? '',
    deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
    deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
  );
}

enum PaymentMethod { cash, digital }

abstract class OrderStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesOrderStore implements OrderStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const _key = 'smooch_cafe_orders_v1';

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}

class MemoryOrderStore implements OrderStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

// ============================================================
// PRODUCT DATA
// ============================================================
// BEGIN CAFE CATALOG
// Generated from SmoochCafe/pages/products.html by tools/import_menu.mjs.
const cafeProducts = <Product>[
  Product(
    id: "coffee-tiramisu-latte",
    name: "Tiramisu Latte",
    price: 145,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Espresso-based latte with tiramisu-inspired cream. A little coffee, a little dessert, and a whole lot of comfort.",
    image: "assets/images/Tiramisu Latte 5.webp",
    featured: true,
  ),
  Product(
    id: "quarter-pounder-classic-burger",
    name: "Classic Burger",
    price: 110,
    category: "Food",
    subcategory: "Quarter Pounder",
    description: "A juicy quarter-pound patty with cheese and fresh veggies. Your comfort-food favorite, made to pair with a Smooch drink.",
    image: "assets/images/Classic Burger.webp",
    featured: true,
  ),
  Product(
    id: "brownies-chocolate-bliss",
    name: "Chocolate Bliss",
    price: 145,
    category: "Pastries",
    subcategory: "Brownies",
    description: "A fudgy chocolate brownie with a rich, moist center. The perfect little companion to your favorite coffee.",
    image: "assets/images/Chocolate Bliss 2.png",
    featured: true,
  ),
  Product(
    id: "coffee-spanish-latte",
    name: "Spanish Latte",
    price: 80,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Espresso and milk with a sweet, creamy finish. A comforting coffee for slow afternoons.",
    image: "assets/images/Spanish Latte 5.webp",
    featured: true,
  ),
  Product(
    id: "non-coffee-strawberry-matcha",
    name: "Strawberry Matcha",
    price: 115,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Earthy matcha meets sweet strawberry and milk for a colorful sip of happiness.",
    image: "assets/images/Strawberry Matcha 1.webp",
    featured: true,
  ),
  Product(
    id: "cakes-basque-cheesecake",
    name: "Basque Cheesecake",
    price: 190,
    category: "Pastries",
    subcategory: "Cakes",
    description: "A sweet little moment from our cakes selection. Enjoy it with a hot or iced coffee.",
    image: "assets/images/Basque Cheesecake 1.png",
    featured: true,
  ),
  Product(
    id: "sandwiches-classic-chicken",
    name: "Classic Chicken",
    price: 110,
    category: "Food",
    subcategory: "Sandwiches",
    description: "A comforting pick from our sandwiches menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Classic Chicken Sandwich.webp",
    featured: false,
  ),
  Product(
    id: "quesadilla-cheese-quesadilla",
    name: "Cheese Quesadilla",
    price: 115,
    category: "Food",
    subcategory: "Quesadilla",
    description: "A comforting pick from our quesadilla menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Cheese Quesadilla.webp",
    featured: false,
  ),
  Product(
    id: "french-fries-bbq-fries",
    name: "BBQ Fries",
    price: 30,
    category: "Food",
    subcategory: "French Fries",
    description: "A comforting pick from our french fries menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/BBQ Fries.webp",
    featured: false,
  ),
  Product(
    id: "rice-bowls-sisig",
    name: "Sisig",
    price: 130,
    category: "Food",
    subcategory: "Rice Bowls",
    description: "A comforting pick from our rice bowls menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Sisig Rice Bowl.webp",
    featured: false,
  ),
  Product(
    id: "rice-bowls-chicken-teriyaki",
    name: "Chicken Teriyaki",
    price: 125,
    category: "Food",
    subcategory: "Rice Bowls",
    description: "A comforting pick from our rice bowls menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Chicken Teriyaki Rice Bowl.webp",
    featured: false,
  ),
  Product(
    id: "pasta-carbonara",
    name: "Carbonara",
    price: 115,
    category: "Food",
    subcategory: "Pasta",
    description: "A comforting pick from our pasta menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Carbonara 1.png",
    featured: false,
  ),
  Product(
    id: "nachos-beef-nachos",
    name: "Beef Nachos",
    price: 130,
    category: "Food",
    subcategory: "Nachos",
    description: "A comforting pick from our nachos menu. Pair it with your favorite handcrafted drink.",
    image: "assets/images/Beef Nachos 1.png",
    featured: false,
  ),
  Product(
    id: "brownies-biscoff-blondies",
    name: "Biscoff Blondies",
    price: 50,
    category: "Pastries",
    subcategory: "Brownies",
    description: "A sweet little moment from our brownies selection. Enjoy it with a hot or iced coffee.",
    image: "assets/images/Biscoff Blandies 1.png",
    featured: false,
  ),
  Product(
    id: "cookies-og-cookies",
    name: "OG Cookies",
    price: 40,
    category: "Pastries",
    subcategory: "Cookies",
    description: "A sweet little moment from our cookies selection. Enjoy it with a hot or iced coffee.",
    image: "assets/images/OG Chookies 1.png",
    featured: false,
  ),
  Product(
    id: "cookies-hershey-s-crinkles",
    name: "Hershey's Crinkles",
    price: 45,
    category: "Pastries",
    subcategory: "Cookies",
    description: "A sweet little moment from our cookies selection. Enjoy it with a hot or iced coffee.",
    image: "assets/images/Hershey's Crinkles 1.png",
    featured: false,
  ),
  Product(
    id: "muffins-choco-chip-muffin",
    name: "Choco Chip Muffin",
    price: 75,
    category: "Pastries",
    subcategory: "Muffins",
    description: "A sweet little moment from our muffins selection. Enjoy it with a hot or iced coffee.",
    image: "assets/images/Choco Chip Muffin 1.png",
    featured: false,
  ),
  Product(
    id: "coffee-americano",
    name: "Americano",
    price: 60,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/Americano 3.webp",
    featured: false,
  ),
  Product(
    id: "coffee-latte",
    name: "Latte",
    price: 70,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/Latte 5.webp",
    featured: false,
  ),
  Product(
    id: "coffee-french-vanilla-latte",
    name: "French Vanilla Latte",
    price: 75,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/French Vanilla Latte 5.webp",
    featured: false,
  ),
  Product(
    id: "coffee-mocha-latte",
    name: "Mocha Latte",
    price: 100,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/Mocha Latte 5.webp",
    featured: false,
  ),
  Product(
    id: "coffee-caramel-macchiato",
    name: "Caramel Macchiato",
    price: 95,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/Caramel Macchiato 5.webp",
    featured: false,
  ),
  Product(
    id: "coffee-dirty-matcha-latte",
    name: "Dirty Matcha Latte",
    price: 115,
    category: "Coffee",
    subcategory: "Coffee",
    description: "Your next coffee moment, from our espresso-based coffee selection. Made for your everyday cravings.",
    image: "assets/images/Dirty Matcha Latte 5.webp",
    featured: false,
  ),
  Product(
    id: "non-coffee-chocolate",
    name: "Chocolate",
    price: 195,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Skip the espresso and find a little happiness in our non-coffee drink selection.",
    image: "assets/images/Chocolate 1.webp",
    featured: false,
  ),
  Product(
    id: "non-coffee-strawberry-latte",
    name: "Strawberry Latte",
    price: 85,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Skip the espresso and find a little happiness in our non-coffee drink selection.",
    image: "assets/images/Strawberry Latte 1.webp",
    featured: false,
  ),
  Product(
    id: "non-coffee-matcha-latte",
    name: "Matcha Latte",
    price: 105,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Skip the espresso and find a little happiness in our non-coffee drink selection.",
    image: "assets/images/Matcha Latte 1.webp",
    featured: false,
  ),
  Product(
    id: "non-coffee-ube-latte",
    name: "Ube Latte",
    price: 75,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Skip the espresso and find a little happiness in our non-coffee drink selection.",
    image: "assets/images/Ube Latte 1.webp",
    featured: false,
  ),
  Product(
    id: "non-coffee-ube-matcha",
    name: "Ube Matcha",
    price: 105,
    category: "Non-Coffee",
    subcategory: "Non-Coffee",
    description: "Skip the espresso and find a little happiness in our non-coffee drink selection.",
    image: "assets/images/Ube Matcha.webp",
    featured: false,
  ),
  Product(
    id: "ice-blended-mocha",
    name: "Mocha",
    price: 125,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Mocha 6.png",
    featured: false,
  ),
  Product(
    id: "ice-blended-caramel-macchiato",
    name: "Caramel Macchiato",
    price: 120,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Caramel Macchiato 7.png",
    featured: false,
  ),
  Product(
    id: "ice-blended-choco-hazelnut",
    name: "Choco Hazelnut",
    price: 135,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Choco Hazelnut 7.png",
    featured: false,
  ),
  Product(
    id: "ice-blended-strawberry",
    name: "Strawberry",
    price: 110,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Strawberry 6.png",
    featured: false,
  ),
  Product(
    id: "ice-blended-matcha",
    name: "Matcha",
    price: 115,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Matcha 4.png",
    featured: false,
  ),
  Product(
    id: "ice-blended-ube",
    name: "Ube",
    price: 100,
    category: "Ice Blended",
    subcategory: "Ice Blended",
    description: "A cool, blended treat for a sweet afternoon break. Discover your favorite flavor.",
    image: "assets/images/Ube 2.png",
    featured: false,
  ),
  Product(
    id: "lava-series-chocolate-lava",
    name: "Chocolate Lava",
    price: 110,
    category: "More Drinks",
    subcategory: "Lava Series",
    description: "A refreshing little break from our lava series selection. A delicious way to complete your order.",
    image: "assets/images/Chocolate Lava 5.webp",
    featured: false,
  ),
  Product(
    id: "lava-series-strawberry-lava",
    name: "Strawberry Lava",
    price: 135,
    category: "More Drinks",
    subcategory: "Lava Series",
    description: "A refreshing little break from our lava series selection. A delicious way to complete your order.",
    image: "assets/images/Strawberry Lava 5.png",
    featured: false,
  ),
  Product(
    id: "chilled-drinks-bottled-water",
    name: "Bottled Water",
    price: 12,
    category: "More Drinks",
    subcategory: "Chilled Drinks",
    description: "A refreshing little break from our chilled drinks selection. A delicious way to complete your order.",
    image: "assets/images/Bottled Water 1.png",
    featured: false,
  ),
  Product(
    id: "chilled-drinks-calamansi-juice",
    name: "Calamansi Juice",
    price: 38,
    category: "More Drinks",
    subcategory: "Chilled Drinks",
    description: "A refreshing little break from our chilled drinks selection. A delicious way to complete your order.",
    image: "assets/images/Calamansi juice 1.png",
    featured: false,
  ),
  Product(
    id: "dessert-affogato",
    name: "Affogato",
    price: 65,
    category: "More Drinks",
    subcategory: "Dessert",
    description: "A refreshing little break from our dessert selection. A delicious way to complete your order.",
    image: "assets/images/Affogato 4.png",
    featured: false,
  ),
  Product(
    id: "dessert-matcha-affogato",
    name: "Matcha Affogato",
    price: 85,
    category: "More Drinks",
    subcategory: "Dessert",
    description: "A refreshing little break from our dessert selection. A delicious way to complete your order.",
    image: "assets/images/Matcha Affogato 2.png",
    featured: false,
  ),
];
// END CAFE CATALOG

// ============================================================
// LOCAL MENU DATA
// ============================================================
// The browseable menu is intentionally limited to 40 varied choices:
// Coffee 8, Non-Coffee 6, Food 8, Pastries 6, Ice Blended 6, More Drinks 6.
// Saved receipts retain their own product snapshots; retired photos use a placeholder.
// This selection sits outside the importer block so imports preserve it.
const cafeMenuProductIds = <String>{
  // Coffee: signatures, espresso classics, flavored and matcha options.
  'coffee-tiramisu-latte',
  'coffee-spanish-latte',
  'coffee-americano',
  'coffee-latte',
  'coffee-french-vanilla-latte',
  'coffee-mocha-latte',
  'coffee-caramel-macchiato',
  'coffee-dirty-matcha-latte',
  // Non-Coffee: retain all six distinct choices.
  'non-coffee-strawberry-matcha',
  'non-coffee-chocolate',
  'non-coffee-strawberry-latte',
  'non-coffee-matcha-latte',
  'non-coffee-ube-latte',
  'non-coffee-ube-matcha',
  // Food: cover the seven food groups without repeated flavor variants.
  'quarter-pounder-classic-burger',
  'sandwiches-classic-chicken',
  'quesadilla-cheese-quesadilla',
  'french-fries-bbq-fries',
  'rice-bowls-sisig',
  'rice-bowls-chicken-teriyaki',
  'pasta-carbonara',
  'nachos-beef-nachos',
  // Pastries: brownies, cookies, a muffin and the featured cheesecake.
  'brownies-chocolate-bliss',
  'cakes-basque-cheesecake',
  'brownies-biscoff-blondies',
  'cookies-og-cookies',
  'cookies-hershey-s-crinkles',
  'muffins-choco-chip-muffin',
  // Ice Blended: coffee, chocolate, fruit, matcha and ube.
  'ice-blended-mocha',
  'ice-blended-caramel-macchiato',
  'ice-blended-choco-hazelnut',
  'ice-blended-strawberry',
  'ice-blended-matcha',
  'ice-blended-ube',
  // More Drinks: lava drinks, chilled essentials and affogato desserts.
  'lava-series-chocolate-lava',
  'lava-series-strawberry-lava',
  'chilled-drinks-bottled-water',
  'chilled-drinks-calamansi-juice',
  'dessert-affogato',
  'dessert-matcha-affogato',
};

class MenuRepository {
  const MenuRepository();

  // Cache an immutable projection once; filters, Discover counts and carousel
  // all consume the same selection without filtering again on cart rebuilds.
  static final _menu = List<Product>.unmodifiable(
    cafeProducts.where((product) => cafeMenuProductIds.contains(product.id)),
  );

  List<Product> get products => _menu;
}

// ============================================================
// SEARCH, CATEGORY FILTERS, AND CART STATE
// ============================================================
enum MenuSort {
  recommended('Cafe picks'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  name('Name: A–Z');

  const MenuSort(this.label);
  final String label;
}

class ShopController extends ChangeNotifier {
  ShopController({required this.repository, OrderStore? orderStore})
    : orderStore = orderStore ?? MemoryOrderStore();

  final MenuRepository repository;
  final OrderStore orderStore;
  final Map<String, CartItem> _cart = {};
  final List<OrderReceipt> _orders = [];
  bool _placingOrder = false;
  bool loadingOrders = false;
  String? historyError;
  bool _disposed = false;
  Future<void>? _restoreTask;
  int _nextOrderNumber = 1;
  String _query = '';
  List<String> _queryWords = const [];
  String _category = 'All';
  MenuSort _sort = MenuSort.recommended;

  static const categories = [
    'All',
    'Coffee',
    'Non-Coffee',
    'Food',
    'Pastries',
    'Ice Blended',
    'More Drinks',
  ];

  String get query => _query;
  String get category => _category;
  MenuSort get sort => _sort;
  bool get placingOrder => _placingOrder;
  List<OrderReceipt> get orders => List.unmodifiable(_orders);
  bool get hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _category != 'All' ||
      _sort != MenuSort.recommended;
  List<Product> get products => repository.products;
  List<Product> get filteredProducts => productsForCategory(_category);

  // Read-only projection for adjacent swipe pages; filtering rules stay shared.
  List<Product> productsForCategory(String category) {
    final matches = products.where((product) {
      final matchesCategory = category == 'All' || product.category == category;
      return matchesCategory && _matchesQuery(product);
    }).toList();
    switch (_sort) {
      case MenuSort.recommended:
        break;
      case MenuSort.priceLow:
        matches.sort((a, b) => a.price.compareTo(b.price));
      case MenuSort.priceHigh:
        matches.sort((a, b) => b.price.compareTo(a.price));
      case MenuSort.name:
        matches.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return matches;
  }

  bool _matchesQuery(Product product) {
    final text = '${product.name} ${product.category} ${product.subcategory}'
        .toLowerCase();
    return _queryWords.every(text.contains);
  }

  int quantityOf(Product product) => _cart[product.id]?.quantity ?? 0;

  void sortBy(MenuSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  List<CartItem> get cartItems => List.unmodifiable(_cart.values);
  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  int get total => _cart.values.fold(0, (sum, item) => sum + item.total);

  void search(String value) {
    if (_query == value) return;
    _query = value;
    _queryWords = value.trim().toLowerCase().split(RegExp(r'\s+'));
    notifyListeners();
  }

  void selectCategory(String value) {
    if (_category == value || !categories.contains(value)) return;
    _category = value;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _queryWords = const [];
    _category = 'All';
    _sort = MenuSort.recommended;
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1}) {
    if (quantity < 1 || _placingOrder) return;
    final previous = _cart[product.id]?.quantity ?? 0;
    _cart[product.id] = CartItem(
      product: product,
      quantity: previous + quantity,
    );
    notifyListeners();
  }

  void decrease(Product product) {
    if (_placingOrder) return;
    final current = _cart[product.id];
    if (current == null) return;
    if (current.quantity == 1) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = CartItem(
        product: product,
        quantity: current.quantity - 1,
      );
    }
    notifyListeners();
  }

  void remove(Product product) {
    if (_placingOrder) return;
    _cart.remove(product.id);
    notifyListeners();
  }

  Future<void> restoreOrders({bool retry = false}) {
    if (retry && !loadingOrders) _restoreTask = null;
    if (_restoreTask != null) return _restoreTask!;
    loadingOrders = true;
    historyError = null;
    notifyListeners();
    return _restoreTask = _loadOrders();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final saved = await orderStore.read();
      if (_disposed || saved == null) return;
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final restored = <OrderReceipt>[];
      var nextNumber = math.max(1, (data['nextOrderNumber'] as int?) ?? 1);
      final seenReferences = <String>{};
      for (final entry in data['orders'] as List) {
        try {
          final record = entry as Map<String, dynamic>;
          final reference = record['reference'] as String;
          final number = int.tryParse(reference.replaceFirst('SMC-', ''));
          if (number != null) nextNumber = math.max(nextNumber, number + 1);
          final order = OrderReceipt.fromJson(record);
          if (order.items.isEmpty ||
              order.items.any(
                (item) => item.quantity < 1 || item.product.price < 0,
              )) {
            throw const FormatException('Invalid receipt items');
          }
          if (seenReferences.add(reference)) restored.add(order);
        } on FormatException {
          historyError = 'Some saved orders could not be read.';
        } on TypeError {
          historyError = 'Some saved orders could not be read.';
        } on ArgumentError {
          historyError = 'Some saved orders could not be read.';
        }
      }
      restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _orders
        ..clear()
        ..addAll(restored);
      _nextOrderNumber = nextNumber;
    } on FormatException {
      historyError = 'Saved orders could not be read on this device.';
    } on TypeError {
      historyError = 'Saved orders could not be read on this device.';
    } catch (_) {
      historyError = 'Could not load your orders. Please try again.';
      _restoreTask = null;
      rethrow;
    } finally {
      loadingOrders = false;
      if (!_disposed) notifyListeners();
    }
  }

  String _encodeOrders({OrderReceipt? newOrder}) => jsonEncode({
    'nextOrderNumber': _nextOrderNumber + (newOrder == null ? 0 : 1),
    'orders': [
      if (newOrder != null) newOrder.toJson(),
      ..._orders.map((order) => order.toJson()),
    ],
  });

  Future<OrderReceipt?> submitOrder({
    required String customerName,
    required String mobileNumber,
    required String notes,
    required PaymentMethod paymentMethod,
    required String deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) async {
    if (_disposed ||
        _cart.isEmpty ||
        _placingOrder ||
        CheckoutValidation.name(customerName) != null ||
        CheckoutValidation.mobile(mobileNumber) != null ||
        CheckoutValidation.address(deliveryAddress) != null ||
        (deliveryLatitude == null) != (deliveryLongitude == null) ||
        (deliveryLatitude != null &&
            (!deliveryLatitude.isFinite || deliveryLatitude.abs() > 90)) ||
        (deliveryLongitude != null &&
            (!deliveryLongitude.isFinite || deliveryLongitude.abs() > 180)) ||
        (deliveryLatitude != null &&
            !CheckoutValidation.isWithinDeliveryArea(
              LatLng(deliveryLatitude, deliveryLongitude!),
            ))) {
      return null;
    }
    _placingOrder = true;
    notifyListeners();
    try {
      await restoreOrders();
      if (_disposed) return null;
      final order = OrderReceipt(
        reference: 'SMC-${_nextOrderNumber.toString().padLeft(4, '0')}',
        items: cartItems,
        customerName: customerName.trim(),
        mobileNumber: normalizedMobile(mobileNumber),
        notes: notes.trim(),
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        fulfillment: FulfillmentMethod.delivery,
        deliveryAddress: deliveryAddress.trim(),
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
      );
      await orderStore.write(_encodeOrders(newOrder: order));
      _nextOrderNumber++;
      _orders.insert(0, order);
      _cart.clear();
      if (!_disposed) notifyListeners();
      return order;
    } finally {
      _placingOrder = false;
      if (!_disposed) notifyListeners();
    }
  }
}

// ============================================================
// MAIN APPLICATION
// ============================================================

class MiniShopApp extends StatefulWidget {
  const MiniShopApp({super.key, this.orderStore});
  final OrderStore? orderStore;

  @override
  State<MiniShopApp> createState() => _MiniShopAppState();
}

class _MiniShopAppState extends State<MiniShopApp> {
  late final ShopController controller;
  final titles = CafeRouteTitles();

  @override
  void initState() {
    super.initState();
    controller = ShopController(
      repository: const MenuRepository(),
      orderStore: widget.orderStore,
    );
    unawaited(controller.restoreOrders().catchError((Object _) {}));
  }

  @override
  void dispose() {
    titles.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smooch Cafe',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    scrollBehavior: const AlwaysScrollbarBehavior(),
    navigatorObservers: [titles],
    builder: (context, child) => CafeTitleScope(
      titles: titles,
      child: ValueListenableBuilder<String>(
        valueListenable: titles.title,
        child: cafeTextScaleBuilder(context, child),
        builder: (context, value, navigator) =>
            Title(title: value, color: AppColors.dark, child: navigator!),
      ),
    ),
    home: StartScreen(controller: controller),
  );
}

// ============================================================
// SHARED WIDGETS
// ============================================================
Widget cafeTextScaleBuilder(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 2)),
    child: child ?? const SizedBox.shrink(),
  );
}

class AlwaysScrollbarBehavior extends MaterialScrollBehavior {
  const AlwaysScrollbarBehavior();
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => Scrollbar(controller: details.controller, child: child);
}

class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key, this.minimum = 16});
  final double minimum;
  static double of(BuildContext context, {double minimum = 16}) =>
      math.max(MediaQuery.viewPaddingOf(context).bottom, minimum);
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: of(context, minimum: minimum));
}

abstract final class CafeHaptics {
  static Future<bool>? _capability;
  static Future<void> play(HapticsType type) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      if (await (_capability ??= Haptics.canVibrate())) {
        await Haptics.vibrate(type);
      }
    } catch (_) {
      /* Optional feedback must never prevent a customer action. */
    }
  }

  static void light() => unawaited(play(HapticsType.light));
  static void selection() => unawaited(play(HapticsType.selection));
  static void success() => unawaited(play(HapticsType.success));
  static void warning() => unawaited(play(HapticsType.warning));
  static void error() => unawaited(play(HapticsType.error));
}

const releaseNotes = <String, List<String>>{
  '1.0.0': ['Clearer order statuses and payment steps.'],
};

Version? releaseVersion(String value) {
  try {
    return Version.parse(value);
  } on FormatException {
    return null;
  }
}

List<String> unseenChanges(String lastSeen, String current) {
  final before = releaseVersion(lastSeen), after = releaseVersion(current);
  if (before == null || after == null || after <= before) return [];
  final versions = releaseNotes.keys.map(Version.parse).toList()..sort();
  return [
    for (final version in versions)
      if (version > before && version <= after)
        ...releaseNotes[version.toString()]!,
  ];
}

Future<String> readInstalledVersion() async =>
    (await PackageInfo.fromPlatform()).version;

class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key});
  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  String? label;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => label = 'Smooch Cafe ${info.version} (${info.buildNumber})',
        );
      }
    } catch (_) {
      /* Platform metadata may be unavailable in previews. */
    }
  }

  @override
  Widget build(BuildContext context) => label == null
      ? const SizedBox.shrink()
      : Text(
          label!,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.secondaryText,
            fontFeatures: cafeNumberFeatures,
          ),
        );
}

class HorizontalEdgeFade extends StatelessWidget {
  const HorizontalEdgeFade({
    super.key,
    required this.child,
    this.fadeStart = false,
    this.fadeEnd = true,
  });
  final Widget child;
  final bool fadeStart, fadeEnd;
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) {
      final edge = bounds.width <= 0 ? 0.0 : math.min(12.0 / bounds.width, .1);
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          fadeStart ? Colors.transparent : Colors.white,
          Colors.white,
          Colors.white,
          fadeEnd ? Colors.transparent : Colors.white,
        ],
        stops: [0, edge, 1 - edge, 1],
      ).createShader(bounds);
    },
    child: child,
  );
}

class HorizontalScrollFade extends StatefulWidget {
  const HorizontalScrollFade({super.key, required this.child});
  final Widget child;
  @override
  State<HorizontalScrollFade> createState() => _HorizontalScrollFadeState();
}

class _HorizontalScrollFadeState extends State<HorizontalScrollFade> {
  bool start = false, end = false, wantedStart = false, wantedEnd = false;
  bool scheduled = false;
  void readMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) return;
    wantedStart = metrics.extentBefore > .5;
    wantedEnd = metrics.extentAfter > .5;
    if (scheduled || (start == wantedStart && end == wantedEnd)) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (!mounted || (start == wantedStart && end == wantedEnd)) return;
      setState(() {
        start = wantedStart;
        end = wantedEnd;
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          readMetrics(notification.metrics);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            readMetrics(notification.metrics);
            return false;
          },
          child: HorizontalEdgeFade(
            fadeStart: start,
            fadeEnd: end,
            child: widget.child,
          ),
        ),
      );
}

/// Local transform feedback that leaves the child's tap and focus behavior intact.
class CafePress extends StatefulWidget {
  const CafePress({
    super.key,
    required this.child,
    this.lift = false,
    this.enabled = true,
  });
  final Widget child;
  final bool lift;
  final bool enabled;
  @override
  State<CafePress> createState() => _CafePressState();
}

class _CafePressState extends State<CafePress>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController.unbounded(vsync: this, value: 1);
  bool hovering = false;
  bool pressing = false;
  bool reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      motion.stop();
      motion.value = 1;
    }
  }

  void settle() {
    if (!widget.enabled || reduced) return;
    final target = pressing
        ? .975
        : hovering && widget.lift
        ? 1.012
        : 1.0;
    motion.animateWith(
      SpringSimulation(
        CafeMotion.spring,
        motion.value,
        target,
        motion.velocity,
      ),
    );
  }

  @override
  void didUpdateWidget(CafePress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      pressing = false;
      motion.stop();
      motion.value = 1;
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      hovering = true;
      settle();
    },
    onExit: (_) {
      hovering = false;
      pressing = false;
      settle();
    },
    child: Listener(
      onPointerDown: (_) {
        pressing = true;
        settle();
      },
      onPointerUp: (_) {
        pressing = false;
        settle();
      },
      onPointerCancel: (_) {
        pressing = false;
        settle();
      },
      child: AnimatedBuilder(
        animation: motion,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            widget.lift && !reduced
                ? -math.max(0.0, motion.value - 1) * 160
                : 0,
          ),
          child: Transform.scale(
            scale: reduced ? 1 : motion.value,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// A finite entrance; the static subtree is cached throughout the animation.
class CafeReveal extends StatefulWidget {
  const CafeReveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final double delay;
  @override
  State<CafeReveal> createState() => _CafeRevealState();
}

class _CafeRevealState extends State<CafeReveal>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: CafeMotion.entrance,
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.value = 1;
      started = true;
    } else if (!started) {
      started = true;
      motion.forward();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: widget.child,
    builder: (_, child) {
      final value = Interval(
        widget.delay.clamp(0.0, .6),
        1,
        curve: Curves.easeOutCubic,
      ).transform(motion.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}

class CafeSuccessSeal extends StatefulWidget {
  const CafeSuccessSeal({super.key, this.animate = true});
  final bool animate;
  @override
  State<CafeSuccessSeal> createState() => _CafeSuccessSealState();
}

class _CafeSuccessSealState extends State<CafeSuccessSeal>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      motion.value = 1;
      started = true;
    } else if (!started) {
      started = true;
      motion.forward();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        key: const Key('order-success-seal'),
        width: 104,
        height: 104,
        child: AnimatedBuilder(
          animation: motion,
          builder: (_, _) =>
              CustomPaint(painter: _SuccessSealPainter(motion.value)),
        ),
      ),
    ),
  );
}

class _SuccessSealPainter extends CustomPainter {
  const _SuccessSealPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 104;
    canvas.save();
    canvas.scale(scale);
    final center = const Offset(52, 52);
    final settle = const Interval(
      0,
      .65,
      curve: Curves.easeOutBack,
    ).transform(progress);
    canvas.drawCircle(center, 41 * settle, Paint()..color = AppColors.softTeal);
    canvas.drawCircle(
      center,
      49,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 49),
      -math.pi / 2,
      2 * math.pi * Curves.easeOutCubic.transform(progress),
      false,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2,
    );
    final check = Path()
      ..moveTo(32, 52)
      ..lineTo(46, 66)
      ..lineTo(73, 38);
    final reveal = const Interval(
      .25,
      .9,
      curve: Curves.easeOutCubic,
    ).transform(progress);
    final measure = check.computeMetrics().first;
    canvas.drawPath(
      measure.extractPath(0, measure.length * reveal),
      Paint()
        ..color = AppColors.dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SuccessSealPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class CheckoutStepHeading extends StatelessWidget {
  const CheckoutStepHeading({
    super.key,
    required this.step,
    required this.title,
    required this.icon,
  });
  final int step;
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.softTeal,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        NumericText(
          '0$step',
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ],
    ),
  );
}

class CafeSectionHeading extends StatelessWidget {
  const CafeSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String eyebrow, title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: displayStyle(
                MediaQuery.sizeOf(context).width > 900 ? 42 : 32,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    ],
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 125});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo.png',
    width: width,
    height: width * .56,
    semanticLabel: 'Smooch Cafe',
    fit: BoxFit.contain,
  );
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.maxWidth = 1160,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.secondaryText});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color,
    ),
  );
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.highResolution = false,
  });
  final Product product;
  final BoxFit fit;
  final bool highResolution;
  static const thumbnailCacheWidth = 640;
  static final _currentImages = {
    for (final product in const MenuRepository().products)
      product.id: product.image,
  };
  static const _placeholder = ColoredBox(
    color: AppColors.softTeal,
    child: Center(
      child: Icon(Icons.coffee_outlined, size: 48, color: AppColors.teal),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Receipt snapshots may reference retired products or older PNG filenames.
    // Use the current photo by ID when available; never request a deleted asset.
    final image = _currentImages[product.id];
    if (image == null) {
      return Semantics(image: true, label: product.name, child: _placeholder);
    }
    return Image.asset(
      image,
      cacheWidth: highResolution ? 1024 : thumbnailCacheWidth,
      fit: fit,
      gaplessPlayback: true,
      semanticLabel: product.name,
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || MediaQuery.disableAnimationsOf(context)
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: CafeMotion.standard,
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (context, error, trace) => _placeholder,
    );
  }
}

Future<void> openCafeLink(BuildContext context, Uri uri) async {
  CafeHaptics.light();
  try {
    if (await launchUrl(uri)) return;
  } catch (_) {
    // Some devices have no application that can handle this link.
  }
  if (context.mounted) {
    CafeHaptics.error();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open the link. You can copy the details instead.',
        ),
      ),
    );
  }
}

class CartButton extends StatefulWidget {
  const CartButton({
    super.key,
    required this.controller,
    required this.onPressed,
    this.flightTargetKey,
  });
  final ShopController controller;
  final VoidCallback onPressed;
  final GlobalKey? flightTargetKey;

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse;
  late final Animation<double> pulseScale;
  late int previousCount;
  bool reducedMotion = false;

  @override
  void initState() {
    super.initState();
    previousCount = widget.controller.cartCount;
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
    ]).animate(pulse);
    widget.controller.addListener(onCartChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      pulse.stop();
      pulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(CartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(onCartChanged);
    previousCount = widget.controller.cartCount;
    widget.controller.addListener(onCartChanged);
  }

  void onCartChanged() {
    final count = widget.controller.cartCount;
    if (count > previousCount && !reducedMotion) pulse.forward(from: 0);
    previousCount = count;
  }

  @override
  void dispose() {
    widget.controller.removeListener(onCartChanged);
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => IconButton(
      tooltip: 'View cart',
      onPressed: () {
        CafeHaptics.light();
        widget.onPressed();
      },
      icon: ScaleTransition(
        key: const Key('cart-pulse'),
        scale: pulseScale,
        child: SizedBox(
          key: widget.flightTargetKey,
          child: Badge(
            isLabelVisible: widget.controller.cartCount > 0,
            backgroundColor: AppColors.action,
            label: NumericText(countText(widget.controller.cartCount)),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _flyProductToCart(
  BuildContext source,
  Product product,
  GlobalKey targetKey,
) {
  if (!source.mounted || MediaQuery.disableAnimationsOf(source)) {
    return Future<void>.value();
  }
  final overlay = Overlay.maybeOf(source, rootOverlay: true);
  final sourceBox = source.findRenderObject();
  final targetBox = targetKey.currentContext?.findRenderObject();
  final overlayBox = overlay?.context.findRenderObject();
  if (overlay == null ||
      sourceBox is! RenderBox ||
      targetBox is! RenderBox ||
      overlayBox is! RenderBox ||
      !sourceBox.attached ||
      !targetBox.attached ||
      !overlayBox.attached) {
    return Future<void>.value();
  }
  final start = overlayBox.globalToLocal(
    sourceBox.localToGlobal(sourceBox.size.center(Offset.zero)),
  );
  final end = overlayBox.globalToLocal(
    targetBox.localToGlobal(targetBox.size.center(Offset.zero)),
  );
  final finished = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CartFlightOverlay(
      product: product,
      start: start,
      end: end,
      onFinished: () {
        entry.remove();
        entry.dispose();
        if (!finished.isCompleted) finished.complete();
      },
    ),
  );
  overlay.insert(entry);
  return finished.future;
}

class _CartFlightOverlay extends StatefulWidget {
  const _CartFlightOverlay({
    required this.product,
    required this.start,
    required this.end,
    required this.onFinished,
  });

  final Product product;
  final Offset start;
  final Offset end;
  final VoidCallback onFinished;

  @override
  State<_CartFlightOverlay> createState() => _CartFlightOverlayState();
}

class _CartFlightOverlayState extends State<_CartFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController flight;

  @override
  void initState() {
    super.initState();
    flight =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1100),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            scheduleMicrotask(widget.onFinished);
          }
        });
    flight.forward();
  }

  @override
  void dispose() {
    flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: widget.start.dx - 34,
    top: widget.start.dy - 34,
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: flight,
        child: RepaintBoundary(
          key: Key('cart-flight-${widget.product.id}'),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: ExcludeSemantics(
                child: ProductImage(product: widget.product),
              ),
            ),
          ),
        ),
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(flight.value);
          final arc =
              math.sin(math.pi * progress) *
              math.min(80.0, (widget.start.dy - widget.end.dy).abs() * .2);
          final opacity = progress < .8 ? 1.0 : (1 - progress) / .2;
          return Transform.translate(
            offset: Offset(
              (widget.end.dx - widget.start.dx) * progress,
              (widget.end.dy - widget.start.dy) * progress - arc,
            ),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 - (52 / 68) * progress,
                child: Transform.rotate(angle: progress * .22, child: child),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class QuantityPicker extends StatelessWidget {
  const QuantityPicker({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: onDecrease == null
              ? null
              : () {
                  CafeHaptics.selection();
                  onDecrease!();
                },
          icon: const Icon(Icons.remove, size: 18),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 28),
          child: NumericText(
            countText(quantity),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: () {
            CafeHaptics.selection();
            onIncrease();
          },
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColors.teal),
        const SizedBox(height: 20),
        Text(title, style: displayStyle(28), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.7),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

// ============================================================
// 3D SPLASH SCREEN AND MENU TRANSITION
// ============================================================
class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.controller, this.versionReader});

  final ShopController controller;
  final Future<String> Function()? versionReader;
  static const duration = Duration(milliseconds: 2400);
  static const transitionDuration = Duration(milliseconds: 600);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  late final AnimationController _idle;
  bool? _reducedMotion;
  bool _leaving = false;
  bool _foreground = true;
  bool _checkedReleaseNotes = false;
  Timer? _preloadTimer;
  List<String> _warmAssets = const [];
  int _nextWarmAsset = 0;
  bool _warmingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
      animationBehavior: AnimationBehavior.preserve,
    );
    _animation =
        AnimationController(
          vsync: this,
          duration: StartScreen.duration,
          animationBehavior: AnimationBehavior.preserve,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _syncMotion();
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prepareMenuImages();
      unawaited(_checkReleaseNotes());
    });
  }

  bool get _canWarmImages =>
      mounted &&
      _foreground &&
      !_leaving &&
      ModalRoute.of(context)?.isCurrent != false;

  void _prepareMenuImages() {
    final shop = widget.controller;
    // Match the first carousel cards and the current filtered/sorted grid.
    // Six unique thumbnails are enough for the initial menu preview; lazy
    // grid/page builders resolve the remaining images as users browse.
    final initialImages = <String>{
      if (shop.category == 'All' && shop.query.trim().isEmpty)
        ...shop.products
            .where((product) => product.featured)
            .take(2)
            .map((product) => product.image),
      ...shop.filteredProducts.take(6).map((product) => product.image),
    };
    _warmAssets = initialImages.take(6).toList(growable: false);
    _nextWarmAsset = 0;
    _scheduleImageWarmup();
  }

  void _scheduleImageWarmup() {
    if (!_canWarmImages ||
        _warmingImage ||
        _preloadTimer?.isActive == true ||
        _nextWarmAsset >= _warmAssets.length) {
      return;
    }
    _preloadTimer = Timer(
      const Duration(milliseconds: 16),
      () => unawaited(_warmNextImage()),
    );
  }

  void _pauseImageWarmup() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
  }

  Future<void> _warmNextImage() async {
    if (!_canWarmImages ||
        _warmingImage ||
        _nextWarmAsset >= _warmAssets.length) {
      return;
    }
    final path = _warmAssets[_nextWarmAsset++];
    _warmingImage = true;
    try {
      await precacheImage(
        ResizeImage.resizeIfNeeded(
          ProductImage.thumbnailCacheWidth,
          null,
          AssetImage(path),
        ),
        context,
        onError: (Object _, StackTrace? _) {},
      );
    } finally {
      // A started decode may finish after navigation; never queue more work
      // unless this route is visible and the app is in the foreground.
      _warmingImage = false;
      _scheduleImageWarmup();
    }
  }

  Future<void> _checkReleaseNotes() async {
    if (_checkedReleaseNotes || !mounted) return;
    _checkedReleaseNotes = true;
    try {
      final current = await (widget.versionReader ?? readInstalledVersion)();
      final prefs = await SharedPreferences.getInstance();
      const key = 'smooch_last_seen_version';
      final last = prefs.getString(key);
      if (last == null) {
        await prefs.setString(key, current);
        return;
      }
      final before = releaseVersion(last), after = releaseVersion(current);
      if (after == null || (before != null && after <= before)) return;
      final notes = unseenChanges(last, current);
      if (notes.isEmpty) {
        await prefs.setString(key, current);
        return;
      }
      if (!mounted || _leaving || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('What’s new'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(note),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      await prefs.setString(key, current);
    } catch (_) {
      /* Release notes never block ordering. */
    } finally {
      _scheduleImageWarmup();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduceMotion) return;
    _reducedMotion = reduceMotion;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground != foreground) {
      setState(() => _foreground = foreground);
    }
    if (foreground) {
      _scheduleImageWarmup();
    } else {
      _pauseImageWarmup();
    }
    _syncMotion();
  }

  void _syncMotion() {
    if (_reducedMotion == true) {
      _animation.stop();
      _idle.stop();
      if (_animation.value != 1) _animation.value = 1;
    } else if (_reducedMotion != false || _leaving || !_foreground) {
      _animation.stop();
      _idle.stop();
    } else if (_animation.isCompleted) {
      if (!_idle.isAnimating) _idle.repeat();
    } else if (!_animation.isAnimating) {
      _animation.forward();
    }
  }

  Future<void> _openMenu() async {
    if (!mounted || _leaving) return;
    CafeHaptics.light();
    setState(() => _leaving = true);
    _pauseImageWarmup();
    _syncMotion();
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: MenuScreen.routeName),
          builder: (_) => MenuScreen(controller: widget.controller),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
        _prepareMenuImages();
        _syncMotion();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseImageWarmup();
    _animation.dispose();
    _idle.dispose();
    super.dispose();
  }

  Widget coffeeScene(double height) => SizedBox(
    width: 500,
    height: height,
    child: RepaintBoundary(
      child: Semantics(
        label: 'A floating Smooch Cafe cup with coffee beans and rising steam',
        image: true,
        hint: _reducedMotion == true
            ? null
            : 'Drag left or right to turn the cup.',
        child: ExcludeSemantics(
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 20,
                child: CoffeeSceneViewport(
                  entrance: _animation,
                  idle: _idle,
                  reducedMotion: _reducedMotion ?? false,
                  active: !_leaving && _foreground,
                ),
              ),
              if (_reducedMotion == false)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Text(
                      'DRAG TO EXPLORE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget introduction(bool wide, bool compact) => Column(
    crossAxisAlignment: wide
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    children: [
      Text(
        'A little magic.',
        textAlign: wide ? TextAlign.start : TextAlign.center,
        style: displayStyle(
          wide
              ? 46
              : compact
              ? 31
              : 38,
          color: AppColors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'A lot of Smooch.',
        textAlign: wide ? TextAlign.start : TextAlign.center,
        style: displayStyle(
          wide
              ? 46
              : compact
              ? 31
              : 38,
          color: AppColors.coral,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Handcrafted sips. Comforting bites.\nYour daily dose of happy starts here.',
        textAlign: wide ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.muted,
        ),
      ),
    ],
  );

  Widget orderAction() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: SizedBox(
      width: double.infinity,
      child: CafePress(
        enabled: !_leaving,
        child: FilledButton.icon(
          key: const Key('enter-store'),
          onPressed: _leaving ? null : _openMenu,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('ORDER NOW'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.dark,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.15),
          radius: .85,
          colors: [AppColors.teal, AppColors.dark, Color(0xFF062E35)],
          stops: [0, .57, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 850 &&
                MediaQuery.textScalerOf(context).scale(14) < 23;
            final compact = constraints.maxHeight < 740;
            final sceneHeight = wide
                ? 460.0
                : (constraints.maxHeight * (compact ? .34 : .39)).clamp(
                    160.0,
                    340.0,
                  );
            final bottomSpace = BottomPadding.of(context, minimum: 20);
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomSpace),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0.0, constraints.maxHeight - bottomSpace),
                ),
                child: ContentWidth(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SMOOCH CAFE · CARMONA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.8,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: wide ? 32 : 18),
                      if (wide)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const BrandLogo(width: 178),
                                  const SizedBox(height: 28),
                                  introduction(true, false),
                                  const SizedBox(height: 32),
                                  orderAction(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(child: coffeeScene(sceneHeight)),
                          ],
                        )
                      else ...[
                        BrandLogo(width: compact ? 142 : 164),
                        coffeeScene(sceneHeight),
                        introduction(false, compact),
                        const SizedBox(height: 28),
                        orderAction(),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'COFFEE. COMFORT. CONNECTION.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _MenuTransition extends StatelessWidget {
  const _MenuTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: RepaintBoundary(child: child),
    builder: (context, menu) {
      // Finish covering the splash before the menu appears, avoiding ghosted
      // cup/text over the product grid during the MaterialPageRoute transition.
      final cover = const Interval(
        0,
        .4,
        curve: Curves.easeInOutCubic,
      ).transform(animation.value);
      final reveal = const Interval(
        .4,
        1,
        curve: Curves.easeInOutCubic,
      ).transform(animation.value);
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            key: const Key('splash-fade-cover'),
            opacity: cover,
            child: const ColoredBox(color: AppColors.dark),
          ),
          ExcludeSemantics(
            excluding: animation.value < 1,
            child: IgnorePointer(
              ignoring: animation.value < 1,
              child: Opacity(
                key: const Key('menu-reveal'),
                opacity: reveal,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - reveal)),
                  child: menu,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ============================================================
// MENU SCREEN
// ============================================================
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.controller});
  static const routeName = '/menu';
  final ShopController controller;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  int tab = 0;
  final cartFlightTarget = GlobalKey();
  final search = TextEditingController();
  final menuSearchFocus = FocusNode();
  final orderScroll = ScrollController();
  final cafeScroll = ScrollController();
  final categoryScrolls = List.generate(
    ShopController.categories.length,
    (_) => ScrollController(),
  );
  final featuredPages = PageController(viewportFraction: .9);
  late TabController categoryTabs;
  bool? reducedCategoryMotion;
  int featuredIndex = 0;
  ShopController get shop => widget.controller;

  @override
  void initState() {
    super.initState();
    search.text = shop.query;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reducedCategoryMotion == reduced) return;
    final previousIndex = reducedCategoryMotion == null
        ? ShopController.categories.indexOf(shop.category)
        : categoryTabs.index;
    if (reducedCategoryMotion != null) {
      categoryTabs.removeListener(onCategoryPageChanged);
      categoryTabs.dispose();
    }
    categoryTabs = TabController(
      length: ShopController.categories.length,
      initialIndex: previousIndex,
      animationDuration: reduced
          ? Duration.zero
          : const Duration(milliseconds: 320),
      vsync: this,
    );
    categoryTabs.addListener(onCategoryPageChanged);
    if (reducedCategoryMotion == null) shop.addListener(syncCategoryTabs);
    reducedCategoryMotion = reduced;
  }

  @override
  void dispose() {
    search.dispose();
    menuSearchFocus.dispose();
    if (reducedCategoryMotion != null) {
      shop.removeListener(syncCategoryTabs);
      categoryTabs.removeListener(onCategoryPageChanged);
      categoryTabs.dispose();
    }
    featuredPages.dispose();
    orderScroll.dispose();
    cafeScroll.dispose();
    for (final scroll in categoryScrolls) {
      scroll.dispose();
    }
    super.dispose();
  }

  void openCart() {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/bag'),
        builder: (_) => CartScreen(controller: shop),
      ),
    );
  }

  void selectTab(int value) {
    if (value < 0 || value > 2) return;
    CafeTitleScope.of(context)?.selectMenuTab(value);
    CafeHaptics.light();
    if (value == tab) {
      final scroll = activePrimaryScroll;
      if (scroll.hasClients && scroll.offset > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (MediaQuery.disableAnimationsOf(context)) {
          scroll.jumpTo(0);
        } else {
          unawaited(
            scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          );
        }
      } else if (tab == 0) {
        menuSearchFocus.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => tab = value);
  }

  ScrollController get activePrimaryScroll => switch (tab) {
    0 => categoryScrolls[categoryTabs.index],
    1 => orderScroll,
    _ => cafeScroll,
  };

  void resetPosition() {
    final scroll = categoryScrolls[categoryTabs.index];
    if (scroll.hasClients && scroll.offset > 0) scroll.jumpTo(0);
  }

  void syncCategoryTabs() {
    final index = ShopController.categories.indexOf(shop.category);
    if (!mounted || index < 0 || categoryTabs.index == index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      categoryTabs.index = index;
    } else {
      categoryTabs.animateTo(index);
    }
  }

  void onCategoryPageChanged() {
    if (categoryTabs.indexIsChanging) return;
    // Let TabBar.onTap finish first when a zero-duration accessibility change
    // notifies listeners synchronously; swipes still commit on settle.
    scheduleMicrotask(() {
      if (!mounted) return;
      final category = ShopController.categories[categoryTabs.index];
      if (shop.category != category) {
        CafeHaptics.selection();
        shop.selectCategory(category);
      }
    });
  }

  void selectCategory(String category) {
    if (!ShopController.categories.contains(category)) return;
    final target = category;
    FocusManager.instance.primaryFocus?.unfocus();
    final index = ShopController.categories.indexOf(target);
    if (MediaQuery.disableAnimationsOf(context)) {
      categoryTabs.index = index;
    } else {
      categoryTabs.animateTo(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    if (shop.category != target) {
      CafeHaptics.light();
      shop.selectCategory(target);
    }
  }

  void queryChanged(String query) {
    shop.search(query);
    resetPosition();
  }

  void resetFilters() {
    CafeHaptics.selection();
    FocusManager.instance.primaryFocus?.unfocus();
    search.clear();
    shop.resetFilters();
    if (MediaQuery.disableAnimationsOf(context)) {
      categoryTabs.index = 0;
    } else {
      categoryTabs.animateTo(0);
    }
    resetPosition();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= 900 &&
          MediaQuery.textScalerOf(context).scale(14) <= 18;
      final padding = wide ? 24.0 : 16.0;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final searchHeight = math.max(56.0, 14 * scale + 32);
      return ListenableBuilder(
        listenable: shop,
        builder: (context, _) {
          final endInset = wide && shop.cartCount == 0
              ? BottomPadding.of(context, minimum: 0)
              : 0.0;
          return PrimaryScrollController(
            controller: activePrimaryScroll,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: 72,
                titleSpacing: 0,
                title: ContentWidth(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        IconButton(
                          tooltip: 'Back to start',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const BrandLogo(width: 112),
                      const Spacer(),
                      if (wide) ...[
                        for (final entry in [
                          'Our menu',
                          'Order history',
                          'Discover',
                        ].asMap().entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TextButton(
                              onPressed: () => selectTab(entry.key),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.white,
                                backgroundColor: tab == entry.key
                                    ? AppColors.white.withValues(alpha: .12)
                                    : null,
                                minimumSize: const Size(80, 48),
                              ),
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 20),
                      ],
                      CartButton(
                        controller: shop,
                        onPressed: openCart,
                        flightTargetKey: cartFlightTarget,
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: (wide && shop.cartCount == 0)
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (shop.cartCount > 0)
                          _BagSummary(
                            controller: shop,
                            onPressed: openCart,
                            bottomSafeArea: wide,
                          ),
                        if (!wide)
                          NavigationBar(
                            selectedIndex: tab,
                            onDestinationSelected: selectTab,
                            height: 72,
                            destinations: const [
                              NavigationDestination(
                                icon: Icon(Icons.grid_view_outlined),
                                selectedIcon: Icon(
                                  Icons.grid_view_rounded,
                                  color: AppColors.dark,
                                ),
                                label: 'Our menu',
                              ),
                              NavigationDestination(
                                icon: Icon(Icons.receipt_long_outlined),
                                selectedIcon: Icon(
                                  Icons.receipt_long,
                                  color: AppColors.dark,
                                ),
                                label: 'Order history',
                              ),
                              NavigationDestination(
                                icon: Icon(Icons.explore_outlined),
                                selectedIcon: Icon(
                                  Icons.explore,
                                  color: AppColors.dark,
                                ),
                                label: 'Discover',
                              ),
                            ],
                          ),
                      ],
                    ),
              body: tab == 0
                  ? Column(
                      children: [
                        Material(
                          color: AppColors.canvas,
                          child: MenuFilters(
                            controller: shop,
                            search: search,
                            searchFocus: menuSearchFocus,
                            onQuery: queryChanged,
                            onCategory: selectCategory,
                            tabs: categoryTabs,
                            horizontalPadding: padding,
                            searchHeight: searchHeight,
                          ),
                        ),
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                              },
                            ),
                            child: TabBarView(
                              key: const Key('menu-category-pages'),
                              controller: categoryTabs,
                              physics: const PageScrollPhysics(),
                              children: [
                                for (
                                  var index = 0;
                                  index < ShopController.categories.length;
                                  index++
                                )
                                  _MenuCategoryPage(
                                    key: PageStorageKey(
                                      'menu-category-${ShopController.categories[index]}',
                                    ),
                                    category: ShopController.categories[index],
                                    products: shop.productsForCategory(
                                      ShopController.categories[index],
                                    ),
                                    controller: shop,
                                    scroll: categoryScrolls[index],
                                    width: constraints.maxWidth,
                                    horizontalPadding: padding,
                                    wide: wide,
                                    endInset: endInset,
                                    featuredPages: featuredPages,
                                    featuredIndex: featuredIndex,
                                    onFeaturedPageChanged: (value) =>
                                        setState(() => featuredIndex = value),
                                    onReset: resetFilters,
                                    onSort: (value) {
                                      shop.sortBy(value);
                                      resetPosition();
                                    },
                                    onDiscover: () => selectTab(2),
                                    onSearchAll: () => selectCategory('All'),
                                    onClearSearch: () {
                                      search.clear();
                                      queryChanged('');
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : tab == 1
                  ? Column(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your orders',
                                      style: displayStyle(32),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Find past orders and view the details.',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _OrderHistoryContent(
                            controller: shop,
                            onBrowseMenu: () => selectTab(0),
                            scroll: orderScroll,
                            endInset: endInset,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      key: const PageStorageKey('menu-tab-cafe'),
                      controller: cafeScroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: ContentWidth(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                bottom: 14,
                              ),
                              child: CafeSection(
                                products: shop.products,
                                onBrowse: () => selectTab(0),
                                onCategory: (category) {
                                  selectTab(0);
                                  search.clear();
                                  queryChanged('');
                                  selectCategory(category);
                                  resetPosition();
                                },
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: math.max(24.0, endInset)),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    },
  );
}

class _MenuCategoryPage extends StatelessWidget {
  const _MenuCategoryPage({
    super.key,
    required this.category,
    required this.products,
    required this.controller,
    required this.scroll,
    required this.width,
    required this.horizontalPadding,
    required this.wide,
    this.endInset = 0,
    required this.featuredPages,
    required this.featuredIndex,
    required this.onFeaturedPageChanged,
    required this.onReset,
    required this.onSort,
    required this.onSearchAll,
    required this.onClearSearch,
    required this.onDiscover,
  });

  final String category;
  final List<Product> products;
  final ShopController controller;
  final ScrollController scroll;
  final double width;
  final double horizontalPadding;
  final bool wide;
  final double endInset;
  final PageController featuredPages;
  final int featuredIndex;
  final ValueChanged<int> onFeaturedPageChanged;
  final VoidCallback onReset;
  final ValueChanged<MenuSort> onSort;
  final VoidCallback onSearchAll;
  final VoidCallback onClearSearch;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final showFeatured = category == 'All' && controller.query.trim().isEmpty;
    return CustomScrollView(
      key: PageStorageKey('products-$category'),
      controller: scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (showFeatured) ...[
          SliverToBoxAdapter(
            child: ContentWidth(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 24),
                child: CafeReveal(
                  child: CafeSectionHeading(
                    eyebrow: 'SMOOCH CAFE · CARMONA',
                    title: MediaQuery.textScalerOf(context).scale(14) > 20
                        ? 'Your menu.'
                        : 'Good days start here.',
                    subtitle: MediaQuery.textScalerOf(context).scale(14) > 20
                        ? null
                        : 'Your favorite sip. A comforting bite. A little Smooch.',
                    trailing: wide
                        ? CafePress(
                            child: OutlinedButton.icon(
                              onPressed: onDiscover,
                              icon: const Icon(
                                Icons.explore_outlined,
                                size: 18,
                              ),
                              label: const Text('Discover Smooch'),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _FeaturedCarousel(
              controller: controller,
              pages: featuredPages,
              currentPage: featuredIndex,
              onPageChanged: onFeaturedPageChanged,
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: ContentWidth(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.query.trim().isNotEmpty
                              ? 'Search results'
                              : category == 'All'
                              ? 'Explore the menu'
                              : category,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${countText(products.length)} ${products.length == 1 ? 'item' : 'items'}${controller.query.trim().isNotEmpty ? ' for “${controller.query.trim()}”' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.hasActiveFilters) ...[
                    TextButton(
                      key: const Key('reset-menu-filters'),
                      onPressed: onReset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.teal,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  PopupMenuButton<MenuSort>(
                    tooltip: 'Sort menu',
                    onOpened: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    initialValue: controller.sort,
                    onSelected: (value) {
                      if (controller.sort != value) CafeHaptics.selection();
                      onSort(value);
                    },
                    itemBuilder: (_) => [
                      for (final sort in MenuSort.values)
                        CheckedPopupMenuItem(
                          value: sort,
                          checked: controller.sort == sort,
                          child: Text(sort.label),
                        ),
                    ],
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_vert, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            wide
                                ? controller.sort.label
                                : switch (controller.sort) {
                                    MenuSort.recommended => 'Sort',
                                    MenuSort.priceLow => 'Price ↑',
                                    MenuSort.priceHigh => 'Price ↓',
                                    MenuSort.name => 'A–Z',
                                  },
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matches found.',
              message: category == 'All'
                  ? 'Try another name or clear your search.'
                  : 'Nothing matched in $category. Try searching all categories.',
              action: OutlinedButton(
                onPressed: category == 'All' ? onClearSearch : onSearchAll,
                child: Text(
                  category == 'All' ? 'Clear search' : 'Search all categories',
                ),
              ),
            ),
          )
        else
          _ProductGridSliver(
            products: products,
            controller: controller,
            width: width,
            horizontalPadding: horizontalPadding,
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, math.max(32.0, endInset)),
            child: const Center(
              child: Text(
                'A little Smooch goes a long way.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductGridSliver extends StatelessWidget {
  const _ProductGridSliver({
    required this.products,
    required this.controller,
    required this.width,
    required this.horizontalPadding,
  });
  final List<Product> products;
  final ShopController controller;
  final double width;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: math.max(0, (width - 1160) / 2) + horizontalPadding,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, gridConstraints) {
          final gridWidth = gridConstraints.crossAxisExtent;
          final columns = scale > 1.3
              ? math.max(1, (gridWidth / (240 * scale)).floor()).clamp(1, 4)
              : gridWidth >= 1040
              ? 5
              : gridWidth >= 900
              ? 4
              : gridWidth >= 700
              ? 3
              : gridWidth >= 300
              ? 2
              : 1;
          final cardWidth = (gridWidth - 12 * (columns - 1)) / columns;
          return SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: math.min(cardWidth * .76, 176) + 144 * scale,
            ),
            itemBuilder: (_, index) => ProductCard(
              key: ValueKey(products[index].id),
              product: products[index],
              controller: controller,
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({
    required this.controller,
    required this.pages,
    required this.currentPage,
    required this.onPageChanged,
  });
  final ShopController controller;
  final PageController pages;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  @override
  Widget build(BuildContext context) {
    final featured = controller.products
        .where((item) => item.featured)
        .take(5)
        .toList();
    if (featured.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Eyebrow('SMOOCH PICKS · SWIPE TO FIND YOUR FAVORITE'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 224 * scale.clamp(1, 1.8),
                child: HorizontalScrollFade(
                  child: PageView.builder(
                    key: const Key('featured-carousel'),
                    controller: pages,
                    itemCount: featured.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) => AnimatedBuilder(
                      animation: pages,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _FeaturedCard(
                          product: featured[index],
                          controller: controller,
                          index: index,
                        ),
                      ),
                      builder: (context, child) {
                        final page =
                            pages.hasClients &&
                                pages.position.hasContentDimensions
                            ? pages.page ?? currentPage.toDouble()
                            : currentPage.toDouble();
                        final distance = (page - index).abs().clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: reduced ? 1 : 1 - distance * .045,
                          alignment: Alignment.centerLeft,
                          child: child,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < featured.length; index++)
                    AnimatedContainer(
                      duration: CafeMotion.of(context, CafeMotion.standard),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == currentPage ? 24 : 6,
                      height: 5,
                      decoration: BoxDecoration(
                        color: index == currentPage
                            ? AppColors.teal
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  const SizedBox(width: 14),
                  ExcludeSemantics(
                    child: NumericText(
                      '${currentPage + 1} / ${featured.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.product,
    required this.controller,
    required this.index,
  });
  final Product product;
  final ShopController controller;
  final int index;
  @override
  Widget build(BuildContext context) => CafePress(
    lift: true,
    child: Material(
      color: AppColors.dark,
      borderRadius: BorderRadius.circular(CafeShape.panel),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('featured-${product.id}'),
        onTap: () {
          CafeHaptics.light();
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: RouteSettings(
                name: '/details',
                arguments: product.name,
              ),
              builder: (_) => ProductDetailsScreen(
                product: product,
                controller: controller,
              ),
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 500;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: compact ? 57 : 51,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 12,
                        top: 5,
                        child: ExcludeSemantics(
                          child: Text(
                            '0${index + 1}',
                            style: displayStyle(
                              compact ? 76 : 112,
                              color: AppColors.white.withValues(alpha: .055),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(compact ? 18 : 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow(
                              'THE CAFE PICKS',
                              color: AppColors.gold,
                            ),
                            const Spacer(),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: displayStyle(
                                compact ? 25 : 34,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.subcategory,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            NumericText(
                              pesos(product.price),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: compact ? 43 : 49,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(product: product),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _AnimatedAddButton(
                          key: ValueKey('featured-${product.id}'),
                          product: product,
                          controller: controller,
                          iconOnly: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _BagSummary extends StatelessWidget {
  const _BagSummary({
    required this.controller,
    required this.onPressed,
    required this.bottomSafeArea,
  });
  final ShopController controller;
  final VoidCallback onPressed;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      bottom: bottomSafeArea,
      child: ContentWidth(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Semantics(
          liveRegion: true,
          child: FilledButton(
            key: const Key('view-bag-summary'),
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dark,
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: NumericText(
                    countText(controller.cartCount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'View bag',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                NumericText(
                  pesos(controller.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// SEARCH AND CATEGORY FILTER CONTROLS
// ============================================================
class MenuFilters extends StatelessWidget {
  const MenuFilters({
    super.key,
    required this.controller,
    required this.search,
    required this.onQuery,
    required this.onCategory,
    required this.tabs,
    required this.horizontalPadding,
    required this.searchHeight,
    this.searchFocus,
  });

  final ShopController controller;
  final TextEditingController search;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onCategory;
  final TabController tabs;
  final double horizontalPadding;
  final double searchHeight;
  final FocusNode? searchFocus;

  @override
  Widget build(BuildContext context) => ContentWidth(
    padding: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: searchHeight,
              child: TextField(
                key: const Key('menu-search'),
                controller: search,
                focusNode: searchFocus,
                onChanged: onQuery,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: 'Search drinks, food or pastries',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: controller.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            search.clear();
                            onQuery('');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: HorizontalScrollFade(
              child: TabBar(
                key: const Key('category-filters'),
                controller: tabs,
                isScrollable: true,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorPadding: const EdgeInsets.symmetric(vertical: 5),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 17),
                onTap: (index) => onCategory(ShopController.categories[index]),
                tabs: [
                  for (final category in ShopController.categories)
                    Tab(key: Key('category-$category'), text: category),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// PRODUCT CARD
// ============================================================
class _AnimatedAddButton extends StatefulWidget {
  const _AnimatedAddButton({
    super.key,
    required this.product,
    required this.controller,
    this.shortLabel = false,
    this.iconOnly = false,
  });

  final Product product;
  final ShopController controller;
  final bool shortLabel;
  final bool iconOnly;

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton> {
  Timer? resetTimer;
  Timer? pressTimer;
  bool added = false;
  bool pressed = false;

  @override
  void didUpdateWidget(_AnimatedAddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id) return;
    resetTimer?.cancel();
    pressTimer?.cancel();
    added = false;
    pressed = false;
  }

  void addProduct() {
    final previousCount = widget.controller.cartCount;
    widget.controller.addToCart(widget.product);
    if (widget.controller.cartCount == previousCount) return;
    CafeHaptics.light();
    final targetKey = context
        .findAncestorStateOfType<_MenuScreenState>()
        ?.cartFlightTarget;
    if (targetKey != null) {
      unawaited(_flyProductToCart(context, widget.product, targetKey));
    }
    resetTimer?.cancel();
    pressTimer?.cancel();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      added = true;
      pressed = !reduceMotion;
    });
    if (!reduceMotion) {
      pressTimer = Timer(const Duration(milliseconds: 110), () {
        if (mounted) setState(() => pressed = false);
      });
    }
    resetTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => added = false);
    });
  }

  @override
  void dispose() {
    resetTimer?.cancel();
    pressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colorDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final scaleDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 110);
    return Tooltip(
      message: added
          ? 'Add another ${widget.product.name} to bag'
          : 'Add ${widget.product.name} to bag',
      child: AnimatedScale(
        key: Key(
          widget.iconOnly
              ? 'featured-add-feedback-${widget.product.id}'
              : 'add-feedback-${widget.product.id}',
        ),
        scale: reduceMotion ? 1 : (pressed ? .96 : 1),
        duration: scaleDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: colorDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.iconOnly
                ? added
                      ? AppColors.teal
                      : AppColors.softTeal
                : added
                ? AppColors.teal
                : AppColors.action,
            borderRadius: BorderRadius.circular(widget.iconOnly ? 30 : 12),
          ),
          child: widget.iconOnly
              ? IconButton(
                  key: Key('featured-add-${widget.product.id}'),
                  onPressed: addProduct,
                  icon: AnimatedSwitcher(
                    duration: colorDuration,
                    child: Icon(
                      added ? Icons.check : Icons.add,
                      key: ValueKey(added),
                      size: 18,
                      color: added ? AppColors.white : AppColors.dark,
                    ),
                  ),
                )
              : FilledButton(
                  key: Key('add-${widget.product.id}'),
                  onPressed: addProduct,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    minimumSize: const Size(68, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: colorDuration,
                    child: Row(
                      key: ValueKey(added),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!added || !widget.shortLabel) ...[
                          Icon(added ? Icons.check : Icons.add, size: 17),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          added
                              ? 'Added'
                              : widget.shortLabel
                              ? 'Add'
                              : 'Add to bag',
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
  });
  final Product product;
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    final quantity = controller.quantityOf(product);
    return CafePress(
      lift: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CafeShape.card),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('product-${product.id}'),
          onTap: () {
            CafeHaptics.light();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: RouteSettings(
                  name: '/details',
                  arguments: product.name,
                ),
                builder: (_) => ProductDetailsScreen(
                  product: product,
                  controller: controller,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(product: product),
                    if (product.featured)
                      Positioned(
                        left: 10,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Smooch pick',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                      ),
                    if (quantity > 0)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${countText(quantity)} in bag',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.subcategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(15) * 2.7,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final scale =
                            MediaQuery.textScalerOf(context).scale(13) / 13;
                        final stacked = constraints.maxWidth < 150 * scale;
                        final price = NumericText(
                          pesos(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        );
                        final add = _AnimatedAddButton(
                          product: product,
                          controller: controller,
                          shortLabel: constraints.maxWidth < 230 * scale,
                        );
                        if (stacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              price,
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: add),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: price),
                            const SizedBox(width: 8),
                            add,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT DETAILS SCREEN
// ============================================================
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.controller,
  });
  final Product product;
  final ShopController controller;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  bool adding = false;
  final cartFlightTarget = GlobalKey();

  Future<void> addToCart(BuildContext buttonContext) async {
    if (adding) return;
    final addedQuantity = quantity;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => adding = true);
    final before = widget.controller.cartCount;
    widget.controller.addToCart(widget.product, quantity: addedQuantity);
    if (widget.controller.cartCount == before) {
      setState(() => adding = false);
      return;
    }
    CafeHaptics.light();
    await _flyProductToCart(buttonContext, widget.product, cartFlightTarget);
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      setState(() => adding = false);
      return;
    }
    navigator.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${countText(addedQuantity)} × ${widget.product.name} added to your bag.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Product details', style: TextStyle(fontSize: 16)),
      actions: [
        CartButton(
          controller: widget.controller,
          flightTargetKey: cartFlightTarget,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/bag'),
              builder: (_) => CartScreen(controller: widget.controller),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: wide ? 1 : 0,
                    child: CafeReveal(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AspectRatio(
                          aspectRatio: wide ? 1 : 1.1,
                          child: ProductImage(
                            product: widget.product,
                            highResolution: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 44 : 0, height: wide ? 0 : 28),
                  Flexible(
                    flex: wide ? 1 : 0,
                    child: CafeReveal(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(widget.product.subcategory),
                          const SizedBox(height: 12),
                          Text(widget.product.name, style: displayStyle(38)),
                          const SizedBox(height: 18),
                          NumericText(
                            pesos(widget.product.price),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 18),
                          const Text(
                            'About this item',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.description,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              height: 1.7,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Icon(
                                Icons.local_cafe_outlined,
                                color: AppColors.action,
                                size: 15,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Made with love at Smooch Cafe.',
                                  softWrap: true,
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
    bottomNavigationBar: Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: ContentWidth(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final picker = Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  QuantityPicker(
                    quantity: quantity,
                    onDecrease: quantity > 1 && !adding
                        ? () => setState(() => quantity--)
                        : null,
                    onIncrease: () {
                      if (!adding) setState(() => quantity++);
                    },
                  ),
                ],
              );
              final button = Builder(
                builder: (buttonContext) => CafePress(
                  enabled: !adding,
                  child: FilledButton.icon(
                    key: const Key('details-add-to-cart'),
                    onPressed: adding ? null : () => addToCart(buttonContext),
                    icon: Icon(
                      adding ? Icons.check : Icons.shopping_bag_outlined,
                      size: 18,
                    ),
                    label: NumericText(
                      adding
                          ? 'Added to bag'
                          : 'Add to bag • ${pesos(widget.product.price * quantity)}',
                    ),
                  ),
                ),
              );
              if (constraints.maxWidth >= 650) {
                return Row(children: [picker, const Spacer(), button]);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  picker,
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: button),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// CART SCREEN
// ============================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.controller});
  final ShopController controller;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  ShopController get controller => widget.controller;
  List<CartItem> get items => controller.cartItems;
  int get itemCount => controller.cartCount;
  int get orderTotal => controller.total;

  void _openCheckout() {
    if (items.isEmpty) return;
    CafeHaptics.light();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/checkout'),
        builder: (_) => CheckoutScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Your bag', style: TextStyle(fontSize: 16)),
      ),
      body: items.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: BottomPadding.of(context, minimum: 24),
                ),
                child: EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'A little empty, for now.',
                  message:
                      'Your next favorite sip or bite is waiting on the menu.',
                  action: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Explore the menu'),
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ContentWidth(
                    maxWidth: 760,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28, bottom: 24),
                      child: CafeReveal(
                        child: CafeSectionHeading(
                          eyebrow: 'GOOD THINGS, ALL TOGETHER',
                          title: 'A bag full of happy.',
                          subtitle:
                              '${countText(itemCount)} ${itemCount == 1 ? 'item' : 'items'} picked by you. One lovely order.',
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ContentWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CartRow(item: item, controller: controller),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : ColoredBox(
              color: AppColors.surface,
              child: SafeArea(
                child: ContentWidth(
                  maxWidth: 760,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16)),
                            NumericText(
                              pesos(orderTotal),
                              key: const Key('cart-total'),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No order is sent to the cafe.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: CafePress(
                            child: FilledButton.icon(
                              key: const Key('open-checkout'),
                              onPressed: _openCheckout,
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Continue to checkout'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.controller});
  final CartItem item;
  final ShopController controller;

  void removeWithUndo(BuildContext context) {
    if (controller.placingOrder) return;
    controller.remove(item.product);
    CafeHaptics.light();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${item.product.name} removed from your bag.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            CafeHaptics.light();
            controller.addToCart(item.product, quantity: item.quantity);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 450;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: compact ? 68 : 100,
                    height: compact ? 80 : 100,
                    child: ProductImage(product: item.product),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.subcategory.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NumericText(
                        '${pesos(item.product.price)} each',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${item.product.name}',
                  onPressed: () => removeWithUndo(context),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                QuantityPicker(
                  quantity: item.quantity,
                  onDecrease: () => item.quantity == 1
                      ? removeWithUndo(context)
                      : controller.decrease(item.product),
                  onIncrease: () => controller.addToCart(item.product),
                ),
                NumericText(
                  pesos(item.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

// ============================================================
// SAVED ORDERS
// ============================================================
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key, required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Your orders', style: TextStyle(fontSize: 16)),
    ),
    body: _OrderHistoryContent(
      controller: controller,
      onBrowseMenu: () => Navigator.pop(context),
    ),
  );
}

class _OrderHistoryContent extends StatelessWidget {
  const _OrderHistoryContent({
    required this.controller,
    required this.onBrowseMenu,
    this.scroll,
    this.endInset,
  });

  final ShopController controller;
  final VoidCallback onBrowseMenu;
  final ScrollController? scroll;
  final double? endInset;
  double bottomPadding(BuildContext context) => endInset == null
      ? BottomPadding.of(context, minimum: 24)
      : math.max(24.0, endInset!);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) =>
        controller.loadingOrders && controller.orders.isEmpty
        ? const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading orders'),
          )
        : controller.historyError != null && controller.orders.isEmpty
        ? Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding(context)),
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Orders are unavailable.',
                message: controller.historyError!,
                action: OutlinedButton(
                  key: const Key('retry-order-history'),
                  onPressed: () => unawaited(
                    controller
                        .restoreOrders(retry: true)
                        .catchError((Object _) => CafeHaptics.error()),
                  ),
                  child: const Text('Try again'),
                ),
              ),
            ),
          )
        : controller.orders.isEmpty
        ? Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding(context)),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet.',
                message: 'Your saved orders will appear here.',
                action: FilledButton(
                  onPressed: onBrowseMenu,
                  child: const Text('Browse the menu'),
                ),
              ),
            ),
          )
        : ListView.builder(
            key: const PageStorageKey('order-history-list'),
            controller: scroll,
            padding: EdgeInsets.only(top: 24, bottom: bottomPadding(context)),
            itemCount: controller.orders.length,
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        key: Key('history-${order.reference}'),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          CafeHaptics.light();
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(
                                name: '/order-confirmation',
                                arguments: 'Order details',
                              ),
                              builder: (_) => OrderConfirmationScreen(
                                order: order,
                                fromHistory: true,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index == 0 &&
                                  controller.historyError != null) ...[
                                Text(
                                  controller.historyError!,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    color: AppColors.teal,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      order.reference,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.secondaryText,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                orderDate(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OrderTracking(
                                  key: ValueKey('tracking-${order.reference}'),
                                  order: order,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${countText(order.itemCount)} ${order.itemCount == 1 ? 'item' : 'items'} · ${order.fulfillment == FulfillmentMethod.delivery ? 'Delivery' : 'Pickup'} · ${order.paymentStatus}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              NumericText(
                                pesos(order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
  );
}

// ============================================================
// CHECKOUT AND GCASH-STYLE PAYMENT DEMO
// ============================================================
class DeliveryLocationSelection {
  const DeliveryLocationSelection(this.point, this.suggestedAddress);

  final LatLng point;
  final String? suggestedAddress;
}

class DeliveryLocationService {
  const DeliveryLocationService();

  static DateTime? _lastNominatimRequest;

  Future<LatLng> currentLocation() async {
    if (!kIsWeb) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on device location services to use GPS.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was denied.');
      }
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 18),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<String?> addressFor(LatLng point) async {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      return null;
    }

    final openStreetMapAddress = await _openStreetMapAddress(point);
    if (openStreetMapAddress != null) return openStreetMapAddress;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return null;
    }
    try {
      final matches = await Geocoding()
          .placemarkFromCoordinates(point.latitude, point.longitude)
          .timeout(const Duration(seconds: 6));
      if (matches.isEmpty) return null;
      final place = matches.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ];
      final unique = <String>{};
      final address = parts
          .whereType<String>()
          .map((part) => part.usableText)
          .whereType<String>()
          .where((part) => unique.add(part.toLowerCase()))
          .join(', ');
      return address.usableText;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _openStreetMapAddress(LatLng point) async {
    final previousRequest = _lastNominatimRequest;
    if (previousRequest != null) {
      final wait =
          const Duration(seconds: 1) -
          DateTime.now().difference(previousRequest);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastNominatimRequest = DateTime.now();

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': point.latitude.toStringAsFixed(6),
      'lon': point.longitude.toStringAsFixed(6),
      'zoom': '18',
      'addressdetails': '1',
    });
    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!kIsWeb) 'User-Agent': 'SmoochCafeFlutter/1.0',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'];
      if (address is Map<String, dynamic>) {
        final parts = [
          address['house_number'],
          address['road'] ?? address['pedestrian'] ?? address['footway'],
          address['neighbourhood'] ?? address['suburb'],
          address['city'] ?? address['town'] ?? address['village'],
          address['state'],
          address['postcode'],
        ];
        final unique = <String>{};
        final formatted = parts
            .whereType<String>()
            .map((part) => part.usableText)
            .whereType<String>()
            .where((part) => unique.add(part.toLowerCase()))
            .join(', ');
        if (formatted.isNotEmpty) return formatted;
      }
      final displayName = data['display_name'];
      return displayName is String ? displayName.usableText : null;
    } catch (_) {
      return null;
    }
  }
}

class DeliveryRoute {
  DeliveryRoute({
    required List<LatLng> points,
    required this.distanceMeters,
    this.durationSeconds,
  }) : points = List<LatLng>.unmodifiable(points) {
    if (this.points.length < 2 ||
        this.points.length > 10000 ||
        this.points.any((point) => !_validPoint(point)) ||
        !distanceMeters.isFinite ||
        distanceMeters < 0 ||
        (durationSeconds != null &&
            (!durationSeconds!.isFinite || durationSeconds! < 0))) {
      throw StateError('The delivery route is invalid.');
    }
  }

  final List<LatLng> points;
  final double distanceMeters;
  final double? durationSeconds;

  static bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;
}

class DeliveryRouteService {
  DeliveryRouteService({this.client, Uri? endpoint, DateTime Function()? clock})
    : _endpoint = endpoint ?? Uri.parse(_configuredEndpoint),
      _clock = clock ?? DateTime.now {
    if (!const ['https', 'http'].contains(_endpoint.scheme) ||
        _endpoint.host.isEmpty ||
        _endpoint.userInfo.isNotEmpty ||
        _endpoint.hasFragment) {
      throw ArgumentError('The routing endpoint must be an HTTP(S) URL.');
    }
  }

  static const _configuredEndpoint = String.fromEnvironment(
    'OSRM_ROUTE_URL',
    defaultValue: 'https://router.project-osrm.org/route/v1/driving',
  );
  static final shared = DeliveryRouteService();
  static const _timeout = Duration(seconds: 8);
  static const _cacheLifetime = Duration(minutes: 10);
  static const _maxCacheEntries = 24;
  static const _maxResponseBytes = 512 * 1024;
  static DateTime _nextPublicRequest = DateTime.fromMillisecondsSinceEpoch(0);

  final http.Client? client;
  final Uri _endpoint;
  final DateTime Function() _clock;
  final _cache = <String, ({DeliveryRoute route, DateTime expiresAt})>{};
  final _inFlight = <String, Future<DeliveryRoute>>{};

  Future<DeliveryRoute> route(LatLng origin, LatLng destination) {
    if (!DeliveryRoute._validPoint(origin) ||
        !DeliveryRoute._validPoint(destination)) {
      return Future.error(StateError('The route locations are invalid.'));
    }
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final cached = _cache.remove(coordinates);
    if (cached != null && _clock().isBefore(cached.expiresAt)) {
      // Refresh insertion order so the least recently used entry leaves first.
      _cache[coordinates] = cached;
      return Future.value(cached.route);
    }
    final pending = _inFlight[coordinates];
    if (pending != null) return pending;

    final request = _fetch(coordinates)
        .then((result) {
          _cache[coordinates] = (
            route: result,
            expiresAt: _clock().add(_cacheLifetime),
          );
          while (_cache.length > _maxCacheEntries) {
            _cache.remove(_cache.keys.first);
          }
          return result;
        })
        .whenComplete(() {
          _inFlight.remove(coordinates);
        });
    _inFlight[coordinates] = request;
    return request;
  }

  Future<DeliveryRoute> _fetch(String coordinates) async {
    try {
      // The public OSRM server allows at most one request each second.
      // Reserve slots synchronously across instances; custom hosts skip this.
      if (_endpoint.host.toLowerCase() == 'router.project-osrm.org') {
        final now = DateTime.now();
        final slot = now.isBefore(_nextPublicRequest)
            ? _nextPublicRequest
            : now;
        _nextPublicRequest = slot.add(const Duration(seconds: 1));
        final delay = slot.difference(now);
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      }
      final path = _endpoint.path.replaceFirst(RegExp(r'/+$'), '');
      final uri = _endpoint.replace(
        path: '$path/$coordinates',
        queryParameters: {
          ..._endpoint.queryParameters,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'false',
          'alternatives': 'false',
        },
      );
      const headers = {'Accept': 'application/json'};
      final response =
          await (client == null
                  ? http.get(uri, headers: headers)
                  : client!.get(uri, headers: headers))
              .timeout(_timeout);
      if (response.statusCode != 200 ||
          response.bodyBytes.length > _maxResponseBytes) {
        throw StateError('The delivery route is unavailable.');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic> || body['code'] != 'Ok') {
        throw StateError('No road route is available for these locations.');
      }
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) {
        throw StateError('The routing response contains no route.');
      }
      final first = routes.first;
      if (first is! Map<String, dynamic>) {
        throw StateError('The routing response is invalid.');
      }
      final geometry = first['geometry'];
      if (geometry is! Map<String, dynamic> ||
          geometry['type'] != 'LineString') {
        throw StateError('The routing geometry is invalid.');
      }
      final rawPoints = geometry['coordinates'];
      if (rawPoints is! List ||
          rawPoints.length < 2 ||
          rawPoints.length > 10000) {
        throw StateError('The routing geometry is invalid.');
      }
      final points = <LatLng>[];
      for (final coordinate in rawPoints) {
        if (coordinate is! List ||
            coordinate.length < 2 ||
            coordinate[0] is! num ||
            coordinate[1] is! num) {
          throw StateError('The routing coordinates are invalid.');
        }
        points.add(
          LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
        );
      }
      final distance = first['distance'];
      final duration = first['duration'];
      if (distance is! num || (duration != null && duration is! num)) {
        throw StateError('The routing distance is invalid.');
      }
      return DeliveryRoute(
        points: points,
        distanceMeters: distance.toDouble(),
        durationSeconds: (duration as num?)?.toDouble(),
      );
    } on StateError {
      rethrow;
    } on TimeoutException {
      throw StateError('The route request timed out.');
    } catch (_) {
      throw StateError('The delivery route could not be loaded.');
    }
  }
}

class _CafeMap extends StatelessWidget {
  const _CafeMap({
    required this.center,
    this.pin,
    this.controller,
    this.onTap,
    this.onReady,
    this.zoom = 15,
    this.mapKey = const Key('delivery-map'),
    this.initialCameraFit,
    this.layers = const [],
    this.markers = const [],
  });

  static const _tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  final LatLng center;
  final LatLng? pin;
  final MapController? controller;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onReady;
  final double zoom;
  final Key mapKey;
  final CameraFit? initialCameraFit;
  final List<Widget> layers;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) => FlutterMap(
    key: mapKey,
    mapController: controller,
    options: MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      initialCameraFit: initialCameraFit,
      minZoom: 3,
      maxZoom: 19,
      onTap: onTap == null ? null : (_, point) => onTap!(point),
      onMapReady: onReady,
    ),
    children: [
      TileLayer(
        urlTemplate: _tileUrl,
        userAgentPackageName: 'SmoochCafeFlutter',
      ),
      ...layers,
      if (pin != null || markers.isNotEmpty)
        MarkerLayer(
          markers: [
            ...markers,
            if (pin != null)
              Marker(
                point: pin!,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  size: 46,
                  color: AppColors.action,
                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                ),
              ),
          ],
        ),
      Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: AppColors.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => openCafeLink(
                context,
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: AppColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class DeliveryRouteMap extends StatefulWidget {
  const DeliveryRouteMap({
    super.key,
    required this.destination,
    this.origin = CheckoutValidation.deliveryCenter,
    this.routeService,
  });

  final LatLng origin;
  final LatLng destination;
  final DeliveryRouteService? routeService;

  @override
  State<DeliveryRouteMap> createState() => _DeliveryRouteMapState();
}

class _DeliveryRouteMapState extends State<DeliveryRouteMap>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final mapController = MapController();
  late final flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6500),
  );
  DeliveryRoute? route;
  bool loading = true;
  bool failed = false;
  bool paused = false;
  bool reduced = false;
  bool foreground = true;
  bool tickerEnabled = true;
  bool mapReady = false;
  int request = 0;

  DeliveryRouteService get service =>
      widget.routeService ?? DeliveryRouteService.shared;

  CameraFit get cameraFit => CameraFit.coordinates(
    coordinates: [widget.origin, ...?route?.points, widget.destination],
    padding: const EdgeInsets.fromLTRB(42, 48, 42, 42),
    maxZoom: 17,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(loadRoute());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    tickerEnabled = TickerMode.valuesOf(context).enabled;
    syncMotion();
  }

  @override
  void didUpdateWidget(DeliveryRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination ||
        oldWidget.routeService != widget.routeService) {
      unawaited(loadRoute());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    syncMotion();
  }

  void syncMotion() {
    if (route != null && !paused && !reduced && foreground && tickerEnabled) {
      if (!flow.isAnimating) flow.repeat();
    } else {
      flow.stop();
    }
  }

  Future<void> loadRoute() async {
    final generation = ++request;
    flow.stop();
    flow.value = 0;
    setState(() {
      route = null;
      loading = true;
      failed = false;
    });
    if (mapReady) fitRoute();
    try {
      final result = await service.route(widget.origin, widget.destination);
      if (!mounted || generation != request) return;
      setState(() {
        route = result;
        loading = false;
      });
      syncMotion();
      // Camera changes happen after layout; animation never moves the map.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == request) fitRoute();
      });
    } catch (_) {
      if (!mounted || generation != request) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  void fitRoute() {
    if (mapReady) mapController.fitCamera(cameraFit);
  }

  @override
  void dispose() {
    request++;
    WidgetsBinding.instance.removeObserver(this);
    flow.dispose();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Delivery route',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (route != null && !reduced)
            IconButton(
              key: const Key('delivery-route-toggle'),
              tooltip: paused
                  ? 'Play route animation'
                  : 'Pause route animation',
              onPressed: () {
                setState(() => paused = !paused);
                syncMotion();
              },
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
              ),
            ),
          IconButton(
            key: const Key('delivery-route-fit'),
            tooltip: 'Show full route',
            onPressed: fitRoute,
            icon: const Icon(Icons.fit_screen_rounded, size: 20),
          ),
        ],
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CafeMap(
                mapKey: const Key('delivery-route-map'),
                center: widget.origin,
                controller: mapController,
                initialCameraFit: cameraFit,
                onReady: () {
                  mapReady = true;
                  fitRoute();
                },
                markers: [
                  Marker(
                    point: widget.origin,
                    width: 40,
                    height: 40,
                    child: const _RoutePin(
                      label: 'Smooch Cafe. Route start',
                      color: AppColors.dark,
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  Marker(
                    point: widget.destination,
                    width: 40,
                    height: 40,
                    child: const _RoutePin(
                      label: 'Delivery destination',
                      color: AppColors.action,
                      icon: Icons.home_outlined,
                    ),
                  ),
                ],
                layers: [
                  if (route case final road?) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: road.points,
                          strokeWidth: 6,
                          color: AppColors.teal,
                          borderStrokeWidth: 4,
                          borderColor: Colors.white,
                        ),
                      ],
                    ),
                    _DeliveryRouteHighlight(
                      points: road.points,
                      animation: flow,
                      moving: !reduced,
                    ),
                  ],
                ],
              ),
              if (loading)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    key: const Key('delivery-route-loading'),
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Finding a road route…',
                      style: TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ),
              if (failed)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Road route unavailable right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        TextButton.icon(
                          key: const Key('delivery-route-retry'),
                          onPressed: () => unawaited(loadRoute()),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _RouteLegend(color: AppColors.dark, label: 'Smooch Cafe'),
          _RouteLegend(color: AppColors.action, label: 'Delivery address'),
        ],
      ),
      if (route case final road?) ...[
        const SizedBox(height: 8),
        Text(
          '${(road.distanceMeters / 1000).toStringAsFixed(1)} km by road · Highlight shows route direction.',
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    ],
  );
}

class _RoutePin extends StatelessWidget {
  const _RoutePin({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(label, style: const TextStyle(fontSize: 11))),
    ],
  );
}

class _DeliveryRouteHighlight extends StatelessWidget {
  const _DeliveryRouteHighlight({
    required this.points,
    required this.animation,
    required this.moving,
  });
  final List<LatLng> points;
  final Animation<double> animation;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return SizedBox.expand(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              key: const Key('delivery-route-highlight'),
              painter: DeliveryRouteHighlightPainter(
                points: points
                    .map(camera.latLngToScreenOffset)
                    .toList(growable: false),
                animation: animation,
                moving: moving,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryRouteHighlightPainter extends CustomPainter {
  DeliveryRouteHighlightPainter({
    required this.points,
    required this.animation,
    required this.moving,
  }) : super(repaint: animation) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    final iterator = path.computeMetrics().iterator;
    metric = iterator.moveNext() ? iterator.current : null;
  }

  final List<Offset> points;
  final Animation<double> animation;
  final bool moving;
  late final ui.PathMetric? metric;

  @override
  void paint(Canvas canvas, Size size) {
    final line = metric;
    if (line == null || line.length < 1 || size.isEmpty) return;
    final length = line.length;
    final tail = (length * .22).clamp(28.0, 90.0);
    final head = moving
        ? animation.value * (length + tail * 2) - tail
        : length * .62;
    final start = (head - tail).clamp(0.0, length);
    final end = head.clamp(0.0, length);
    if (end <= start) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      line.extractPath(start, end),
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // A directional chevron is decorative, rather than a rider position.
    final tangent = line.getTangentForOffset(end);
    if (tangent != null) {
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      canvas.drawPath(
        Path()
          ..moveTo(-4, -4)
          ..lineTo(0, 0)
          ..lineTo(-4, 4),
        Paint()
          ..color = AppColors.dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DeliveryRouteHighlightPainter oldDelegate) =>
      points != oldDelegate.points ||
      animation != oldDelegate.animation ||
      moving != oldDelegate.moving;
}

class DeliveryMapPicker extends StatefulWidget {
  const DeliveryMapPicker({
    super.key,
    this.initialPoint,
    this.locateOnOpen = false,
    this.locationService = const DeliveryLocationService(),
  });

  final LatLng? initialPoint;
  final bool locateOnOpen;
  final DeliveryLocationService locationService;

  @override
  State<DeliveryMapPicker> createState() => _DeliveryMapPickerState();
}

class _DeliveryMapPickerState extends State<DeliveryMapPicker> {
  static const carmonaCenter = LatLng(14.3158, 121.0561);
  final mapController = MapController();
  LatLng? pin;
  bool mapReady = false;
  bool locating = false;
  bool resolving = false;
  int locationRequest = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    pin = widget.initialPoint;
    if (widget.locateOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) locate();
      });
    }
  }

  @override
  void dispose() {
    locationRequest++;
    mapController.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    if (locating || resolving) return;
    CafeHaptics.light();
    final request = ++locationRequest;
    setState(() {
      locating = true;
      error = null;
    });
    try {
      final location = await widget.locationService.currentLocation();
      if (!mounted || request != locationRequest) return;
      setState(() {
        pin = location;
        error = CheckoutValidation.isWithinDeliveryArea(location)
            ? null
            : 'This location is outside our ${CheckoutValidation.deliveryRadiusLabel} delivery area around Carmona.';
      });
      if (!CheckoutValidation.isWithinDeliveryArea(location)) {
        CafeHaptics.warning();
      }
      if (mapReady) mapController.move(location, 17);
    } catch (failure) {
      if (mounted && request == locationRequest) {
        CafeHaptics.error();
        setState(
          () => error = failure is StateError
              ? '${failure.message} You can also tap the map.'
              : failure is TimeoutException
              ? 'GPS took too long. Try again or tap the map.'
              : 'Could not use GPS. Allow location access or tap the map.',
        );
      }
    } finally {
      if (mounted && request == locationRequest) {
        setState(() => locating = false);
      }
    }
  }

  Future<void> confirm() async {
    if (pin == null ||
        resolving ||
        locating ||
        !CheckoutValidation.isWithinDeliveryArea(pin)) {
      CafeHaptics.warning();
      setState(
        () => error =
            'Choose a location within ${CheckoutValidation.deliveryRadiusLabel} of Carmona to continue.',
      );
      return;
    }
    CafeHaptics.selection();
    setState(() => resolving = true);
    final selected = pin!;
    String? suggestedAddress;
    try {
      suggestedAddress = await widget.locationService
          .addressFor(selected)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Keep the chosen destination even if the address lookup is unavailable.
    }
    if (!mounted) return;
    Navigator.of(context)
        .pop(DeliveryLocationSelection(selected, suggestedAddress));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Pin delivery location',
        style: TextStyle(fontSize: 16),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Stack(
          children: [
            _CafeMap(
              center: pin ?? carmonaCenter,
              pin: pin,
              controller: mapController,
              zoom: pin == null ? 13.5 : 16,
              onReady: () {
                mapReady = true;
                if (pin != null) mapController.move(pin!, 17);
              },
              onTap: resolving
                  ? null
                  : (point) {
                      if (CheckoutValidation.isWithinDeliveryArea(point)) {
                        CafeHaptics.selection();
                      } else {
                        CafeHaptics.warning();
                      }
                      setState(() {
                        locationRequest++;
                        locating = false;
                        pin = point;
                        error = CheckoutValidation.isWithinDeliveryArea(point)
                            ? null
                            : 'This location is outside our ${CheckoutValidation.deliveryRadiusLabel} delivery area around Carmona.';
                      });
                    },
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 8),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Text(
                      'Delivery available within ${CheckoutValidation.deliveryRadiusLabel} of Carmona. Tap to place your pin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.sizeOf(context).height * .45,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pin == null
                          ? 'Place a pin, or use your current location.'
                          : 'Pin: ${pin!.latitude.toStringAsFixed(5)}, ${pin!.longitude.toStringAsFixed(5)}',
                      key: const Key('selected-delivery-pin'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.action,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('map-use-current-location'),
                      onPressed: locating || resolving ? null : locate,
                      icon: locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_outlined, size: 18),
                      label: Text(locating ? 'Locating...' : 'Use my location'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      key: const Key('confirm-delivery-pin'),
                      onPressed:
                          pin == null ||
                              resolving ||
                              locating ||
                              !CheckoutValidation.isWithinDeliveryArea(pin)
                          ? null
                          : confirm,
                      icon: resolving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        resolving ? 'Finding address...' : 'Use this pin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.controller,
    this.locationService = const DeliveryLocationService(),
  });
  final ShopController controller;
  final DeliveryLocationService locationService;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final mobile = TextEditingController();
  final mobileFormatter = PhMobileInputFormatter();
  final address = TextEditingController();
  final notes = TextEditingController();
  String? suggestedAddress;
  LatLng? deliveryPin;
  PaymentMethod payment = PaymentMethod.cash;
  bool busy = false;
  bool attemptedSubmit = false;

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  String? validateMobile(String? value) {
    return CheckoutValidation.mobile(value);
  }

  Future<void> chooseLocation({bool useGps = false}) async {
    if (busy) return;
    CafeHaptics.light();
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await Navigator.of(context)
        .push<DeliveryLocationSelection>(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/delivery-map'),
            builder: (_) => DeliveryMapPicker(
              initialPoint: deliveryPin,
              locateOnOpen: useGps,
              locationService: widget.locationService,
            ),
          ),
        );
    if (!mounted || selected == null) return;
    final previousSuggestion = suggestedAddress;
    setState(() {
      deliveryPin = selected.point;
      suggestedAddress = selected.suggestedAddress.usableText;
    });
    if ((address.text.trim().isEmpty || address.text == previousSuggestion) &&
        selected.suggestedAddress.isUsable) {
      address.text = selected.suggestedAddress.usableText!;
    }
  }

  Future<void> placeOrder() async {
    if (busy) return;
    setState(() => attemptedSubmit = true);
    final invalid = form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      CafeHaptics.warning();
      await Scrollable.ensureVisible(
        invalid.first.context,
        alignment: .15,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      if (payment == PaymentMethod.digital) {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/payment'),
            builder: (_) => DemoPaymentScreen(
              amount: widget.controller.total,
              checkoutMobile: mobile.text,
            ),
          ),
        );
        if (!mounted || paid != true) return;
      }
      final order = await widget.controller.submitOrder(
        customerName: name.text,
        mobileNumber: mobile.text,
        notes: notes.text,
        paymentMethod: payment,
        deliveryAddress: address.text,
        deliveryLatitude: deliveryPin?.latitude,
        deliveryLongitude: deliveryPin?.longitude,
      );
      if (!mounted) return;
      if (order == null) {
        CafeHaptics.warning();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check your bag and delivery details before placing an order.',
            ),
          ),
        );
        return;
      }
      CafeHaptics.success();
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: OrderConfirmationScreen.routeName,
          ),
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
        (route) => route.settings.name == MenuScreen.routeName || route.isFirst,
      );
    } catch (_) {
      if (mounted) {
        CafeHaptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the order. Your bag is still here.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Form(
                key: form,
                autovalidateMode: attemptedSubmit
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Eyebrow('Order details'),
                    const SizedBox(height: 10),
                    Text('Almost yours.', style: displayStyle(32)),
                    const SizedBox(height: 8),
                    const Text(
                      'Tell us where to bring your order and how to reach you.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const CheckoutStepHeading(
                      step: 1,
                      title: 'Contact details',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('customer-name'),
                      controller: name,
                      enabled: !busy,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: CheckoutValidation.name,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const Key('customer-mobile'),
                      controller: mobile,
                      inputFormatters: [mobileFormatter],
                      enabled: !busy,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number *',
                        hintText: '09XX XXX XXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: validateMobile,
                    ),
                    const SizedBox(height: 24),
                    const CheckoutStepHeading(
                      step: 2,
                      title: 'Delivery address',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('delivery-address'),
                      controller: address,
                      enabled: !busy,
                      autofillHints: const [AutofillHints.fullStreetAddress],
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Delivery address *',
                        hintText: 'House number, street, barangay, city',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final addressError = CheckoutValidation.address(value);
                        if (addressError != null) return addressError;
                        if (deliveryPin != null &&
                            !CheckoutValidation.isWithinDeliveryArea(
                              deliveryPin,
                            )) {
                          return 'That pin is outside our ${CheckoutValidation.deliveryRadiusLabel} delivery area';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Delivery is available within ${CheckoutValidation.deliveryRadiusLabel} of Carmona, Cavite. If you use the map, your pin must be within this area. Include your house number, street and city.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    if (suggestedAddress.isUsable) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Map address suggestion: $suggestedAddress',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      if (address.text.trim() != suggestedAddress)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('use-suggested-address'),
                            onPressed: busy
                                ? null
                                : () => setState(() {
                                    address.text = suggestedAddress!;
                                  }),
                            icon: const Icon(Icons.edit_location_alt_outlined),
                            label: const Text('Use suggested address'),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('use-gps-address'),
                          onPressed: () => chooseLocation(useGps: true),
                          icon: const Icon(
                            Icons.my_location_outlined,
                            size: 18,
                          ),
                          label: const Text('Use GPS'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('choose-map-address'),
                          onPressed: chooseLocation,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(
                            deliveryPin == null ? 'Choose on map' : 'Move pin',
                          ),
                        ),
                      ],
                    ),
                    if (deliveryPin != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Delivery pin: ${deliveryPin!.latitude.toStringAsFixed(5)}, ${deliveryPin!.longitude.toStringAsFixed(5)}',
                        key: const Key('checkout-delivery-pin'),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('remove-delivery-pin'),
                          onPressed: busy
                              ? null
                              : () => setState(() => deliveryPin = null),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Remove pin'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const Key('customer-notes'),
                      controller: notes,
                      enabled: !busy,
                      maxLines: 2,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Delivery notes (optional)',
                        alignLabelWithHint: true,
                        hintText: 'Anything the cafe should know?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CheckoutStepHeading(
                      step: 3,
                      title: 'Payment method',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 12),
                    _PaymentChoice(
                      key: const Key('payment-cash'),
                      title: 'Cash on delivery',
                      subtitle: 'Pay when your order arrives',
                      icon: Icons.payments_outlined,
                      selected: payment == PaymentMethod.cash,
                      onTap: () {
                        if (!busy && payment != PaymentMethod.cash) {
                          CafeHaptics.selection();
                          setState(() => payment = PaymentMethod.cash);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _PaymentChoice(
                      key: const Key('payment-digital'),
                      title: 'GCash',
                      subtitle: 'Preview a wallet payment; no money is taken',
                      icon: Icons.account_balance_wallet_outlined,
                      selected: payment == PaymentMethod.digital,
                      onTap: () {
                        if (!busy && payment != PaymentMethod.digital) {
                          CafeHaptics.selection();
                          setState(() => payment = PaymentMethod.digital);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No order will be sent to the cafe, and no payment will be taken.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${countText(widget.controller.cartCount)} ${widget.controller.cartCount == 1 ? 'item' : 'items'} · Delivery',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        NumericText(
                          pesos(widget.controller.total),
                          key: const Key('checkout-total'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CafePress(
                        enabled: !busy,
                        child: FilledButton.icon(
                          key: const Key('place-order'),
                          onPressed: busy ? null : placeOrder,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward, size: 18),
                          iconAlignment: IconAlignment.end,
                          label: Text(
                            payment == PaymentMethod.cash
                                ? 'Place order'
                                : 'Continue to GCash',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: selected ? AppColors.softTeal : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.dark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.teal : AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

abstract final class _WalletDemoColors {
  static const blue = Color(0xFF0958D9);
  static const deepBlue = Color(0xFF073DA7);
  static const paleBlue = Color(0xFFF3F7FF);
  static const text = Color(0xFF172B50);
  static const muted = Color(0xFF65738D);
}

enum _DemoPaymentStage { review, processing, success, failed }

class DemoPaymentScreen extends StatefulWidget {
  const DemoPaymentScreen({
    super.key,
    required this.amount,
    required this.checkoutMobile,
  });

  final num amount;
  final String checkoutMobile;

  @override
  State<DemoPaymentScreen> createState() => _DemoPaymentScreenState();
}

class _DemoPaymentScreenState extends State<DemoPaymentScreen> {
  _DemoPaymentStage stage = _DemoPaymentStage.review;

  String get maskedMobile {
    final digits = widget.checkoutMobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'Checkout mobile';
    return 'Checkout mobile ending ${digits.substring(digits.length - 4)}';
  }

  Future<void> pay() async {
    if (stage != _DemoPaymentStage.review) return;
    setState(() => stage = _DemoPaymentStage.processing);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) {
      CafeHaptics.success();
      setState(() => stage = _DemoPaymentStage.success);
    }
  }

  Widget paymentRow(String label, String value, {bool total = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: total
                      ? _WalletDemoColors.text
                      : _WalletDemoColors.muted,
                  fontWeight: total ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: NumericText(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: _WalletDemoColors.text,
                  fontWeight: total ? FontWeight.w800 : FontWeight.w600,
                  fontSize: total ? 18 : 14,
                ),
              ),
            ),
          ],
        ),
      );

  Widget walletCard(Widget child) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14073DA7),
          blurRadius: 26,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );

  Widget reviewContent() => Column(
    key: const ValueKey('payment-review'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      walletCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PAY WITH',
              style: TextStyle(
                color: _WalletDemoColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _WalletDemoColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GCash wallet',
                        style: TextStyle(
                          color: _WalletDemoColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        maskedMobile,
                        style: const TextStyle(
                          color: _WalletDemoColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: _WalletDemoColors.blue,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      walletCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PAYMENT DETAILS',
              style: TextStyle(
                color: _WalletDemoColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 13),
            paymentRow('Merchant', 'Smooch Cafe'),
            paymentRow('Amount', pesos(widget.amount)),
            paymentRow('Service fee', pesos(0)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            paymentRow('Total', pesos(widget.amount), total: true),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const _PaymentDemoNotice(),
    ],
  );

  Widget resultContent() {
    final success = stage == _DemoPaymentStage.success;
    final processing = stage == _DemoPaymentStage.processing;
    final icon = processing
        ? null
        : success
        ? Icons.check_rounded
        : Icons.close_rounded;
    return Column(
      key: ValueKey(stage),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        walletCard(
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: success
                      ? const Color(0xFFE6F7F0)
                      : processing
                      ? _WalletDemoColors.paleBlue
                      : const Color(0xFFFDEDEB),
                  shape: BoxShape.circle,
                ),
                child: processing
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: _WalletDemoColors.blue,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        icon,
                        color: success
                            ? const Color(0xFF18835D)
                            : AppColors.action,
                        size: 40,
                      ),
              ),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(
                  processing
                      ? 'Processing payment'
                      : success
                      ? 'Payment preview complete'
                      : 'Payment preview failed',
                  key: processing
                      ? const Key('payment-processing')
                      : success
                      ? const Key('payment-success')
                      : const Key('payment-failure'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _WalletDemoColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                processing
                    ? 'Please wait while we complete your payment step.'
                    : success
                    ? 'Your Smooch Cafe order is ready to confirm.'
                    : 'Your bag is safe. You can try again or return to checkout.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _WalletDemoColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Divider(),
              paymentRow('Merchant', 'Smooch Cafe'),
              paymentRow('Amount', pesos(widget.amount), total: true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _PaymentDemoNotice(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: _WalletDemoColors.paleBlue,
      appBar: AppBar(
        backgroundColor: _WalletDemoColors.deepBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'GCash',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .17),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PREVIEW',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_WalletDemoColors.deepBlue, _WalletDemoColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (stage) {
                            _DemoPaymentStage.review => 'PAYMENT PREVIEW',
                            _DemoPaymentStage.processing =>
                              'PROCESSING PAYMENT',
                            _DemoPaymentStage.success => 'PREVIEW COMPLETE',
                            _DemoPaymentStage.failed => 'PREVIEW UNSUCCESSFUL',
                          },
                          style: const TextStyle(
                            color: Color(0xFFD6E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: NumericText(
                            pesos(widget.amount),
                            key: const Key('payment-amount'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.white,
                              child: Text(
                                'SC',
                                style: TextStyle(
                                  color: _WalletDemoColors.deepBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Smooch Cafe',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: stage == _DemoPaymentStage.review
                        ? reviewContent()
                        : resultContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: Key(
                        stage == _DemoPaymentStage.success
                            ? 'continue-after-payment'
                            : stage == _DemoPaymentStage.failed
                            ? 'retry-payment'
                            : 'pay-with-gcash',
                      ),
                      onPressed: switch (stage) {
                        _DemoPaymentStage.review => pay,
                        _DemoPaymentStage.processing => null,
                        _DemoPaymentStage.success => () => Navigator.pop(
                          context,
                          true,
                        ),
                        _DemoPaymentStage.failed => () => setState(
                          () => stage = _DemoPaymentStage.review,
                        ),
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _WalletDemoColors.blue,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: NumericText(switch (stage) {
                        _DemoPaymentStage.review =>
                          'Continue · ${pesos(widget.amount)}',
                        _DemoPaymentStage.processing => 'Processing…',
                        _DemoPaymentStage.success => 'Continue to order',
                        _DemoPaymentStage.failed => 'Try again',
                      }),
                    ),
                    if (stage == _DemoPaymentStage.review)
                      TextButton(
                        key: const Key('simulate-payment-failure'),
                        onPressed: () {
                          CafeHaptics.error();
                          setState(() => stage = _DemoPaymentStage.failed);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _WalletDemoColors.blue,
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text('Preview failed payment'),
                      ),
                    if (stage == _DemoPaymentStage.failed)
                      TextButton(
                        key: const Key('cancel-payment'),
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: _WalletDemoColors.blue,
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text('Back to checkout'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDemoNotice extends StatelessWidget {
  const _PaymentDemoNotice();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline, color: _WalletDemoColors.blue, size: 18),
      SizedBox(width: 9),
      Expanded(
        child: Text(
          'Payment preview only. This is not connected to GCash and no money will be transferred.',
          style: TextStyle(
            color: _WalletDemoColors.muted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

// ============================================================
// ORDER CONFIRMATION
// ============================================================
class OrderTracking extends StatefulWidget {
  const OrderTracking({super.key, required this.order, this.compact = false});

  final OrderReceipt order;
  final bool compact;

  @override
  State<OrderTracking> createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTracking>
    with WidgetsBindingObserver {
  late OrderStage stage;
  Timer? transitionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    stage = widget.order.stageAt(DateTime.now());
    scheduleNextTransition();
  }

  @override
  void didUpdateWidget(OrderTracking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.reference != widget.order.reference ||
        oldWidget.order.createdAt != widget.order.createdAt ||
        oldWidget.order.fulfillment != widget.order.fulfillment) {
      transitionTimer?.cancel();
      stage = widget.order.stageAt(DateTime.now());
      scheduleNextTransition();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final current = widget.order.stageAt(DateTime.now());
    if (widget.order.stages.indexOf(current) >
        widget.order.stages.indexOf(stage)) {
      setState(() => stage = current);
    }
    transitionTimer?.cancel();
    scheduleNextTransition();
  }

  void scheduleNextTransition() {
    if (stage == widget.order.stages.last) return;
    final nextAt = widget.order.createdAt.add(
      Duration(seconds: (widget.order.stages.indexOf(stage) + 1) * 10),
    );
    final remaining = nextAt.difference(DateTime.now());
    transitionTimer = Timer(
      remaining > Duration.zero ? remaining : const Duration(milliseconds: 1),
      advance,
    );
  }

  void advance() {
    if (!mounted) return;
    final actual = widget.order.stageAt(DateTime.now());
    final next =
        widget.order.stages.indexOf(actual) > widget.order.stages.indexOf(stage)
        ? actual
        : widget.order.stages[widget.order.stages.indexOf(stage) + 1];
    setState(() => stage = next);
    if (stage != widget.order.stages.last) {
      transitionTimer = Timer(const Duration(seconds: 10), advance);
    }
  }

  @override
  void dispose() {
    transitionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    if (widget.compact) {
      return Semantics(
        label: 'Order status: ${stage.label}',
        child: AnimatedSwitcher(
          duration: motion,
          child: Container(
            key: ValueKey(stage),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stage == widget.order.stages.last
                  ? AppColors.softTeal
                  : AppColors.softCoral,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stage.label,
              key: Key('order-stage-${widget.order.reference}'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const Key('order-tracking'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Updates every 10 seconds.',
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 18),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final step in widget.order.stages)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: AnimatedContainer(
                        duration: motion,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:
                              widget.order.stages.indexOf(step) <=
                                  widget.order.stages.indexOf(stage)
                              ? AppColors.teal
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: motion,
              child: Text(
                stage.message,
                key: Key('order-stage-${stage.name}'),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final step in widget.order.stages) ...[
            Row(
              children: [
                AnimatedContainer(
                  duration: motion,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color:
                        widget.order.stages.indexOf(step) <=
                            widget.order.stages.indexOf(stage)
                        ? AppColors.teal
                        : AppColors.softTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.order.stages.indexOf(step) <
                            widget.order.stages.indexOf(stage)
                        ? Icons.check_rounded
                        : switch (step) {
                            OrderStage.confirmed => Icons.receipt_long_outlined,
                            OrderStage.preparing => Icons.restaurant_outlined,
                            OrderStage.riderAssigned =>
                              Icons.delivery_dining_outlined,
                            OrderStage.onTheWay => Icons.route_outlined,
                            OrderStage.delivered =>
                              Icons.local_shipping_outlined,
                            OrderStage.readyForPickup =>
                              Icons.storefront_outlined,
                          },
                    size: 16,
                    color:
                        widget.order.stages.indexOf(step) <=
                            widget.order.stages.indexOf(stage)
                        ? AppColors.white
                        : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: step == stage
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color:
                          widget.order.stages.indexOf(step) <=
                              widget.order.stages.indexOf(stage)
                          ? AppColors.ink
                          : AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
            if (step != widget.order.stages.last)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: AnimatedContainer(
                  duration: motion,
                  width: 2,
                  height: 16,
                  color:
                      widget.order.stages.indexOf(step) <
                          widget.order.stages.indexOf(stage)
                      ? AppColors.teal
                      : AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.fromHistory = false,
  });
  static const routeName = '/order-confirmation';
  final OrderReceipt order;
  final bool fromHistory;

  void _continueShopping(BuildContext context) {
    if (fromHistory) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).popUntil(
      (route) => route.settings.name == MenuScreen.routeName || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        fromHistory ? 'Order details' : 'Order confirmation',
        style: const TextStyle(fontSize: 16),
      ),
      leading: IconButton(
        tooltip: fromHistory ? 'Back to orders' : 'Back to menu',
        onPressed: () => _continueShopping(context),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: CafeSuccessSeal(animate: !fromHistory)),
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    fromHistory ? 'Your saved order.' : 'Order placed.',
                    style: displayStyle(32),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fromHistory
                      ? orderDate(order.createdAt, detailed: true)
                      : 'Follow your order progress below.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                OrderTracking(order: order),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Eyebrow('Order reference'),
                      const SizedBox(height: 8),
                      SelectableText(
                        order.reference,
                        key: const Key('order-reference'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${countText(order.itemCount)} ${order.itemCount == 1 ? 'item' : 'items'} · ${order.fulfillment == FulfillmentMethod.delivery ? 'Delivery' : 'Pickup'} order',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${order.fulfillment == FulfillmentMethod.delivery ? 'Delivery' : 'Pickup'} for ${order.customerName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (order.mobileNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(readablePhMobile(order.mobileNumber)),
                      ],
                      if (order.deliveryAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Delivery address',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(order.deliveryAddress),
                        if (order.deliveryPoint case final point?) ...[
                          const SizedBox(height: 12),
                          DeliveryRouteMap(destination: point),
                        ],
                      ],
                      if (order.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Note: ${order.notes}'),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        order.paymentMethod == PaymentMethod.cash
                            ? '${order.fulfillment == FulfillmentMethod.delivery ? 'Cash on delivery' : 'Cash at pickup'} · ${order.paymentStatus}'
                            : 'GCash · ${order.paymentStatus}',
                        key: const Key('confirmation-payment'),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.product.subcategory,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  NumericText(
                                    '${countText(item.quantity)} × ${pesos(item.product.price)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  NumericText(
                                    pesos(item.total),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          NumericText(
                            pesos(order.total),
                            key: const Key('confirmation-total'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Saved on this device only. Nothing was sent to the cafe, and no payment was taken.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CafePress(
                  child: FilledButton.icon(
                    key: const Key('continue-shopping'),
                    onPressed: () => _continueShopping(context),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      fromHistory ? 'Back to orders' : 'Continue Shopping',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// CAFE INFORMATION
// ============================================================
class CafeSection extends StatelessWidget {
  const CafeSection({
    super.key,
    required this.onBrowse,
    required this.onCategory,
    required this.products,
  });
  final VoidCallback onBrowse;
  final ValueChanged<String> onCategory;
  final List<Product> products;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final spacious = constraints.maxWidth >= 700 && !largeText;
      final horizontal = largeText || constraints.maxWidth < 260;
      final collections = [
        for (final category in const ['Coffee', 'Food', 'Pastries'])
          (
            category: category,
            items: products
                .where((product) => product.category == category)
                .toList(),
          ),
      ].where((collection) => collection.items.isNotEmpty).toList();
      final columns = math.max(1, collections.length);
      final tileWidth = horizontal
          ? constraints.maxWidth
          : (constraints.maxWidth - 12 * (columns - 1)) / columns;
      final detailsWidth = spacious
          ? (constraints.maxWidth - 72) / 2
          : constraints.maxWidth - 40;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CafeReveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Smooch',
                  style: displayStyle(spacious ? 36 : 30),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coffee, comfort, and something sweet.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (collections.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final collection in collections)
                  SizedBox(
                    width: tileWidth,
                    child: _DiscoverCollection(
                      category: collection.category,
                      product: collection.items.first,
                      itemCount: collection.items.length,
                      horizontal: horizontal,
                      imageHeight: (tileWidth * .98).clamp(88.0, 200.0),
                      onTap: () => onCategory(collection.category),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('discover-browse-menu'),
              onPressed: onBrowse,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Browse menu'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                minimumSize: const Size(48, 48),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Visit Smooch',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Container(
            key: const Key('discover-cafe-details'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(CafeShape.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 32,
                  runSpacing: 0,
                  children: [
                    SizedBox(
                      width: detailsWidth,
                      child: const Column(
                        children: [
                          _CafeInfo(
                            icon: Icons.location_on_outlined,
                            title: 'Find us',
                            text: '447 JM Loyola Street, Carmona, Cavite',
                          ),
                          Divider(height: 1),
                          _CafeInfo(
                            icon: Icons.schedule,
                            title: 'Opening hours',
                            text: 'Monday–Sunday • 2:00 PM–11:00 PM',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: detailsWidth,
                      child: Column(
                        children: [
                          if (!spacious) const Divider(height: 1),
                          const _CafeInfo(
                            icon: Icons.phone_outlined,
                            title: 'Give us a call',
                            text: '(0965) 760 8290',
                            link: 'tel:+639657608290',
                            actionLabel: 'Call cafe',
                          ),
                          const Divider(height: 1),
                          const _CafeInfo(
                            icon: Icons.mail_outline,
                            title: 'Say hello',
                            text: 'smoochcafe25@gmail.com',
                            link: 'mailto:smoochcafe25@gmail.com',
                            actionLabel: 'Email cafe',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.delivery_dining_outlined,
                      size: 19,
                      color: AppColors.teal,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delivery within ${CheckoutValidation.deliveryRadiusLabel} of Carmona',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppVersionLabel(),
        ],
      );
    },
  );
}

class _DiscoverCollection extends StatelessWidget {
  const _DiscoverCollection({
    required this.category,
    required this.product,
    required this.itemCount,
    required this.onTap,
    required this.horizontal,
    required this.imageHeight,
  });
  final String category;
  final Product product;
  final int itemCount;
  final VoidCallback onTap;
  final bool horizontal;
  final double imageHeight;
  @override
  Widget build(BuildContext context) {
    final count =
        '${countText(itemCount)} ${itemCount == 1 ? 'item' : 'items'}';
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: horizontal ? 68 : double.infinity,
        height: horizontal ? 68 : imageHeight,
        child: ProductImage(product: product),
      ),
    );
    final text = Column(
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: 'Browse $category. $count.',
      onTap: onTap,
      excludeSemantics: true,
      child: CafePress(
        lift: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('discover-$category'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: horizontal
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        image,
                        const SizedBox(width: 16),
                        Expanded(child: text),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      image,
                      const SizedBox(height: 12),
                      text,
                      const SizedBox(height: 6),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CafeInfo extends StatelessWidget {
  const _CafeInfo({
    required this.icon,
    required this.title,
    required this.text,
    this.link,
    this.actionLabel,
  });
  final IconData icon;
  final String title;
  final String text;
  final String? link;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.teal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                text,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (link != null)
          IconButton(
            tooltip: actionLabel,
            onPressed: () => openCafeLink(context, Uri.parse(link!)),
            icon: const Icon(
              Icons.open_in_new,
              size: 20,
              color: AppColors.teal,
            ),
          ),
      ],
    ),
  );
}

class CafeRouteTitles extends NavigatorObserver {
  final title = ValueNotifier<String>('Welcome · Smooch Cafe');
  String menuLabel = 'Our menu';
  Route<dynamic>? active;
  String? pending;
  bool scheduled = false;
  bool disposed = false;
  void publish(String label) {
    pending = '$label · Smooch Cafe';
    if (scheduled || disposed) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (!disposed && pending != null) title.value = pending!;
    });
  }

  void showRoute(Route<dynamic>? route) {
    active = route;
    final label = switch (route?.settings.name) {
      '/menu' => menuLabel,
      '/details' =>
        route?.settings.arguments is String
            ? route!.settings.arguments as String
            : 'Product details',
      '/bag' => 'Your bag',
      '/history' => 'Order history',
      '/delivery-map' => 'Delivery location',
      '/checkout' => 'Checkout',
      '/payment' => 'GCash',
      '/order-confirmation' =>
        route?.settings.arguments == 'Order details'
            ? 'Order details'
            : 'Order confirmation',
      _ => 'Welcome',
    };
    publish(label);
  }

  void selectMenuTab(int index) {
    menuLabel = const ['Our menu', 'Order history', 'Discover'][index];
    if (active?.settings.name == '/menu') publish(menuLabel);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    if (route.settings.name == '/menu') menuLabel = 'Our menu';
    showRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) showRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (active == oldRoute) showRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (active == route) showRoute(previousRoute);
  }

  void dispose() {
    disposed = true;
    title.dispose();
  }
}

class CafeTitleScope extends InheritedWidget {
  const CafeTitleScope({super.key, required this.titles, required super.child});
  final CafeRouteTitles titles;
  static CafeRouteTitles? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CafeTitleScope>()?.titles;
  @override
  bool updateShouldNotify(CafeTitleScope oldWidget) =>
      oldWidget.titles != titles;
}

/// Friendly replacement for Flutter's red error screen, installed via
/// [ErrorWidget.builder]. Release builds show no technical details; debug
/// builds add the exception and stack trace. A long press anywhere copies
/// the details to the clipboard.
///
/// Adapts to the space the broken widget occupied: a full layout when there
/// is room, an icon-only badge inside small slots.
class FriendlyErrorView extends StatefulWidget {
  const FriendlyErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  State<FriendlyErrorView> createState() => _FriendlyErrorViewState();
}

class _FriendlyErrorViewState extends State<FriendlyErrorView> {
  Timer? _timer;
  bool _copied = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await HapticFeedback.mediumImpact();

      await Clipboard.setData(
        ClipboardData(
          text:
              '${widget.details.exceptionAsString()}\n\n${widget.details.stack}',
        ),
      );
    } catch (_) {
      return;
    }

    if (!mounted) return;

    setState(() => _copied = true);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The view can land anywhere in the tree, including where no Material or
    // Directionality ancestor exists, so it provides its own. The transparent
    // Material also prevents the yellow "missing Material" text underlines.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          container: true,
          label: 'Something went wrong. Please reopen the app and try again.',
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: _copy,
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool full =
                      c.maxHeight.isFinite &&
                      c.maxHeight >= 320 &&
                      c.maxWidth.isFinite &&
                      c.maxWidth >= 300;

                  // Only fill bounded axes; under unbounded constraints
                  // (lists, FittedBox) the view sizes to its content.
                  return Container(
                    width: c.hasBoundedWidth ? c.maxWidth : null,
                    height: c.hasBoundedHeight ? c.maxHeight : null,
                    decoration: BoxDecoration(
                      color: AppColors.softTeal,
                      borderRadius: BorderRadius.circular(full ? 0 : 28),
                    ),
                    child: full
                        ? _FriendlyErrorFullView(
                            details: widget.details,
                            copied: _copied,
                          )
                        : _FriendlyErrorCompactView(
                            details: widget.details,
                            copied: _copied,
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendlyErrorFullView extends StatelessWidget {
  const _FriendlyErrorFullView({required this.details, required this.copied});

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = AppTheme.theme.textTheme;

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FriendlyErrorBadge(size: 104, copied: copied),
        const SizedBox(height: 24),
        Text(
          'Something went wrong',
          textAlign: TextAlign.center,
          style: tt.titleLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please reopen the app and try again.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.75),
          ),
        ),
      ],
    );

    // Centered while the content fits, scrollable once it doesn't: the
    // sliver forces the child to at least viewport height, and the centered
    // column simply grows past it when the debug stack trace is long.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            // Clear the status bar and home indicator; the view has no
            // Scaffold or SafeArea above it (and possibly no MediaQuery).
            padding: EdgeInsets.fromLTRB(
              32,
              (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 32,
              32,
              (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                header,
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _FriendlyErrorDebugText(
                    '${details.exceptionAsString()}\n\n${details.stack}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendlyErrorCompactView extends StatelessWidget {
  const _FriendlyErrorCompactView({
    required this.details,
    required this.copied,
  });

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FriendlyErrorBadge(size: 48, copied: copied),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: _FriendlyErrorDebugText(
                    details.exceptionAsString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The badge briefly swaps its "!" for a check after the hidden long-press
/// copy gesture, so regular users never see a hint.
class _FriendlyErrorBadge extends StatelessWidget {
  const _FriendlyErrorBadge({required this.size, required this.copied});

  final double size;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: AppColors.teal,
        // A soft flower built with the SDK's StarBorder, so this file needs
        // no shape package.
        shape: const StarBorder(
          points: 12,
          innerRadiusRatio: 0.8,
          pointRounding: 0.7,
          valleyRounding: 0.3,
        ),
      ),
      child: AnimatedSwitcher(
        duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: Icon(
          copied ? Icons.check_rounded : Icons.priority_high_rounded,
          key: ValueKey<bool>(copied),
          color: AppColors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}

/// Exception text shown only in debug builds.
class _FriendlyErrorDebugText extends StatelessWidget {
  const _FriendlyErrorDebugText(this.text, {this.maxLines, this.textAlign});

  final String text;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? TextOverflow.fade : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
        fontSize: 12,
        color: AppColors.ink.withValues(alpha: 0.6),
      ),
    );
  }
}

// ============================================================
// 3D COFFEE SCENE DRAWING
// ============================================================
// Cached meshes and textures are projected into GPU triangle batches.
class CoffeeSceneViewport extends StatefulWidget {
  const CoffeeSceneViewport({
    super.key,
    required this.entrance,
    required this.idle,
    required this.reducedMotion,
    this.active = true,
  });
  final Animation<double> entrance;
  final Animation<double> idle;
  final bool reducedMotion;
  final bool active;
  @override
  State<CoffeeSceneViewport> createState() => _CoffeeSceneViewportState();
}

class _CoffeeSceneViewportState extends State<CoffeeSceneViewport>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final horizontal = AnimationController.unbounded(vsync: this);
  late final vertical = AnimationController.unbounded(vsync: this);
  final buffers = _CoffeeRenderBuffers();
  ui.Image? logoImage;
  ui.Image? latteImage;
  ui.ImageShader? logoShader;
  ui.ImageShader? latteShader;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final recording = ui.PictureRecorder();
    final canvas = Canvas(recording);
    _paintLatteTexture(canvas);
    // Solid ceramic samples this white gutter, so the entire depth-sorted
    // model shares one texture and does not split into tiny material batches.
    canvas.drawRect(
      const Rect.fromLTWH(512, 0, 8, 512),
      Paint()..color = Colors.white,
    );
    final picture = recording.endRecording();
    latteImage = picture.toImageSync(520, 512);
    picture.dispose();
    latteShader = ui.ImageShader(
      latteImage!,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
      filterQuality: FilterQuality.medium,
    );
    unawaited(loadLogo());
  }

  Future<void> loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 512,
      );
      ui.Image image;
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        image.dispose();
        return;
      }
      final shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
      setState(() {
        logoImage = image;
        logoShader = shader;
      });
    } catch (_) {
      // The mesh keeps its small heart mark if the bundled logo cannot decode.
    }
  }

  @override
  void didUpdateWidget(CoffeeSceneViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion || !widget.active) {
      horizontal.value = 0;
      vertical.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      horizontal.value = 0;
      vertical.value = 0;
    }
  }

  void moveTo(Offset local, Size size) {
    if (widget.reducedMotion || !widget.active || size.isEmpty) return;
    spring(horizontal, (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0));
    spring(vertical, (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0));
  }

  void spring(AnimationController controller, double target) {
    controller.animateWith(
      SpringSimulation(
        CafeMotion.spring,
        controller.value,
        target,
        controller.velocity,
      ),
    );
  }

  void rest() {
    if (widget.reducedMotion || !widget.active) return;
    spring(horizontal, 0);
    spring(vertical, 0);
  }

  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    WidgetsBinding.instance.removeObserver(this);
    logoShader?.dispose();
    latteShader?.dispose();
    logoImage?.dispose();
    latteImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      return MouseRegion(
        cursor: widget.reducedMotion
            ? MouseCursor.defer
            : SystemMouseCursors.grab,
        onHover: (event) => moveTo(event.localPosition, size),
        onExit: (_) => rest(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.reducedMotion
              ? null
              : (event) => moveTo(event.localPosition, size),
          onHorizontalDragUpdate: widget.reducedMotion
              ? null
              : (event) => moveTo(event.localPosition, size),
          onHorizontalDragEnd: widget.reducedMotion ? null : (_) => rest(),
          onHorizontalDragCancel: widget.reducedMotion ? null : rest,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.entrance,
              widget.idle,
              horizontal,
              vertical,
            ]),
            builder: (_, _) => CustomPaint(
              key: const Key('coffee-scene'),
              painter: CoffeeScenePainter._withBuffers(
                buffers,
                progress: widget.entrance.value,
                idlePhase: widget.idle.value,
                reducedMotion: widget.reducedMotion,
                interaction: widget.reducedMotion
                    ? Offset.zero
                    : Offset(
                        horizontal.value.clamp(-1.0, 1.0),
                        vertical.value.clamp(-1.0, 1.0),
                      ),
                logoShader: logoShader,
                logoSize: logoImage == null
                    ? Size.zero
                    : Size(
                        logoImage!.width.toDouble(),
                        logoImage!.height.toDouble(),
                      ),
                latteShader: latteShader,
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _paintLatteTexture(Canvas canvas) {
  const disk = Rect.fromLTWH(0, 0, 512, 512);
  canvas.drawOval(
    disk,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.22, -.3),
        radius: 1,
        colors: [Color(0xFFD9AA6E), Color(0xFFC18A4E), Color(0xFF8B4B24)],
        stops: [0, .77, 1],
      ).createShader(disk),
  );
  canvas.drawOval(
    disk.deflate(15),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFFE9C993).withValues(alpha: .8),
  );
  Path heart(double scale) {
    final path = Path();
    for (var i = 0; i <= 100; i++) {
      final t = i / 100 * math.pi * 2;
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t);
      final point = Offset(256 + x * scale, 236 - y * scale);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  for (final (scale, color) in const [
    (10.1, Color(0xFFFFF3D8)),
    (8.5, Color(0xFFC18A4E)),
    (7.2, Color(0xFFFFF3D8)),
    (5.8, Color(0xFFC18A4E)),
    (4.5, Color(0xFFFFF3D8)),
  ]) {
    canvas.drawPath(heart(scale), Paint()..color = color);
  }
  final pull = Path()
    ..moveTo(256, 223)
    ..quadraticBezierTo(250, 336, 264, 417);
  canvas.drawPath(
    pull,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFF3D8),
  );
}

class CoffeeScenePainter extends CustomPainter {
  CoffeeScenePainter({
    required double progress,
    required bool reducedMotion,
    double idlePhase = 0,
    Offset interaction = Offset.zero,
    ui.ImageShader? logoShader,
    Size logoSize = Size.zero,
    ui.ImageShader? latteShader,
  }) : this._withBuffers(
         _CoffeeRenderBuffers(),
         progress: progress,
         reducedMotion: reducedMotion,
         idlePhase: idlePhase,
         interaction: interaction,
         logoShader: logoShader,
         logoSize: logoSize,
         latteShader: latteShader,
       );

  CoffeeScenePainter._withBuffers(
    this._buffers, {
    required this.progress,
    required this.reducedMotion,
    this.idlePhase = 0,
    this.interaction = Offset.zero,
    this.logoShader,
    this.logoSize = Size.zero,
    this.latteShader,
  });
  final double progress, idlePhase;
  final bool reducedMotion;
  final Offset interaction;
  final ui.ImageShader? logoShader, latteShader;
  final Size logoSize;
  final _CoffeeRenderBuffers _buffers;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    final p = reducedMotion
        ? 1.0
        : (progress.isFinite ? progress.clamp(0.0, 1.0) : 1.0);
    final phase = reducedMotion || !idlePhase.isFinite
        ? 0.0
        : (idlePhase % 1) * math.pi * 2;
    final enter = Curves.easeOutCubic.transform(p);
    final arrival = reducedMotion
        ? 1.0
        : Curves.easeOutBack.transform((p / .7).clamp(0.0, 1.0));
    double safe(double value) => value.isFinite ? value.clamp(-1.0, 1.0) : 0;
    final tilt = reducedMotion
        ? Offset.zero
        : Offset(safe(interaction.dx), safe(interaction.dy));
    final rotation = _CoffeeRotation(
      -.12 - 1.1 * (1 - enter) + math.sin(phase) * .19 + tilt.dx * .4,
      .49 + (1 - enter) * .08 + math.sin(phase) * .025 - tilt.dy * .13,
      -.035 + math.sin(phase) * .035 + tilt.dx * .045,
    );
    final frame = _CoffeeFrame(size, rotation, arrival);
    final float = math.sin(phase) * .065;
    final groups = <_CoffeeGroup>[
      _CoffeeGroup(
        _CoffeeRotation.identity,
        _Vector(0, float - (1 - enter) * .2, 0),
        1.1,
      ),
      _CoffeeGroup(
        _CoffeeRotation.identity,
        _Vector(0, math.sin(phase + .7) * .012, 0),
        1,
      ),
      for (var i = 0; i < 5; i++)
        _CoffeeGroup(
          _CoffeeRotation(
            phase + i * 1.1,
            .25 + math.sin(phase * 2 + i) * .4,
            phase + i * .7,
          ),
          _Vector(
            math.cos(phase + i * math.pi * 2 / 5) * 1.85,
            .2 + math.sin(phase * 2 + i * .9) * .49,
            math.sin(phase + i * math.pi * 2 / 5) * 1.47,
          ),
          .78 *
              (reducedMotion
                  ? 1
                  : Curves.easeOutCubic.transform(
                      ((p - .09 - i * .035) / .64).clamp(0.0, 1.0),
                    )),
        ),
    ];
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawStudio(canvas, frame, float, phase);
    if (arrival > .015) {
      _drawOrbit(canvas, frame, false);
      _buffers.update(frame, groups, latteShader != null);
      _buffers.draw(canvas, _buffers.mainOrder, latteShader);
      _drawLogo(canvas, frame, groups.first);
      _drawOrbit(canvas, frame, true);
      _buffers.draw(canvas, _buffers.frontOrder, latteShader);
      _drawSteam(canvas, frame, groups.first, phase);
    }
    canvas.restore();
  }

  void _drawStudio(
    Canvas canvas,
    _CoffeeFrame frame,
    double float,
    double phase,
  ) {
    final glow = Rect.fromCenter(
      center: frame.center.translate(0, -frame.unit * .2),
      width: frame.unit * 5,
      height: frame.unit * 4.5,
    );
    if (_buffers.glowRect != glow) {
      _buffers.glowRect = glow;
      _buffers.glow = const RadialGradient(
        colors: [Color(0x284EB5AF), Color(0x000E6F7A)],
      ).createShader(glow);
    }
    canvas.drawOval(glow, Paint()..shader = _buffers.glow);
    final floor = frame.center + Offset(0, frame.unit * 1.7);
    canvas.drawOval(
      Rect.fromCenter(
        center: floor,
        width: frame.unit * 3.4,
        height: frame.unit * .4,
      ),
      Paint()
        ..color = AppColors.gold.withValues(
          alpha: .035 * frame.arrival.clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: floor,
        width: frame.unit * (2.8 - float),
        height: frame.unit * .22,
      ),
      Paint()
        ..color = const Color(0xFF03262C)
            .withValues(alpha: .65 * frame.arrival.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    for (var i = 0; i < 7; i++) {
      final angle = i * 2.399 + phase;
      final point = frame.project(
        _Vector(math.cos(angle) * 2.04, math.sin(angle) * 1.45 + .2, -.8),
      );
      final pulse = .15 + .2 * math.pow(math.sin(phase + i), 2);
      canvas.drawCircle(
        point,
        (i % 3 == 0 ? 1.8 : 1.1) * frame.arrival,
        Paint()
          ..color = (i.isEven ? AppColors.gold : AppColors.muted).withValues(
            alpha: pulse,
          ),
      );
    }
  }

  void _drawOrbit(Canvas canvas, _CoffeeFrame frame, bool front) {
    final path = Path();
    var connected = false;
    for (var i = 0; i <= 96; i++) {
      final angle = i / 96 * math.pi * 2;
      final world = _Vector(
        math.cos(angle) * 2.03,
        -.26 + math.sin(angle) * .08,
        math.sin(angle) * 1.8,
      );
      final camera = frame.rotation.rotate(world);
      if ((camera.z > .1) != front) {
        connected = false;
        continue;
      }
      final point = frame.projectCamera(camera);
      if (connected) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
        connected = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..color = AppColors.gold.withValues(alpha: front ? .19 : .11),
    );
  }

  void _drawSteam(
    Canvas canvas,
    _CoffeeFrame frame,
    _CoffeeGroup cup,
    double phase,
  ) {
    for (var strand = 0; strand < 3; strand++) {
      final cycle = reducedMotion
          ? .45 + strand * .13
          : (phase / (2 * math.pi) * 2 + strand / 3) % 1;
      final alpha = math.sin(cycle * math.pi) * .19;
      final path = Path();
      for (var step = 0; step <= 22; step++) {
        final t = step / 22;
        final point = frame.project(
          _Vector(
            (strand - 1) * .2 +
                math.sin(t * 5 + cycle * 3 + strand) * (.035 + t * .09),
            1.24 + cup.offset.y + cycle * .3 + t * .82,
            -.08 + math.sin(t * 3 + strand) * .08,
          ),
        );
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.6
          ..color = AppColors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  void _drawLogo(Canvas canvas, _CoffeeFrame frame, _CoffeeGroup cup) {
    if (logoShader == null) {
      final facing = frame.rotation.rotate(const _Vector(0, 0, 1)).z;
      if (facing < .1) return;
      final heart = Path();
      for (var i = 0; i <= 40; i++) {
        final t = i / 40 * math.pi * 2;
        final x = .026 * 16 * math.pow(math.sin(t), 3);
        final y =
            .026 *
                (13 * math.cos(t) -
                    5 * math.cos(2 * t) -
                    2 * math.cos(3 * t) -
                    math.cos(4 * t)) -
            .05;
        final radius = .70 + (y + .96) / 1.62 * .21 + .015;
        final point = frame.project(
          cup.point(
            _Vector(x, y, math.sqrt(math.max(0.0, radius * radius - x * x))),
          ),
        );
        if (i == 0) {
          heart.moveTo(point.dx, point.dy);
        } else {
          heart.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(heart..close(), Paint()..color = AppColors.white);
      return;
    }
    final refreshUv = _buffers.logoTextureSize != logoSize;
    _buffers.logoTextureSize = logoSize;
    final camera = _buffers._camera, normal = _buffers._normal;
    final samples = _CoffeeRenderBuffers.logoSamples;
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final n = sample.normal;
      frame.rotation.rotateInto(n.x, n.y, n.z, normal);
      cup.pointInto(sample.position, camera);
      frame.rotation.rotateInto(camera.x, camera.y, camera.z, camera);
      final scale = frame.unit * (7 / (7 - camera.z)) * frame.arrival;
      _buffers.logoPositions[i * 2] = frame.center.dx + camera.x * scale;
      _buffers.logoPositions[i * 2 + 1] = frame.center.dy + -camera.y * scale;
      if (refreshUv) {
        _buffers.logoUv[i * 2] = sample.u * logoSize.width;
        _buffers.logoUv[i * 2 + 1] = sample.v * logoSize.height;
      }
      final shade = (200 + 55 * math.max(0.0, normal.z)).round();
      _buffers.logoColors[i] =
          0xFF000000 | (shade << 16) | (shade << 8) | shade;
      _buffers.logoFacing[i] = normal.z;
    }
    final topology = _CoffeeRenderBuffers.logoTopology;
    var count = 0;
    for (var cell = 0; cell < topology.length; cell += 6) {
      if (_buffers.logoFacing[topology[cell]] +
              _buffers.logoFacing[topology[cell + 1]] >
          .2) {
        for (var index = 0; index < 6; index++) {
          _buffers.logoIndices[count++] = topology[cell + index];
        }
      }
    }
    if (count == 0) return;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _buffers.logoPositions,
      colors: _buffers.logoColors,
      textureCoordinates: _buffers.logoUv,
      indices: _buffers.logoIndexViews[count ~/ 6],
    );
    canvas.drawVertices(
      vertices,
      BlendMode.modulate,
      _buffers.logoPaint..shader = logoShader,
    );
    vertices.dispose();
  }

  @override
  bool shouldRepaint(CoffeeScenePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      idlePhase != oldDelegate.idlePhase ||
      reducedMotion != oldDelegate.reducedMotion ||
      interaction != oldDelegate.interaction ||
      logoShader != oldDelegate.logoShader ||
      latteShader != oldDelegate.latteShader;
}

class _CoffeeFrame {
  _CoffeeFrame(this.size, this.rotation, this.arrival)
    : unit = math.min(size.width / 4.6, size.height / 4.6),
      center = Offset(size.width * .485, size.height * .48);
  final Size size;
  final _CoffeeRotation rotation;
  final double arrival, unit;
  final Offset center;
  Offset project(_Vector point) => projectCamera(rotation.rotate(point));
  Offset projectCamera(_Vector point) {
    final perspective = 7 / (7 - point.z);
    return center + Offset(point.x, -point.y) * (unit * perspective * arrival);
  }
}

class _CoffeeRotation {
  _CoffeeRotation(double yaw, double pitch, double roll)
    : cy = math.cos(yaw),
      sy = math.sin(yaw),
      cp = math.cos(pitch),
      sp = math.sin(pitch),
      cr = math.cos(roll),
      sr = math.sin(roll);
  static final identity = _CoffeeRotation(0, 0, 0);
  final double cy, sy, cp, sp, cr, sr;
  _Vector rotate(_Vector point) {
    final x = point.x * cy + point.z * sy, z = -point.x * sy + point.z * cy;
    final y = point.y * cp - z * sp, depth = point.y * sp + z * cp;
    return _Vector(x * cr - y * sr, x * sr + y * cr, depth);
  }

  // Keep the same operation order as rotate, writing into retained scratch
  // space instead of creating vectors inside the per-vertex lighting loop.
  void rotateInto(double px, double py, double pz, _CoffeeScratch result) {
    final x = px * cy + pz * sy, z = -px * sy + pz * cy;
    final y = py * cp - z * sp, depth = py * sp + z * cp;
    result
      ..x = x * cr - y * sr
      ..y = x * sr + y * cr
      ..z = depth;
  }
}

class _CoffeeScratch {
  double x = 0, y = 0, z = 0;
  double dot(_Vector other) => x * other.x + y * other.y + z * other.z;
}

class _CoffeeGroup {
  const _CoffeeGroup(this.rotation, this.offset, this.scale);
  final _CoffeeRotation rotation;
  final _Vector offset;
  final double scale;
  _Vector point(_Vector point) => rotation.rotate(point) * scale + offset;

  void pointInto(_Vector point, _CoffeeScratch result) {
    rotation.rotateInto(point.x, point.y, point.z, result);
    result
      ..x = result.x * scale + offset.x
      ..y = result.y * scale + offset.y
      ..z = result.z * scale + offset.z;
  }
}

class _CoffeeLogoSample {
  const _CoffeeLogoSample(this.position, this.normal, this.u, this.v);
  final _Vector position, normal;
  final double u, v;
}

class _CoffeeRenderBuffers {
  _CoffeeRenderBuffers() {
    final vertices = _CoffeeMesh.studio.vertices;
    positions = Float32List(vertices.length * 2);
    colors = Int32List(vertices.length);
    uv = Float32List(vertices.length * 2);
    depths = Float32List(vertices.length);
    facing = Float32List(vertices.length);
    faceDepths = Float32List(_CoffeeMesh.studio.triangles.length);
    indices = Uint16List(_CoffeeMesh.studio.triangles.length * 3);
    for (var i = 0; i < vertices.length; i++) {
      final texturePoint = vertices[i].material == 1
          ? vertices[i].uv
          : const Offset(516, 256);
      uv[i * 2] = texturePoint.dx;
      uv[i * 2 + 1] = texturePoint.dy;
    }
  }
  late final Float32List positions, uv, depths, facing, faceDepths;
  late final Int32List colors;
  late final Uint16List indices;
  final mainOrder = <int>[], frontOrder = <int>[];
  final logoPositions = Float32List(19 * 5 * 2),
      logoUv = Float32List(19 * 5 * 2),
      logoFacing = Float32List(19 * 5);
  final logoColors = Int32List(19 * 5);
  final logoIndices = Uint16List(18 * 4 * 6);
  // Each visible cell contributes six indices. Views share the same retained
  // storage; Vertices.raw copies it before the next frame updates the buffer.
  late final logoIndexViews = List<Uint16List>.generate(
    18 * 4 + 1,
    (cells) => Uint16List.sublistView(logoIndices, 0, cells * 6),
    growable: false,
  );
  Size? logoTextureSize;
  final logoPaint = Paint()..filterQuality = FilterQuality.medium;
  static final logoSamples = _makeLogoSamples();
  static final logoTopology = _makeLogoTopology();
  final _camera = _CoffeeScratch(), _normal = _CoffeeScratch();
  final _foreground = List<bool>.filled(7, false);
  late final Comparator<int> _compareDepths = _compareFaceDepths;
  final meshPaint = Paint()..filterQuality = FilterQuality.medium;
  Rect? glowRect;
  Shader? glow;
  static final keyLight = const _Vector(-.5, .75, 1).normalized;
  static final fillLight = const _Vector(.8, .3, .2).normalized;
  static final highlight = (keyLight + const _Vector(0, 0, 1)).normalized;

  int _compareFaceDepths(int a, int b) =>
      faceDepths[a].compareTo(faceDepths[b]);

  static List<_CoffeeLogoSample> _makeLogoSamples() {
    final samples = <_CoffeeLogoSample>[];
    const columns = 18, rows = 4;
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= columns; x++) {
        final u = x / columns, v = y / rows;
        final angle = math.pi / 2 + (.5 - u) * 1.55;
        final height = .43 - v * 1.0;
        final radius = .70 + (height + .96) / 1.62 * .21 + .014;
        samples.add(
          _CoffeeLogoSample(
            _Vector(radius * math.cos(angle), height, radius * math.sin(angle)),
            _Vector(math.cos(angle), -.13, math.sin(angle)).normalized,
            u,
            v,
          ),
        );
      }
    }
    return List<_CoffeeLogoSample>.unmodifiable(samples);
  }

  static Uint16List _makeLogoTopology() {
    final indices = Uint16List(18 * 4 * 6);
    var index = 0;
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 18; x++) {
        final a = y * 19 + x, b = a + 1, c = a + 19, d = c + 1;
        indices[index++] = a;
        indices[index++] = b;
        indices[index++] = c;
        indices[index++] = b;
        indices[index++] = d;
        indices[index++] = c;
      }
    }
    return indices;
  }

  void update(
    _CoffeeFrame frame,
    List<_CoffeeGroup> groups,
    bool texturedCoffee,
  ) {
    final mesh = _CoffeeMesh.studio;
    for (var i = 0; i < groups.length; i++) {
      final offset = groups[i].offset;
      frame.rotation.rotateInto(offset.x, offset.y, offset.z, _camera);
      _foreground[i] = _camera.z > .95;
    }
    for (var i = 0; i < mesh.vertices.length; i++) {
      final vertex = mesh.vertices[i], group = groups[vertex.group];
      group.pointInto(vertex.position, _camera);
      frame.rotation.rotateInto(_camera.x, _camera.y, _camera.z, _camera);
      final normal = vertex.normal;
      group.rotation.rotateInto(normal.x, normal.y, normal.z, _normal);
      frame.rotation.rotateInto(_normal.x, _normal.y, _normal.z, _normal);
      final perspective = 7 / (7 - _camera.z);
      final scale = frame.unit * perspective * frame.arrival;
      positions[i * 2] = frame.center.dx + _camera.x * scale;
      positions[i * 2 + 1] = frame.center.dy + -_camera.y * scale;
      depths[i] = _camera.z;
      facing[i] = _normal.z;
      final base = vertex.material == 1 && !texturedCoffee
          ? const Color(0xFFC18A4E)
          : vertex.color;
      final diffuse =
          .44 +
          .49 * math.max(0.0, _normal.dot(keyLight)) +
          .12 * math.max(0.0, _normal.dot(fillLight));
      final specular =
          math.pow(math.max(0.0, _normal.dot(highlight)), 42) *
          vertex.gloss *
          .54;
      final rim = math.pow(1 - _normal.z.abs().clamp(0.0, 1.0), 3) * .075;
      colors[i] =
          0xFF000000 |
          (_channel(base.r, 1, diffuse, specular, rim) << 16) |
          (_channel(base.g, .81, diffuse, specular, rim) << 8) |
          _channel(base.b, .48, diffuse, specular, rim);
    }
    mainOrder.clear();
    frontOrder.clear();
    for (var i = 0; i < mesh.triangles.length; i++) {
      final face = mesh.triangles[i];
      if (groups[face.group].scale < .01 ||
          facing[face.a] + facing[face.b] + facing[face.c] <= -.025) {
        continue;
      }
      faceDepths[i] = (depths[face.a] + depths[face.b] + depths[face.c]) / 3;
      (face.group >= 2 && _foreground[face.group] ? frontOrder : mainOrder).add(
        i,
      );
    }
    mainOrder.sort(_compareDepths);
    frontOrder.sort(_compareDepths);
  }

  static int _channel(
    double color,
    double edge,
    double diffuse,
    num specular,
    double rim,
  ) => (255 * (color * diffuse + specular + edge * rim)).round().clamp(0, 255);

  void draw(Canvas canvas, List<int> order, ui.ImageShader? coffee) {
    if (order.isEmpty) return;
    final faces = _CoffeeMesh.studio.triangles;
    var count = 0;
    for (final index in order) {
      final face = faces[index];
      indices[count++] = face.a;
      indices[count++] = face.b;
      indices[count++] = face.c;
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      colors: colors,
      textureCoordinates: coffee == null ? null : uv,
      indices: Uint16List.sublistView(indices, 0, count),
    );
    canvas.drawVertices(
      vertices,
      coffee == null ? BlendMode.dst : BlendMode.modulate,
      meshPaint..shader = coffee,
    );
    vertices.dispose();
  }
}

class _Vector {
  const _Vector(this.x, this.y, this.z);
  final double x, y, z;
  _Vector operator +(_Vector other) =>
      _Vector(x + other.x, y + other.y, z + other.z);
  _Vector operator -(_Vector other) =>
      _Vector(x - other.x, y - other.y, z - other.z);
  _Vector operator *(double factor) =>
      _Vector(x * factor, y * factor, z * factor);
  _Vector get normalized {
    final length = math.sqrt(x * x + y * y + z * z);
    return length <= 1e-10 ? const _Vector(0, 1, 0) : this * (1 / length);
  }

  double dot(_Vector other) => x * other.x + y * other.y + z * other.z;
}

class _CoffeeVertex {
  const _CoffeeVertex({
    required this.position,
    required this.normal,
    required this.color,
    required this.group,
    this.material = 0,
    this.uv = Offset.zero,
    this.gloss = .5,
  });

  final _Vector position;
  final _Vector normal;
  final Color color;
  final int group;
  final int material;
  final Offset uv;
  final double gloss;
}

class _CoffeeTriangle {
  const _CoffeeTriangle(this.a, this.b, this.c, this.material, this.group);
  final int a, b, c, material, group;
}

class _CoffeeMesh {
  const _CoffeeMesh(this.vertices, this.triangles);
  final List<_CoffeeVertex> vertices;
  final List<_CoffeeTriangle> triangles;
  static final studio = _buildStudio();

  static _CoffeeMesh _buildStudio() {
    final mesh = _CoffeeMeshBuilder();
    const teal = Color(0xFF0E6F7A);
    const cream = Color(0xFFF5E8D6);
    const innerCream = Color(0xFFEADCC8);
    const gold = Color(0xFFE9C587);

    mesh.lathe(
      const [
        (-1.15, .56),
        (-1.12, .64),
        (-.96, .70),
        (-.35, .81),
        (.30, .88),
        (.66, .91),
        (.90, .933),
      ],
      teal,
      group: 0,
      gloss: .82,
    );
    mesh.disk(
      y: -1.15,
      radius: .56,
      color: teal,
      group: 0,
      up: false,
      gloss: .55,
    );

    // Adjacent bands share their boundaries. Overlapping the body and lip
    // would produce depth-sorting artifacts as the floating mug rotates.
    mesh.lathe(const [(.90, .933), (.93, .936)], gold, group: 0, gloss: .85);
    // The profile travels up the outside, over the rounded lip and down
    // into the opening, giving the inner section inward-facing normals.
    mesh.lathe(
      const [
        (.93, .936),
        (1.05, .958),
        (1.12, .958),
        (1.18, .91),
        (1.18, .86),
        (1.10, .84),
      ],
      cream,
      group: 0,
      gloss: .68,
    );
    mesh.lathe(
      const [(1.10, .84), (.72, .81), (-.86, .60), (-.99, .57)],
      innerCream,
      group: 0,
      gloss: .40,
    );
    mesh.disk(y: -.99, radius: .57, color: innerCream, group: 0, gloss: .35);

    mesh.handle(color: teal, group: 0);

    // Closed cream saucer: underside -> outer rim -> concave upper dish.
    mesh.lathe(
      const [
        (-1.72, 0.0),
        (-1.72, 1.22),
        (-1.65, 1.42),
        (-1.60, 1.43),
        (-1.54, 1.35),
        (-1.64, .88),
        (-1.64, 0.0),
      ],
      cream,
      group: 1,
      gloss: .58,
    );
    mesh.lathe(
      const [(-1.615, 1.438), (-1.588, 1.431)],
      gold,
      group: 1,
      gloss: .82,
    );

    // The visible liquid is below the ceramic lip. Texture coordinates
    // are pixel coordinates for the root renderer's 512px coffee artwork.
    mesh.disk(
      y: 1.075,
      radius: .835,
      color: const Color(0xFFFFFFFF),
      group: 0,
      material: 1,
      segments: 48,
      gloss: .36,
    );

    const browns = [
      Color(0xFFA86B3D),
      Color(0xFFB77945),
      Color(0xFF9A592F),
      Color(0xFFC0874D),
      Color(0xFFAD6B38),
    ];
    for (var index = 0; index < 5; index++) {
      mesh.bean(color: browns[index], group: index + 2);
    }
    return _CoffeeMesh(
      List<_CoffeeVertex>.unmodifiable(mesh.vertices),
      List<_CoffeeTriangle>.unmodifiable(mesh.triangles),
    );
  }
}

class _CoffeeMeshBuilder {
  final vertices = <_CoffeeVertex>[];
  final triangles = <_CoffeeTriangle>[];

  int vertex(
    _Vector position,
    _Vector normal,
    Color color, {
    required int group,
    int material = 0,
    double gloss = .5,
    Offset uv = Offset.zero,
  }) {
    vertices.add(
      _CoffeeVertex(
        position: position,
        normal: normal.normalized,
        color: color,
        group: group,
        material: material,
        gloss: gloss,
        uv: uv,
      ),
    );
    return vertices.length - 1;
  }

  void triangle(int a, int b, int c) {
    final first = vertices[a], second = vertices[b], third = vertices[c];
    final u = second.position - first.position;
    final v = third.position - first.position;
    final cross = _Vector(
      u.y * v.z - u.z * v.y,
      u.z * v.x - u.x * v.z,
      u.x * v.y - u.y * v.x,
    );
    // At pole rings one half of each quad collapses to zero area.
    if (cross.dot(cross) < 1e-14) return;
    final normal = first.normal + second.normal + third.normal;
    final flip = cross.dot(normal) < 0;
    triangles.add(
      _CoffeeTriangle(
        a,
        flip ? c : b,
        flip ? b : c,
        first.material,
        first.group,
      ),
    );
  }

  void lathe(
    List<(double, double)> profile,
    Color color, {
    required int group,
    double gloss = .5,
    int segments = 40,
  }) {
    final start = vertices.length;
    for (var ring = 0; ring < profile.length; ring++) {
      final (y, radius) = profile[ring];
      final before = profile[ring == 0 ? ring : ring - 1];
      final after = profile[ring == profile.length - 1 ? ring : ring + 1];
      final dy = after.$1 - before.$1;
      final dr = after.$2 - before.$2;
      for (var segment = 0; segment <= segments; segment++) {
        final angle = segment * math.pi * 2 / segments;
        final cos = math.cos(angle), sin = math.sin(angle);
        vertex(
          _Vector(radius * cos, y, radius * sin),
          _Vector(dy * cos, -dr, dy * sin),
          color,
          group: group,
          gloss: gloss,
        );
      }
    }
    final stride = segments + 1;
    for (var ring = 0; ring < profile.length - 1; ring++) {
      for (var segment = 0; segment < segments; segment++) {
        final a = start + ring * stride + segment;
        final b = a + 1, c = a + stride, d = c + 1;
        triangle(a, b, c);
        triangle(b, d, c);
      }
    }
  }

  void disk({
    required double y,
    required double radius,
    required Color color,
    required int group,
    bool up = true,
    int segments = 40,
    int material = 0,
    double gloss = .5,
  }) {
    final normal = _Vector(0, up ? 1 : -1, 0);
    final center = vertex(
      _Vector(0, y, 0),
      normal,
      color,
      group: group,
      material: material,
      gloss: gloss,
      uv: const Offset(256, 256),
    );
    for (var index = 0; index <= segments; index++) {
      final angle = index * math.pi * 2 / segments;
      final cos = math.cos(angle), sin = math.sin(angle);
      vertex(
        _Vector(radius * cos, y, radius * sin),
        normal,
        color,
        group: group,
        material: material,
        gloss: gloss,
        uv: Offset(256 + cos * 255, 256 + sin * 255),
      );
      if (index > 0) triangle(center, center + index, center + index + 1);
    }
  }

  void handle({required Color color, required int group}) {
    const around = 24, tubeSegments = 8;
    const rx = .52, ry = .66, tube = .11;
    final start = vertices.length;
    for (var ring = 0; ring <= around; ring++) {
      final angle = ring * math.pi * 2 / around;
      final cos = math.cos(angle), sin = math.sin(angle);
      final center = _Vector(1.04 + rx * cos, ry * sin, 0);
      // The ellipse gradient is perpendicular to its tangent. A radial
      // vector would skew highlights at the narrow ends of the oval.
      final outward = _Vector(cos / rx, sin / ry, 0).normalized;
      for (var segment = 0; segment <= tubeSegments; segment++) {
        final phi = segment * math.pi * 2 / tubeSegments;
        final normal = outward * math.cos(phi) + _Vector(0, 0, math.sin(phi));
        vertex(center + normal * tube, normal, color, group: group, gloss: .82);
      }
    }
    const stride = tubeSegments + 1;
    for (var ring = 0; ring < around; ring++) {
      for (var segment = 0; segment < tubeSegments; segment++) {
        final a = start + ring * stride + segment;
        triangle(a, a + 1, a + stride);
        triangle(a + 1, a + stride + 1, a + stride);
      }
    }
  }

  void bean({required Color color, required int group}) {
    const rx = .16, ry = .25, rz = .11;
    const latitudeSteps = 6, longitudeSteps = 12;
    final start = vertices.length;
    for (var latitude = 0; latitude <= latitudeSteps; latitude++) {
      final phi = latitude * math.pi / latitudeSteps;
      final sin = math.sin(phi), cos = math.cos(phi);
      for (var longitude = 0; longitude <= longitudeSteps; longitude++) {
        final theta = longitude * math.pi * 2 / longitudeSteps;
        final position = _Vector(
          rx * sin * math.cos(theta),
          ry * cos,
          rz * sin * math.sin(theta),
        );
        final normal = _Vector(
          position.x / (rx * rx),
          position.y / (ry * ry),
          position.z / (rz * rz),
        );
        vertex(position, normal, color, group: group, gloss: .28);
      }
    }
    const stride = longitudeSteps + 1;
    for (var latitude = 0; latitude < latitudeSteps; latitude++) {
      for (var longitude = 0; longitude < longitudeSteps; longitude++) {
        final a = start + latitude * stride + longitude;
        triangle(a, a + 1, a + stride);
        triangle(a + 1, a + stride + 1, a + stride);
      }
    }

    // Narrow dark ribbon follows the ellipsoid's positive-z surface.
    // It is offset only .002 units to avoid coplanar sorting artifacts.
    final seamStart = vertices.length;
    const seamSteps = 12;
    for (var step = 0; step <= seamSteps; step++) {
      final t = -1 + 2 * step / seamSteps;
      final y = ry * t * .87;
      final curve = .04 * math.sin(t * math.pi);
      final halfWidth = .006 * (1 - .3 * t.abs());
      for (final side in const [-1.0, 1.0]) {
        final x = curve + halfWidth * side;
        final z =
            rz *
            math.sqrt(
              math.max(0.0, 1 - (x / rx) * (x / rx) - (y / ry) * (y / ry)),
            );
        vertex(
          _Vector(x, y, z + .002),
          _Vector(x / (rx * rx), y / (ry * ry), z / (rz * rz)),
          const Color(0xFF4A2B1D),
          group: group,
          gloss: .06,
        );
      }
      if (step > 0) {
        final a = seamStart + (step - 1) * 2;
        triangle(a, a + 1, a + 2);
        triangle(a + 1, a + 3, a + 2);
      }
    }
  }
}

// ============================================================
// WIDGET PREVIEWS
// ============================================================
@Preview(name: '3D start screen / phone', size: Size(390, 844))
@Preview(name: '3D start screen / desktop', size: Size(1440, 900))
Widget splashPreview() => MaterialApp(
  theme: AppTheme.theme,
  scrollBehavior: const AlwaysScrollbarBehavior(),
  builder: cafeTextScaleBuilder,
  home: StartScreen(
    controller: ShopController(repository: const MenuRepository()),
  ),
);

@Preview(name: 'Menu / phone', size: Size(390, 844))
@Preview(name: 'Menu / desktop', size: Size(1440, 1000))
Widget menuPreview() => MaterialApp(
  theme: AppTheme.theme,
  scrollBehavior: const AlwaysScrollbarBehavior(),
  builder: cafeTextScaleBuilder,
  home: MenuScreen(
    controller: ShopController(repository: const MenuRepository()),
  ),
);
