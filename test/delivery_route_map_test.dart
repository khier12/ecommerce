import 'dart:async';
import 'dart:math' as math;

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

OrderReceipt _order(DateTime createdAt) => OrderReceipt(
  reference: 'SMC-RIDER',
  items: const [],
  customerName: 'Ana Cruz',
  mobileNumber: '09171234567',
  notes: '',
  paymentMethod: PaymentMethod.cash,
  createdAt: createdAt,
  fulfillment: FulfillmentMethod.delivery,
  deliveryAddress: 'Carmona',
  deliveryLatitude: _firstDropoff.latitude,
  deliveryLongitude: _firstDropoff.longitude,
);
final _defaultOrder = _order(DateTime.now());

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
  OrderTimeline? timeline,
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
        child: Column(
          children: [
            if (timeline != null)
              OrderTracking(
                order: timeline.order,
                timeline: timeline,
                compact: true,
              ),
            DeliveryRouteMap(
              order: timeline?.order ?? _defaultOrder,
              timeline: timeline,
              destination: destination,
              routeService: service,
            ),
          ],
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

Offset _motorcyclePosition(WidgetTester tester) {
  final matrix = tester
      .widget<Transform>(find.byKey(const Key('delivery-motorcycle')))
      .transform;
  return Offset(matrix.storage[12], matrix.storage[13]);
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
    expect(mapSize.height, 260);
    expect(find.byKey(const Key('delivery-motorcycle')), findsNothing);
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
    'Rider waits at store, travels only on the way, then holds for one second',
    (tester) async {
      final timeline = OrderTimeline(
        order: _order(tester.binding.clock.now()),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      final service = _PendingRouteService();
      await tester.pumpWidget(_routeApp(service, timeline: timeline));
      service.requests.single.result.complete(_roadTo(_firstDropoff));
      await _flushRoute(tester);
      expect(find.byKey(const Key('delivery-motorcycle')), findsNothing);
      await tester.pump(const Duration(milliseconds: 19950));
      expect(timeline.stage, OrderStage.riderAssigned);
      expect(find.text('Rider assigned'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as ResizeImage).imageProvider,
        const AssetImage(deliveryMotorcycleAsset),
      );
      final store = _motorcyclePosition(tester);
      await tester.pump(const Duration(seconds: 5));
      expect(_motorcyclePosition(tester), store);
      expect(timeline.rider.isAnimating, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(timeline.stage, OrderStage.onTheWay);
      expect(find.text('On the way'), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(timeline.rider.value, closeTo(.5, .001));
      expect(_motorcyclePosition(tester), isNot(store));
      await tester.pump(const Duration(seconds: 4));
      expect(timeline.rider.value, 1);
      expect(timeline.stage, OrderStage.onTheWay);
      final arrived = _motorcyclePosition(tester);
      await tester.pump(const Duration(milliseconds: 999));
      expect(timeline.stage, OrderStage.onTheWay);
      expect(_motorcyclePosition(tester), arrived);
      await tester.pump(const Duration(milliseconds: 1));
      expect(timeline.stage, OrderStage.delivered);
      expect(find.text('Delivered'), findsOneWidget);
      expect(_motorcyclePosition(tester), arrived);
      await tester.pump(const Duration(seconds: 20));
      expect(_motorcyclePosition(tester), arrived);
      expect(timeline.rider.isAnimating, isFalse);
      expect(service.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      timeline.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduced motion keeps the rider static without delaying delivery',
    (tester) async {
      final service = _PendingRouteService();
      final route = _roadTo(_firstDropoff);
      final timeline = OrderTimeline(
        order: _order(
          tester.binding.clock.now().subtract(const Duration(seconds: 30)),
        ),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      await tester.pumpWidget(_routeApp(service, timeline: timeline));
      service.requests.single.result.complete(route);
      await _flushRoute(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(timeline.rider.isAnimating, isTrue);

      await tester.pumpWidget(
        _routeApp(
          service,
          timeline: timeline,
          reducedMotion: true,
          textScale: 2,
        ),
      );
      await tester.pump();
      expect(timeline.rider.isAnimating, isFalse);
      expect(find.byKey(const Key('delivery-route-toggle')), findsNothing);
      final still = _motorcyclePosition(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_motorcyclePosition(tester), still);
      expect(_showsFullRoute(tester, route), isTrue);

      await tester.pumpWidget(
        _routeApp(service, timeline: timeline, tickerEnabled: false),
      );
      await tester.pump();
      final muted = _motorcyclePosition(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_motorcyclePosition(tester), muted);

      await tester.pumpWidget(_routeApp(service, timeline: timeline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(timeline.rider.isAnimating, isTrue);
      expect(_motorcyclePosition(tester), isNot(muted));
      await tester.pumpWidget(
        _routeApp(service, timeline: timeline, reducedMotion: true),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(timeline.rider.value, 1);
      expect(timeline.stage, OrderStage.onTheWay);
      await tester.pump(const Duration(seconds: 1));
      expect(timeline.stage, OrderStage.delivered);
      expect(service.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      timeline.dispose();
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('A late road response joins the trip instead of restarting it', (
    tester,
  ) async {
    final timeline = OrderTimeline(
      order: _order(
        tester.binding.clock.now().subtract(const Duration(seconds: 20)),
      ),
      vsync: tester,
      now: tester.binding.clock.now,
    );
    final service = _PendingRouteService();
    await tester.pumpWidget(_routeApp(service, timeline: timeline));
    expect(find.byKey(const Key('delivery-motorcycle')), findsOneWidget);
    await tester.pump(const Duration(seconds: 14));
    expect(timeline.stage, OrderStage.onTheWay);
    expect(find.byKey(const Key('delivery-motorcycle')), findsNothing);
    service.requests.single.result.complete(_roadTo(_firstDropoff));
    await _flushRoute(tester);
    expect(timeline.rider.value, closeTo(.5, .01));
    expect(find.byKey(const Key('delivery-motorcycle')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(timeline.rider.value, 1);
    expect(timeline.stage, OrderStage.onTheWay);
    await tester.pump(const Duration(seconds: 1));
    expect(timeline.stage, OrderStage.delivered);
    await tester.pumpWidget(const SizedBox.shrink());
    timeline.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Backgrounding stops frame updates and resumes at current order time',
    (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final timeline = OrderTimeline(
        order: _order(
          tester.binding.clock.now().subtract(const Duration(seconds: 30)),
        ),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      final service = _PendingRouteService();
      await tester.pumpWidget(_routeApp(service, timeline: timeline));
      service.requests.single.result.complete(_roadTo(_firstDropoff));
      await _flushRoute(tester);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(timeline.rider.isAnimating, isFalse);
      final stopped = _motorcyclePosition(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(_motorcyclePosition(tester), stopped);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(timeline.rider.value, closeTo(5.05 / 8, .002));
      expect(_motorcyclePosition(tester), isNot(stopped));
      expect(timeline.rider.isAnimating, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(timeline.stage, OrderStage.delivered);
      expect(timeline.rider.value, 1);
      expect(timeline.rider.isAnimating, isFalse);
      expect(service.requests, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      timeline.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Saved trips resume their position and delivered trips never replay',
    (tester) async {
      final service = _PendingRouteService();
      final timeline = OrderTimeline(
        order: _order(
          tester.binding.clock.now().subtract(const Duration(seconds: 34)),
        ),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      await tester.pumpWidget(_routeApp(service, timeline: timeline));
      service.requests.single.result.complete(_roadTo(_firstDropoff));
      await _flushRoute(tester);
      expect(timeline.rider.value, closeTo(.5, .01));
      expect(timeline.stage, OrderStage.onTheWay);
      await tester.pumpWidget(const SizedBox.shrink());
      timeline.dispose();
      final delivered = OrderTimeline(
        order: _order(
          tester.binding.clock.now().subtract(const Duration(minutes: 2)),
        ),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      await tester.pumpWidget(_routeApp(service, timeline: delivered));
      service.requests.last.result.complete(_roadTo(_firstDropoff));
      await _flushRoute(tester);
      expect(delivered.stage, OrderStage.delivered);
      final destination = _motorcyclePosition(tester);
      await tester.pump(const Duration(seconds: 15));
      expect(_motorcyclePosition(tester), destination);
      expect(delivered.rider.isAnimating, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      delivered.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Motorcycle center stays on the visible road after pan, zoom and rotation',
    (tester) async {
      final timeline = OrderTimeline(
        order: _order(
          tester.binding.clock.now().subtract(const Duration(seconds: 34)),
        ),
        vsync: tester,
        now: tester.binding.clock.now,
      );
      final service = _PendingRouteService();
      await tester.pumpWidget(
        _routeApp(service, timeline: timeline, tickerEnabled: false),
      );
      // Equal horizontal legs place half the road distance exactly at the middle
      // of the vertical leg, independent of camera rotation and zoom.
      final road = DeliveryRoute(
        points: const [
          LatLng(14.3158, 121.0561),
          LatLng(14.3158, 121.0661),
          LatLng(14.3258, 121.0661),
          LatLng(14.3258, 121.0561),
        ],
        distanceMeters: 3000,
      );
      service.requests.single.result.complete(road);
      await _flushRoute(tester);
      final map = tester.widget<FlutterMap>(
        find.byKey(const Key('delivery-route-map')),
      );
      final controller = map.mapController!;
      void checkAlignment() {
        final camera = controller.camera;
        final expected =
            (camera.latLngToScreenOffset(road.points[1]) +
                camera.latLngToScreenOffset(road.points[2])) /
            2;
        final actual = _motorcyclePosition(tester) + const Offset(24, 24);
        expect((actual - expected).distance, lessThan(.02));
      }

      expect(timeline.rider.value, .5);
      checkAlignment();
      controller.move(const LatLng(14.321, 121.06), 15);
      await tester.pump();
      checkAlignment();
      controller.rotate(73);
      await tester.pump();
      checkAlignment();
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.simplificationTolerance, 0);
      expect(layer.polylines.single.points, road.points);
      await tester.pumpWidget(const SizedBox.shrink());
      timeline.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Snapped road endpoints do not create off-road shortcuts', (
    tester,
  ) async {
    final timeline = OrderTimeline(
      order: _order(
        tester.binding.clock.now().subtract(const Duration(seconds: 30)),
      ),
      vsync: tester,
      now: tester.binding.clock.now,
    );
    final service = _PendingRouteService();
    await tester.pumpWidget(
      _routeApp(service, timeline: timeline, tickerEnabled: false),
    );
    const snappedStart = LatLng(14.317, 121.057);
    final road = DeliveryRoute(
      points: const [snappedStart, _firstDropoff],
      distanceMeters: 800,
    );
    service.requests.single.result.complete(road);
    await _flushRoute(tester);
    final camera = tester
        .widget<FlutterMap>(find.byKey(const Key('delivery-route-map')))
        .mapController!
        .camera;
    final actual = _motorcyclePosition(tester) + const Offset(24, 24);
    expect(
      (actual - camera.latLngToScreenOffset(snappedStart)).distance,
      lessThan(.01),
    );
    expect(
      (actual - camera.latLngToScreenOffset(CheckoutValidation.deliveryCenter))
          .distance,
      greaterThan(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    timeline.dispose();
    expect(tester.takeException(), isNull);
  });

  test(
    'Motorcycle faces each road direction and stays upright when westbound',
    () {
      for (final sample in <(Offset, double, bool)>[
        (const Offset(100, 0), 0, false),
        (const Offset(0, -100), -math.pi / 2, false),
        (const Offset(0, 100), math.pi / 2, false),
        (const Offset(-100, 0), math.pi, true),
      ]) {
        final pose = DeliveryRiderPath([Offset.zero, sample.$1]).poseAt(.5);
        expect(pose.heading, closeTo(sample.$2, .0001));
        expect(pose.facesLeft, sample.$3);
        expect(pose.rotation.abs(), lessThanOrEqualTo(math.pi / 2));
        final front =
            Offset(math.cos(pose.rotation), math.sin(pose.rotation)) *
            (pose.facesLeft ? -1 : 1);
        final travel = sample.$1 / sample.$1.distance;
        expect((front - travel).distance, lessThan(.0001));
      }
    },
  );

  test(
    'Heading eases through a corner without rounding the motorcycle position',
    () {
      final path = DeliveryRiderPath(const [
        Offset.zero,
        Offset(100, 0),
        Offset(100, -100),
      ]);
      final before = path.poseAt(.49);
      final corner = path.poseAt(.5);
      final after = path.poseAt(.51);
      expect(before.position, const Offset(98, 0));
      expect(corner.position, const Offset(100, 0));
      expect(after.position, const Offset(100, -2));
      expect(before.heading, lessThan(0));
      expect(before.heading, greaterThan(corner.heading));
      expect(corner.heading, closeTo(-math.pi / 4, .001));
      expect(after.heading, lessThan(corner.heading));
      expect(after.heading, greaterThan(-math.pi / 2));
    },
  );

  test(
    'The motorcycle follows road corners at a steady distance per frame',
    () {
      final path = DeliveryRiderPath(const [
        Offset(20, 100),
        Offset(120, 100),
        Offset(120, 180),
        Offset(270, 180),
      ]);
      expect(path.positionAt(0), const Offset(20, 100));
      expect(path.positionAt(100 / 330), const Offset(120, 100));
      expect(path.positionAt(140 / 330), const Offset(120, 140));
      expect(path.positionAt(1), const Offset(270, 180));
      expect(
        DeliveryRiderPath(const [Offset(4, 6), Offset(4, 6)]).positionAt(.5),
        const Offset(4, 6),
      );
    },
  );
}
