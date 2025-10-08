import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photos/ui/tools/editor/video_crop_util.dart';

void main() {
  // Coordinate space primer:
  // - Normalized crop uses [0,1] fractions relative to the oriented video.
  // - Display space converts those fractions to pixel coordinates (dimensions
  //   swap when Android metadata rotation is 90°/270°).
  // - File space represents the actual encoded frame orientation and is what
  //   native export paths consume.

  group('VideoCropUtil.calculateDisplaySpaceCropRectFromData', () {
    test('returns swapped dimensions for Android 90° rotation', () {
      final rect = VideoCropUtil.calculateDisplaySpaceCropRectFromData(
        minCrop: const Offset(0.25, 0.25),
        maxCrop: const Offset(0.75, 0.75),
        videoSize: const Size(1920, 1080),
        metadataRotation: 90,
        isAndroidOverride: true,
      );

      expect(rect.left, closeTo(270, 0.0001));
      expect(rect.top, closeTo(480, 0.0001));
      expect(rect.width, closeTo(540, 0.0001));
      expect(rect.height, closeTo(960, 0.0001));
    });

    test('throws when crop collapses to zero span', () {
      expect(
        () => VideoCropUtil.calculateDisplaySpaceCropRectFromData(
          minCrop: const Offset(0.5, 0.5),
          maxCrop: const Offset(0.5, 0.5),
          videoSize: const Size(1920, 1080),
          metadataRotation: 0,
          isAndroidOverride: true,
        ),
        throwsA(isA<VideoCropException>()),
      );
    });

    test('handles non-square crop for Android 90° rotation', () {
      final rect = VideoCropUtil.calculateDisplaySpaceCropRectFromData(
        minCrop: const Offset(0.1, 0.2),
        maxCrop: const Offset(0.4, 0.8),
        videoSize: const Size(1920, 1080),
        metadataRotation: 90,
        isAndroidOverride: true,
      );

      expect(rect.left, closeTo(108, 0.0001));
      expect(rect.top, closeTo(384, 0.0001));
      expect(rect.width, closeTo(324, 0.0001));
      expect(rect.height, closeTo(1152, 0.0001));
    });

    test('handles 180° rotation without swapping dimensions', () {
      final rect = VideoCropUtil.calculateDisplaySpaceCropRectFromData(
        minCrop: const Offset(0.1, 0.3),
        maxCrop: const Offset(0.5, 0.9),
        videoSize: const Size(1920, 1080),
        metadataRotation: 180,
        isAndroidOverride: true,
      );

      expect(rect.left, closeTo(192.0, 0.0001));
      expect(rect.top, closeTo(324.0, 0.0001));
      expect(rect.width, closeTo(768.0, 0.0001));
      expect(rect.height, closeTo(648.0, 0.0001));
    });

    test('handles full frame crop (0,0 → 1,1)', () {
      final rect = VideoCropUtil.calculateDisplaySpaceCropRectFromData(
        minCrop: Offset.zero,
        maxCrop: const Offset(1, 1),
        videoSize: const Size(1920, 1080),
        metadataRotation: 0,
        isAndroidOverride: false,
      );

      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 1920);
      expect(rect.height, 1080);
    });
  });

  group('VideoCropUtil.calculateFileSpaceCropFromData', () {
    test('maps Android 90° rotation crop into file space', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.25, 0.25),
        maxCrop: const Offset(0.75, 0.75),
        videoSize: const Size(1920, 1080),
        metadataRotation: 90,
        isAndroidOverride: true,
      );

      expect(crop.x, 480);
      expect(crop.y, 270);
      expect(crop.width, 960);
      expect(crop.height, 540);
    });

    test('maps Android 270° rotation crop into file space', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.25, 0.25),
        maxCrop: const Offset(0.75, 0.75),
        videoSize: const Size(1920, 1080),
        metadataRotation: 270,
        isAndroidOverride: true,
      );

      expect(crop.x, 480);
      expect(crop.y, 270);
      expect(crop.width, 960);
      expect(crop.height, 540);
    });

    test('returns direct file-space crop for non-Android platforms', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.25, 0.25),
        maxCrop: const Offset(0.75, 0.75),
        videoSize: const Size(1920, 1080),
        metadataRotation: 0,
        isAndroidOverride: false,
      );

      expect(crop.x, 480);
      expect(crop.y, 270);
      expect(crop.width, 960);
      expect(crop.height, 540);
    });

    test('throws when rotation transform collapses crop', () {
      expect(
        () => VideoCropUtil.calculateFileSpaceCropFromData(
          minCrop: const Offset(0.0, 0.0),
          maxCrop: const Offset(0.1, 0.0),
          videoSize: const Size(1920, 1080),
          metadataRotation: 90,
          isAndroidOverride: true,
        ),
        throwsA(isA<VideoCropException>()),
      );
    });

    test('handles non-square crop for Android 90° rotation', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.1, 0.2),
        maxCrop: const Offset(0.4, 0.8),
        videoSize: const Size(1920, 1080),
        metadataRotation: 90,
        isAndroidOverride: true,
      );

      expect(crop.x, 384);
      expect(crop.y, 108);
      expect(crop.width, 1152);
      expect(crop.height, 324);
    });

    test('handles non-square crop for Android 270° rotation', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.1, 0.2),
        maxCrop: const Offset(0.4, 0.8),
        videoSize: const Size(1920, 1080),
        metadataRotation: 270,
        isAndroidOverride: true,
      );

      expect(crop.x, 384);
      expect(crop.y, 648);
      expect(crop.width, 1152);
      expect(crop.height, 324);
    });

    test('handles 180° rotation like no-rotation', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: const Offset(0.1, 0.3),
        maxCrop: const Offset(0.5, 0.9),
        videoSize: const Size(1920, 1080),
        metadataRotation: 180,
        isAndroidOverride: true,
      );

      expect(crop.x, 192);
      expect(crop.y, 324);
      expect(crop.width, 768);
      expect(crop.height, 648);
    });

    test('handles full frame crop (0,0 → 1,1)', () {
      final crop = VideoCropUtil.calculateFileSpaceCropFromData(
        minCrop: Offset.zero,
        maxCrop: const Offset(1, 1),
        videoSize: const Size(1920, 1080),
        metadataRotation: 0,
        isAndroidOverride: true,
      );

      expect(crop.x, 0);
      expect(crop.y, 0);
      expect(crop.width, 1920);
      expect(crop.height, 1080);
    });

    test('round-trip area preserved across rotations', () {
      final random = Random(42);
      const videoSize = Size(1920, 1080);
      const rotations = [0, 90, 180, 270];

      for (final rotation in rotations) {
        for (var i = 0; i < 30; i++) {
          final widthNorm = 0.05 + random.nextDouble() * 0.4;
          final heightNorm = 0.05 + random.nextDouble() * 0.4;
          final minX = random.nextDouble() * (1 - widthNorm);
          final minY = random.nextDouble() * (1 - heightNorm);

          final minCrop = Offset(minX, minY);
          final maxCrop = Offset(minX + widthNorm, minY + heightNorm);

          final displayRect =
              VideoCropUtil.calculateDisplaySpaceCropRectFromData(
            minCrop: minCrop,
            maxCrop: maxCrop,
            videoSize: videoSize,
            metadataRotation: rotation,
            isAndroidOverride: true,
          );

          final fileCrop = VideoCropUtil.calculateFileSpaceCropFromData(
            minCrop: minCrop,
            maxCrop: maxCrop,
            videoSize: videoSize,
            metadataRotation: rotation,
            isAndroidOverride: true,
          );

          final expectedArea =
              widthNorm * heightNorm * videoSize.width * videoSize.height;
          final displayArea = displayRect.width * displayRect.height;
          final fileArea = fileCrop.width * fileCrop.height.toDouble();

          expect(displayArea, closeTo(expectedArea, 1));
          final relativeError = (fileArea - expectedArea).abs() / expectedArea;
          expect(relativeError, lessThan(0.02),
              reason: 'rotation=$rotation min=$minCrop max=$maxCrop');
        }
      }
    });

    group('parameterized rotations', () {
      const rotations = [0, 90, 180, 270];
      for (final rotation in rotations) {
        test('handles $rotation° rotation (Android override)', () {
          final crop = VideoCropUtil.calculateFileSpaceCropFromData(
            minCrop: const Offset(0.2, 0.1),
            maxCrop: const Offset(0.8, 0.6),
            videoSize: const Size(1920, 1080),
            metadataRotation: rotation,
            isAndroidOverride: true,
          );

          expect(crop.width > 0, isTrue);
          expect(crop.height > 0, isTrue);
        });
      }
    });
  });
}
