import 'dart:async';
import 'dart:convert';

import 'package:ecommerce/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart' show LatLng;

String shapeFor(List<List<num>> points) {
  final encoded = StringBuffer();
  var previousLat = 0, previousLon = 0;
  void append(int delta) {
    var value = delta < 0 ? -delta * 2 - 1 : delta * 2;
    while (value >= 32) {
      encoded.writeCharCode((32 | (value & 31)) + 63);
      value >>= 5;
    }
    encoded.writeCharCode(value + 63);
  }

  for (final point in points) {
    final lat = (point[0] * 1e6).round(), lon = (point[1] * 1e6).round();
    append(lat - previousLat);
    append(lon - previousLon);
    previousLat = lat;
    previousLon = lon;
  }
  return encoded.toString();
}

void main() {
  const origin = LatLng(14.3158, 121.0561);
  const destination = LatLng(14.319, 121.06);
  final endpoint = Uri.parse('https://routing.example/route');

  Map<String, Object?> responseBody({
    Object? shape,
    Object? distance = 820.5,
    Object? duration = 140,
    Object? highway = false,
    Object? toll = false,
    Object? ferry = false,
  }) => {
    'trip': {
      'status': 0,
      'units': 'kilometers',
      'summary': {
        'length': distance is num ? distance / 1000 : distance,
        'time': ?duration,
        'has_highway': highway,
        'has_toll': toll,
        'has_ferry': ferry,
      },
      'legs': [
        {
          'shape':
              shape ??
              shapeFor(const [
                [14.3158, 121.0561],
                [14.317, 121.057],
                [14.319, 121.06],
              ]),
          'summary': {
            'length': distance is num ? distance / 1000 : distance,
            'time': ?duration,
            'has_highway': highway,
            'has_toll': toll,
            'has_ferry': ferry,
          },
          'maneuvers': [
            {'travel_mode': 'drive', 'travel_type': 'motor_scooter'},
          ],
        },
      ],
    },
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
    Map<String, Object?> tripOf(Map<String, Object?> body) =>
        body['trip']! as Map<String, Object?>;
    Map<String, Object?> legOf(Map<String, Object?> body) =>
        (tripOf(body)['legs']! as List<Object?>).single!
            as Map<String, Object?>;

    test('rejects restricted leg flags even when the trip summary claims clean roads', () async {
      for (final flag in ['has_highway', 'has_toll', 'has_ferry']) {
        final body = responseBody();
        final summary = legOf(body)['summary']! as Map<String, Object?>;
        summary[flag] = true;
        await expectLater(
          serviceFor(body).route(origin, destination),
          throwsStateError,
        );
      }
    });

    test('rejects a car or unknown travel profile instead of accepting a clean-looking summary', () async {
      for (final profile in ['car', 'motorcycle', 'bicycle', null]) {
        final body = responseBody();
        legOf(body)['maneuvers'] = [
          {'travel_mode': 'drive', 'travel_type': profile},
        ];
        await expectLater(
          serviceFor(body).route(origin, destination),
          throwsStateError,
        );
      }
    });

    test('rejects highway, toll and ferry maneuvers even when summary flags disagree', () async {
      for (final flag in ['highway', 'toll', 'ferry']) {
        final body = responseBody();
        legOf(body)['maneuvers'] = [
          {'travel_mode': 'drive', 'travel_type': 'motor_scooter', flag: true},
        ];
        await expectLater(
          serviceFor(body).route(origin, destination),
          throwsStateError,
        );
      }
    });

    test(
      'rejects missing access information, unexpected legs and wrong units',
      () async {
        final bodies = [
          responseBody()..update(
            'trip',
            (trip) => (trip! as Map<String, Object?>)..['units'] = 'miles',
          ),
          responseBody()..update(
            'trip',
            (trip) => (trip! as Map<String, Object?>)..['legs'] = <Object?>[],
          ),
        ];
        for (final maneuvers in [<Object?>[], null]) {
          final body = responseBody();
          if (maneuvers == null) {
            legOf(body).remove('maneuvers');
          } else {
            legOf(body)['maneuvers'] = maneuvers;
          }
          bodies.add(body);
        }
        for (final body in bodies) {
          await expectLater(
            serviceFor(body).route(origin, destination),
            throwsStateError,
          );
        }
      },
    );

    test('an ignored-exclusions warning is accepted only with verified clean scooter metadata', () async {
      final body = responseBody();
      tripOf(body)['warnings'] = [
        {
          'code': 208,
          'text': 'Hard exclusions are not allowed on this server, ignoring hard excludes',
        },
      ];
      expect(
        (await serviceFor(body).route(origin, destination)).distanceMeters,
        820.5,
      );
      final summary = tripOf(body)['summary']! as Map<String, Object?>;
      summary['has_highway'] = true;
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(body), 200);
      });
      addTearDown(client.close);
      final service = DeliveryRouteService(client: client, endpoint: endpoint);
      await expectLater(service.route(origin, destination), throwsStateError);
      expect(
        requests,
        1,
        reason: 'A rejected route must not trigger a car/bike fallback.',
      );
    });

    test(
      'endpoint query settings cannot replace the scooter request payload',
      () async {
        final client = MockClient((request) async {
          final payload = jsonDecode(
            request.url.queryParameters['json']!,
          ) as Map<String, dynamic>;
          expect(payload['costing'], 'motor_scooter');
          expect(payload['units'], 'kilometers');
          return http.Response(jsonEncode(responseBody()), 200);
        });
        addTearDown(client.close);
        final service = DeliveryRouteService(
          client: client,
          endpoint: Uri.parse(
            'https://routing.example/route?json=%7B%22costing%22:%22auto%22%7D',
          ),
        );
        await service.route(origin, destination);
      },
    );

    test(
      'requests a scooter route with expressway, toll and endpoint exclusions',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/route');
          final input = jsonDecode(
            request.url.queryParameters['json']!,
          ) as Map<String, dynamic>;
          expect(input['locations'], [
            for (final point in [origin, destination])
              {
                'lat': point.latitude,
                'lon': point.longitude,
                'type': 'break',
                'search_filter': {
                  'max_road_class': 'trunk',
                  'exclude_toll': true,
                  'exclude_ferry': true,
                },
              },
          ]);
          expect(input['costing'], 'motor_scooter');
          expect(input['units'], 'kilometers');
          expect(input['alternates'], 0);
          expect(input['directions_type'], 'instructions');
          expect(input['costing_options'], {
            'motor_scooter': {
              'exclude_highways': true,
              'exclude_tolls': true,
              'exclude_ferries': true,
              'use_highways': 0,
              'use_tolls': 0,
            },
          });
          expect(request.headers['X-Client-Id'], 'SmoochCafeFlutter/1.0');
          return http.Response(jsonEncode(responseBody()), 200);
        });
        addTearDown(client.close);
        final service = DeliveryRouteService(
          client: client,
          endpoint: endpoint,
        );
        final result = await service.route(origin, destination);
        expect(result.points, [
          origin,
          const LatLng(14.317, 121.057),
          destination,
        ]);
        expect(result.distanceMeters, 820.5);
        expect(result.durationSeconds, 140);
      },
    );

    test('allows omitted duration without inventing an ETA', () async {
      final result = await serviceFor(responseBody(duration: null))
          .route(origin, destination);
      expect(result.durationSeconds, isNull);
    });

    test(
      'decodes southbound and westbound polyline deltas on native and web',
      () async {
        final points = const [
          [14.3158, 121.0561],
          [14.3157, 121.0559],
          [14.3159, 121.0562],
        ];
        final route = await serviceFor(responseBody(shape: shapeFor(points)))
            .route(origin, destination);
        expect(route.points, [
          const LatLng(14.3158, 121.0561),
          const LatLng(14.3157, 121.0559),
          const LatLng(14.3159, 121.0562),
        ]);
      },
    );

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
      'no route': {'error_code': 442, 'error': 'No path could be found'},
      'legacy car response': {'code': 'Ok', 'routes': <Object?>[]},
      'wrong root type': [],
      'wrong geometry type': responseBody(shape: <String, Object?>{}),
      'one point': responseBody(
        shape: shapeFor(const [
          [14.3158, 121.0561],
        ]),
      ),
      'wrong coordinate order or bounds': responseBody(
        shape: shapeFor(const [
          [121.0561, 14.3158],
          [121.06, 14.319],
        ]),
      ),
      'invalid shape characters': responseBody(shape: '!!'),
      'truncated shape': responseBody(shape: '_'),
      'overflowing shape component': responseBody(shape: '~~~~~~~~~~~~?'),
      'motorway segments': responseBody(highway: true),
      'toll segments': responseBody(toll: true),
      'ferry segments': responseBody(ferry: true),
      'missing highway classification': responseBody(highway: null),
      'missing toll classification': responseBody(toll: null),
      'malformed safety flags': responseBody(highway: 'false'),
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
        shape: shapeFor(List.generate(10001, (_) => [14.3158, 121.0561])),
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
