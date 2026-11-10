import 'dart:async';
import 'dart:convert';

import 'package:ecommerce/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  const origin = LatLng(14.3158, 121.0561);
  const destination = LatLng(14.319, 121.06);
  final endpoint = Uri.parse('https://routing.example/route/v1/driving');

  Map<String, Object?> responseBody({
    Object? coordinates = const [
      [121.0561, 14.3158],
      [121.057, 14.317],
      [121.06, 14.319],
    ],
    Object? distance = 820.5,
    Object? duration = 140,
    String type = 'LineString',
  }) => {
    'code': 'Ok',
    'routes': [
      {
        'distance': distance,
        'duration': ?duration,
        'geometry': {'type': type, 'coordinates': coordinates},
      },
    ],
  };

  DeliveryRouteService serviceFor(Object? body, {int status = 200}) {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(body), status),
    );
    addTearDown(client.close);
    return DeliveryRouteService(client: client, endpoint: endpoint);
  }

  group('DeliveryRoute', () {
    test('copies points into immutable geometry', () {
      final points = [origin, destination];
      final route = DeliveryRoute(points: points, distanceMeters: 820.5);
      points.clear();
      expect(route.points, [origin, destination]);
      expect(() => route.points.add(origin), throwsUnsupportedError);
    });

    test('rejects invalid geometry and non-finite metrics', () {
      for (final points in <List<LatLng>>[
        [],
        [origin],
        [origin, const LatLng(91, 121)],
        [origin, const LatLng(14, double.nan)],
      ]) {
        expect(
          () => DeliveryRoute(points: points, distanceMeters: 10),
          throwsStateError,
        );
      }
      for (final distance in [-1.0, double.nan, double.infinity]) {
        expect(
          () => DeliveryRoute(
            points: [origin, destination],
            distanceMeters: distance,
          ),
          throwsStateError,
        );
      }
      expect(
        () => DeliveryRoute(
          points: [origin, destination],
          distanceMeters: 10,
          durationSeconds: double.infinity,
        ),
        throwsStateError,
      );
    });
  });

  group('DeliveryRouteService', () {
    test('requests full GeoJSON in longitude,latitude order', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/route/v1/driving/121.0561,14.3158;121.06,14.319',
        );
        expect(request.url.queryParameters, {
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'false',
          'alternatives': 'false',
        });
        return http.Response(jsonEncode(responseBody()), 200);
      });
      addTearDown(client.close);
      final service = DeliveryRouteService(client: client, endpoint: endpoint);
      final result = await service.route(origin, destination);
      expect(result.points, [
        origin,
        const LatLng(14.317, 121.057),
        destination,
      ]);
      expect(result.distanceMeters, 820.5);
      expect(result.durationSeconds, 140);
    });

    test('allows omitted duration without inventing an ETA', () async {
      final result = await serviceFor(responseBody(duration: null))
          .route(origin, destination);
      expect(result.durationSeconds, isNull);
    });

    test(
      'coalesces concurrent requests and caches successful routes',
      () async {
        final gate = Completer<void>();
        var requests = 0;
        final client = MockClient((_) async {
          requests++;
          await gate.future;
          return http.Response(jsonEncode(responseBody()), 200);
        });
        addTearDown(client.close);
        final service = DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        );
        final first = service.route(origin, destination);
        final concurrent = service.route(origin, destination);
        gate.complete();
        final results = await Future.wait([first, concurrent]);
        final cached = await service.route(origin, destination);
        expect(requests, 1);
        expect(identical(results.first, results.last), isTrue);
        expect(identical(cached, results.first), isTrue);
      },
    );

    test(
      'does not cache failed requests and permits an explicit retry',
      () async {
        var requests = 0;
        final client = MockClient((_) async {
          requests++;
          return requests == 1
              ? http.Response('{"code":"NoRoute"}', 200)
              : http.Response(jsonEncode(responseBody()), 200);
        });
        addTearDown(client.close);
        final service = DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        );
        await expectLater(service.route(origin, destination), throwsStateError);
        expect((await service.route(origin, destination)).points, hasLength(3));
        expect(requests, 2);
      },
    );

    test('expires cached road geometry after ten minutes', () async {
      var now = DateTime.utc(2026, 11, 10, 12);
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(responseBody()), 200);
      });
      addTearDown(client.close);
      final service = DeliveryRouteService(
        client: client,
        endpoint: endpoint,
        clock: () => now,
      );
      await service.route(origin, destination);
      now = now.add(const Duration(minutes: 9));
      await service.route(origin, destination);
      expect(requests, 1);
      now = now.add(const Duration(minutes: 1));
      await service.route(origin, destination);
      expect(requests, 2);
    });

    test(
      'evicts the least recently used route when its cache reaches 24',
      () async {
        var requests = 0;
        final client = MockClient((_) async {
          requests++;
          return http.Response(jsonEncode(responseBody()), 200);
        });
        addTearDown(client.close);
        final service = DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        );
        LatLng point(int index) => LatLng(14.32 + index * .0001, 121.06);
        for (var index = 0; index < 24; index++) {
          await service.route(origin, point(index));
        }
        await service.route(origin, point(0));
        await service.route(origin, point(24));
        await service.route(origin, point(0));
        expect(requests, 25);
        await service.route(origin, point(1));
        expect(requests, 26);
      },
    );

    test('rejects invalid input before making a network request', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(responseBody()), 200);
      });
      addTearDown(client.close);
      final service = DeliveryRouteService(client: client, endpoint: endpoint);
      for (final point in const [
        LatLng(double.nan, 121),
        LatLng(14, double.infinity),
        LatLng(91, 121),
        LatLng(14, 181),
      ]) {
        await expectLater(service.route(origin, point), throwsStateError);
      }
      expect(requests, 0);
    });

    final invalidBodies = <String, Object?>{
      'no route': {'code': 'NoRoute'},
      'empty routes': {'code': 'Ok', 'routes': <Object?>[]},
      'wrong root type': [],
      'wrong geometry type': responseBody(type: 'MultiLineString'),
      'one point': responseBody(
        coordinates: [
          [121.0561, 14.3158],
        ],
      ),
      'wrong coordinate order or bounds': responseBody(
        coordinates: [
          [14.3158, 121.0561],
          [14.319, 121.06],
        ],
      ),
      'non-numeric coordinate': responseBody(
        coordinates: [
          ['121', 14.3],
          [121.06, 14.319],
        ],
      ),
      'missing distance': responseBody(distance: null),
      'negative distance': responseBody(distance: -1),
      'non-numeric duration': responseBody(duration: 'unknown'),
      'negative duration': responseBody(duration: -1),
    };
    for (final entry in invalidBodies.entries) {
      test('rejects ${entry.key} without a fabricated line', () async {
        await expectLater(
          serviceFor(entry.value).route(origin, destination),
          throwsStateError,
        );
      });
    }

    test('rejects HTTP errors and malformed JSON', () async {
      await expectLater(
        serviceFor(responseBody(), status: 503).route(origin, destination),
        throwsStateError,
      );
      final client = MockClient(
        (_) async => http.Response('<html>offline', 200),
      );
      addTearDown(client.close);
      await expectLater(
        DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        ).route(origin, destination),
        throwsStateError,
      );
    });

    test('rejects oversized responses before parsing them', () async {
      final client = MockClient(
        (_) async => http.Response(' ' * (512 * 1024 + 1), 200),
      );
      addTearDown(client.close);
      await expectLater(
        DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        ).route(origin, destination),
        throwsStateError,
      );
    });

    test('rejects excessive route coordinates', () async {
      final body = responseBody(
        coordinates: List.generate(10001, (_) => [121.0561, 14.3158]),
      );
      await expectLater(
        serviceFor(body).route(origin, destination),
        throwsStateError,
      );
    });

    test('converts network failures to a route error', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      addTearDown(client.close);
      await expectLater(
        DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        ).route(origin, destination),
        throwsStateError,
      );
    });

    testWidgets('times out a stalled request after eight seconds', (
      tester,
    ) async {
      final response = Completer<http.Response>();
      final client = MockClient((_) => response.future);
      addTearDown(client.close);
      final service = DeliveryRouteService(client: client, endpoint: endpoint);
      var finished = false;
      final expectation = expectLater(
        service.route(origin, destination),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('timed out'),
          ),
        ),
      ).then((_) => finished = true);
      await tester.pump(const Duration(milliseconds: 7999));
      expect(finished, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      await expectation;
      response.complete(http.Response(jsonEncode(responseBody()), 200));
      await tester.pump();
    });
  });
}
