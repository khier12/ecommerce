import 'dart:ui' as ui;

import 'package:ecommerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _pixels(CoffeeScenePainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return List<int>.of(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  testWidgets(
    'Retained scene buffers match fresh rendering across phase, size and motion changes',
    (tester) async {
      const poses = [
        (Size(320, 360), 1.0, 0.0, false),
        (Size(320, 360), 1.0, .25, false),
        (Size(500, 460), 1.0, .5, false),
        (Size(320, 360), .12, .75, false),
        (Size(500, 460), .5, .2, false),
        (Size(320, 360), 1.0, .8, true),
        (Size(320, 360), 1.0, .75, false),
        (Size(320, 360), 1.0, 0.0, false),
      ];
      Object? retainedState;
      for (final (size, progress, phase, reduced) in poses) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CoffeeSceneViewport(
                  key: const Key('reused-scene'),
                  entrance: AlwaysStoppedAnimation(progress),
                  idle: AlwaysStoppedAnimation(phase),
                  reducedMotion: reduced,
                ),
              ),
            ),
          ),
        );
        final state = tester.state(find.byKey(const Key('reused-scene')));
        retainedState ??= state;
        expect(identical(state, retainedState), isTrue);
        CoffeeScenePainter current() =>
            tester
                    .widget<CustomPaint>(find.byKey(const Key('coffee-scene')))
                    .painter!
                as CoffeeScenePainter;
        // Decode the real logo, rather than substituting a test texture.
        for (
          var attempt = 0;
          attempt < 100 && current().logoShader == null;
          attempt++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        final reused = current();
        expect(reused.logoShader, isNotNull);
        expect(reused.latteShader, isNotNull);
        final fresh = CoffeeScenePainter(
          progress: reused.progress,
          idlePhase: reused.idlePhase,
          reducedMotion: reused.reducedMotion,
          interaction: reused.interaction,
          logoShader: reused.logoShader,
          logoSize: reused.logoSize,
          latteShader: reused.latteShader,
        );
        await tester.runAsync(() async {
          final actual = await _pixels(reused, size);
          final expected = await _pixels(fresh, size);
          var changed = 0;
          for (var i = 0; i < actual.length; i++) {
            if (actual[i] != expected[i]) changed++;
          }
          expect(
            changed,
            0,
            reason:
                'No stale projection, UV, color or index data at $size / $progress / $phase / reduced=$reduced.',
          );
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
