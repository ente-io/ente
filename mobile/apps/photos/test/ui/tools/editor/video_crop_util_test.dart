import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photos/ui/tools/editor/video_crop_util.dart';

void main() {
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
  });
}
