import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecommerce/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _startupImages = {'assets/images/logo.png'};

// Former preload-only artwork remains available locally, but is neither
// decoded at startup nor shipped now that no screen displays it.
const _retainedUnbundledImages = {
  'assets/images/landing1.png',
  'assets/images/Ice Blended Choco Hazelnut transparent.png',
};

const _removedUnusedExamples = {
  'assets/images/1.png',
  'assets/images/landing2.png',
  'assets/images/Americano.png',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> bundledImages;
  final catalogImages = cafeProducts.map((product) => product.image).toSet();
  final requiredImages = {...catalogImages, ..._startupImages};

  setUpAll(() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    bundledImages = manifest
        .listAssets()
        .where((asset) => asset.startsWith('assets/images/'))
        .toSet();
  });

  test(
    'The Flutter bundle includes the catalog and intentional startup images',
    () {
      expect(catalogImages, isNotEmpty);
      for (final product in cafeProducts) {
        expect(
          bundledImages,
          contains(product.image),
          reason: '${product.name} must retain its product image.',
        );
      }
      expect(bundledImages, containsAll(_startupImages));
      expect(
        bundledImages,
        unorderedEquals(requiredImages),
        reason: 'Only images referenced by the app belong in its image bundle.',
      );

      const apostropheImage = "assets/images/Hershey's Crinkles 1.png";
      expect(catalogImages, contains(apostropheImage));
      expect(
        bundledImages,
        contains(apostropheImage),
        reason: 'The YAML filename must preserve the literal apostrophe.',
      );
    },
  );

  test('Every catalog and startup image loads and decodes from the real bundle', () async {
    for (final asset in requiredImages) {
      try {
        final bytes = await rootBundle.load(asset);
        expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
        // Small sequential decodes validate the actual formats without holding
        // the full catalog at native resolution in the test process.
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          targetWidth: 64,
        );
        try {
          final frame = await codec.getNextFrame();
          try {
            expect(frame.image.width, greaterThan(0), reason: asset);
            expect(frame.image.height, greaterThan(0), reason: asset);
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } catch (error) {
        fail('Bundled image "$asset" could not load or decode: $error');
      }
    }
  });

  test('Optimized WebP products retain sufficient detail resolution', () async {
    final optimized = catalogImages.where((image) => image.endsWith('.webp'));
    expect(optimized, isNotEmpty);
    for (final asset in optimized) {
      final bytes = await rootBundle.load(asset);
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          expect(descriptor.width, inInclusiveRange(640, 1024), reason: asset);
          expect(descriptor.height, inInclusiveRange(640, 1024), reason: asset);
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    }
  });

  test(
    'Only required images are bundled; former preload artwork stays local',
    () {
      for (final asset in _removedUnusedExamples) {
        expect(
          File(asset).existsSync(),
          isFalse,
          reason: 'Verified unused images were removed: $asset',
        );
        expect(requiredImages, isNot(contains(asset)));
      }
      for (final asset in _retainedUnbundledImages) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
        expect(bundledImages, isNot(contains(asset)));
      }
      final sourceImages = Directory('assets/images')
          .listSync(followLinks: false)
          .whereType<File>()
          .map((file) => 'assets/images/${file.uri.pathSegments.last}')
          .toSet();
      expect(
        sourceImages,
        unorderedEquals({...requiredImages, ..._retainedUnbundledImages}),
        reason: 'All required images and retained local artwork must remain.',
      );
    },
  );
}
