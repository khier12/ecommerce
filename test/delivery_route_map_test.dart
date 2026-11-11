import 'dart:async';
import 'dart:ui' as ui;

import 'package:ecommerce/main.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart'
    show FlutterMap, MarkerLayer, PolylineLayer;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;

const _firstDropoff = LatLng(14.322, 121.061);
const _secondDropoff = LatLng(14.319, 121.049);
const _thirdDropoff = LatLng(14.308, 121.054);

class _RouteRequest {
  _RouteRequest(this.origin, this.destination);

  final LatLng origin;
  final LatLng destination;
  final result = Completer<DeliveryRoute>();
}

class _PendingRouteService extends DeliveryRouteService {
  final requests = <_RouteRequest>[];

  @override
  Future<DeliveryRoute> route(LatLng origin, LatLng destination) {
    final request = _RouteRequest(origin, destination);
    requests.add(request);
    return request.result.future;
  }
}

DeliveryRoute _roadTo(LatLng destination) => DeliveryRoute(
  points: [
    CheckoutValidation.deliveryCenter,
    const LatLng(14.317, 121.0561),
    LatLng(14.317, destination.longitude),
    destination,
  ],
  distanceMeters: 1450,
  durationSeconds: 240,
);

Widget _routeApp(
  _PendingRouteService service, {
  LatLng destination = _firstDropoff,
  bool reducedMotion = false,
  bool tickerEnabled = true,
  double textScale = 1,
}) => MaterialApp(
  theme: AppTheme.theme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: TickerMode(
        enabled: tickerEnabled,
        child: DeliveryRouteMap(
          destination: destination,
          routeService: service,
        ),
      ),
    ),
  ),
);

Future<void> _flushRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

bool _showsFullRoute(WidgetTester tester, DeliveryRoute route) => tester
    .widgetList<PolylineLayer>(
      find.byWidgetPredicate((widget) => widget is PolylineLayer),
    )
    .expand((layer) => layer.polylines)
    .any((line) => listEquals(line.points, route.points));

DeliveryRouteHighlightPainter _routePainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const Key('delivery-route-highlight')),
            )
            .painter!
        as DeliveryRouteHighlightPainter;

Future<Uint8List> _rasterHighlight(double phase) async {
  final recorder = ui.PictureRecorder();
  DeliveryRouteHighlightPainter(
    points: const [
      Offset(20, 100),
      Offset(120, 100),
      Offset(120, 180),
      Offset(270, 180),
    ],
    animation: AlwaysStoppedAnimation<double>(phase),
    moving: true,
  ).paint(ui.Canvas(recorder), const Size(320, 260));
  final picture = recorder.endRecording();
  ui.Image? image;
  try {
    image = await picture.toImage(320, 260);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return Uint8List.fromList(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  } finally {
    image?.dispose();
    picture.dispose();
  }
}

int _visiblePixels(Uint8List rgba) {
  var visible = 0;
  for (var alpha = 3; alpha < rgba.length; alpha += 4) {
    if (rgba[alpha] > 0) visible++;
  }
  return visible;
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

  testWidgets('The route loads once and retains its full road geometry', (
    tester,
  ) async {
    final service = _PendingRouteService();
    await tester.pumpWidget(_routeApp(service));
    expect(find.text('Delivery route'), findsOneWidget);
    expect(find.byKey(const Key('delivery-route-loading')), findsOneWidget);
    expect(service.requests, hasLength(1));
    expect(service.requests.single.origin, CheckoutValidation.deliveryCenter);
    expect(service.requests.single.destination, _firstDropoff);

    final route = _roadTo(_firstDropoff);
    service.requests.single.result.complete(route);
    await _flushRoute(tester);
    expect(find.byKey(const Key('delivery-route-loading')), findsNothing);
    expect(find.byKey(const Key('delivery-route-map')), findsOneWidget);
    expect(_showsFullRoute(tester, route), isTrue);
    final mapSize = tester.getSize(find.byKey(const Key('delivery-route-map')));
    final highlightSize = tester.getSize(
      find.byKey(const Key('delivery-route-highlight')),
    );
    expect(highlightSize.width, greaterThan(0));
    expect(highlightSize.height, 260);
    expect(highlightSize, mapSize);
    final markers = tester
        .widgetList<MarkerLayer>(find.byType(MarkerLayer))
        .expand((layer) => layer.markers);
    expect(
      markers.map((marker) => marker.point),
      unorderedEquals([CheckoutValidation.deliveryCenter, _firstDropoff]),
    );

    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 160));
    }
    await tester.pumpWidget(_routeApp(service));
    await _flushRoute(tester);
    expect(service.requests, hasLength(1));
    expect(_showsFullRoute(tester, route), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Changing the drop-off ignores late old route results and errors',
    (tester) async {
      final service = _PendingRouteService();
      await tester.pumpWidget(_routeApp(service));
      await tester.pumpWidget(_routeApp(service, destination: _secondDropoff));
      await tester.pumpWidget(_routeApp(service, destination: _thirdDropoff));
      expect(service.requests, hasLength(3));

      final current = _roadTo(_thirdDropoff);
      service.requests[2].result.complete(current);
      await _flushRoute(tester);
      expect(_showsFullRoute(tester, current), isTrue);

      final old = _roadTo(_firstDropoff);
      service.requests[0].result.complete(old);
      service.requests[1].result.completeError(
        StateError('Old route unavailable'),
      );
      await _flushRoute(tester);
      expect(_showsFullRoute(tester, current), isTrue);
      expect(_showsFullRoute(tester, old), isFalse);
      expect(find.byKey(const Key('delivery-route-retry')), findsNothing);
      expect(service.requests, hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A failed route can be retried without inventing a route line', (
    tester,
  ) async {
    final service = _PendingRouteService();
    await tester.pumpWidget(_routeApp(service));
    service.requests.single.result.completeError(StateError('Offline'));
    await _flushRoute(tester);
    expect(find.byKey(const Key('delivery-route-loading')), findsNothing);
    final retry = find.byKey(const Key('delivery-route-retry'));
    expect(retry, findsOneWidget);
    expect(
      find.text('No suitable motorcycle route available right now.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('delivery-route-policy')), findsOneWidget);
    expect(_showsFullRoute(tester, _roadTo(_firstDropoff)), isFalse);

    await tester.tap(retry);
    await tester.pump();
    expect(service.requests, hasLength(2));
    expect(find.byKey(const Key('delivery-route-loading')), findsOneWidget);
    final route = _roadTo(_firstDropoff);
    service.requests.last.result.complete(route);
    await _flushRoute(tester);
    expect(find.byKey(const Key('delivery-route-retry')), findsNothing);
    expect(_showsFullRoute(tester, route), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('A route response after disposal is harmless', (tester) async {
    final service = _PendingRouteService();
    await tester.pumpWidget(_routeApp(service));
    await tester.pumpWidget(const SizedBox.shrink());
    service.requests.single.result.complete(_roadTo(_firstDropoff));
    await _flushRoute(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Route motion pauses on request and while the app is backgrounded',
    (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final service = _PendingRouteService();
      await tester.pumpWidget(_routeApp(service));
      service.requests.single.result.complete(_roadTo(_firstDropoff));
      await _flushRoute(tester);
      final initial = _routePainter(tester).animation.value;
      await tester.pump(const Duration(milliseconds: 500));
      expect(_routePainter(tester).animation.value, isNot(initial));
      expect(_routePainter(tester).moving, isTrue);

      await tester.tap(find.byKey(const Key('delivery-route-toggle')));
      await tester.pump();
      expect(find.byTooltip('Play route animation'), findsOneWidget);
      final manuallyPaused = _routePainter(tester).animation.value;
      await tester.pump(const Duration(seconds: 1));
      expect(_routePainter(tester).animation.value, manuallyPaused);

      await tester.tap(find.byKey(const Key('delivery-route-toggle')));
      await tester.pump();
      expect(_routePainter(tester).moving, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final backgroundPaused = _routePainter(tester).animation.value;
      await tester.pump(const Duration(seconds: 1));
      expect(_routePainter(tester).animation.value, backgroundPaused);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_routePainter(tester).moving, isTrue);
      expect(_routePainter(tester).animation.value, isNot(backgroundPaused));
      expect(service.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reduced motion and disabled tickers keep a static road route', (
    tester,
  ) async {
    final service = _PendingRouteService();
    final route = _roadTo(_firstDropoff);
    await tester.pumpWidget(_routeApp(service));
    service.requests.single.result.complete(route);
    await _flushRoute(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_routePainter(tester).moving, isTrue);

    await tester.pumpWidget(
      _routeApp(service, reducedMotion: true, textScale: 2),
    );
    await tester.pump();
    expect(_routePainter(tester).moving, isFalse);
    expect(find.byKey(const Key('delivery-route-toggle')), findsNothing);
    final still = _routePainter(tester).animation.value;
    await tester.pump(const Duration(seconds: 1));
    expect(_routePainter(tester).animation.value, still);
    expect(_showsFullRoute(tester, route), isTrue);

    await tester.pumpWidget(_routeApp(service, tickerEnabled: false));
    await tester.pump();
    final muted = _routePainter(tester).animation.value;
    await tester.pump(const Duration(seconds: 1));
    expect(_routePainter(tester).animation.value, muted);

    await tester.pumpWidget(_routeApp(service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_routePainter(tester).moving, isTrue);
    expect(_routePainter(tester).animation.value, isNot(muted));
    expect(service.requests, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Show full route restores both endpoints after map movement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _PendingRouteService();
    await tester.pumpWidget(
      _routeApp(service, reducedMotion: true, textScale: 2),
    );
    service.requests.single.result.complete(_roadTo(_firstDropoff));
    await _flushRoute(tester);
    final map = tester.widget<FlutterMap>(
      find.byKey(const Key('delivery-route-map')),
    );
    final controller = map.mapController!;
    expect(
      controller.camera.visibleBounds.contains(
        CheckoutValidation.deliveryCenter,
      ),
      isTrue,
    );
    expect(controller.camera.visibleBounds.contains(_firstDropoff), isTrue);
    controller.move(const LatLng(15.0, 121.0), 17);
    await tester.pump();
    expect(controller.camera.visibleBounds.contains(_firstDropoff), isFalse);

    await tester.tap(find.byKey(const Key('delivery-route-fit')));
    await _flushRoute(tester);
    expect(
      controller.camera.visibleBounds.contains(
        CheckoutValidation.deliveryCenter,
      ),
      isTrue,
    );
    expect(controller.camera.visibleBounds.contains(_firstDropoff), isTrue);
    expect(service.requests, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('The route highlight visibly moves along the painted road', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final first = await _rasterHighlight(.4);
      final later = await _rasterHighlight(.7);
      expect(_visiblePixels(first), greaterThan(50));
      expect(_visiblePixels(later), greaterThan(50));
      expect(
        listEquals(first, later),
        isFalse,
        reason:
            'The highlight must visibly travel, not only advance its clock.',
      );
    });
  });
}
