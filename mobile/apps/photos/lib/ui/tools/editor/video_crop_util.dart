import 'dart:io';
import 'dart:ui';
import 'package:video_editor/video_editor.dart';

/// Crop calculation result
class CropCalculation {
  final int x;
  final int y;
  final int width;
  final int height;

  CropCalculation({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Create Rect from crop calculation
  Rect toRect() => Rect.fromLTWH(
    x.toDouble(),
    y.toDouble(),
    width.toDouble(),
    height.toDouble(),
  );

  /// FFmpeg crop filter string: crop=w:h:x:y
  String toFFmpegFilter() => 'crop=$width:$height:$x:$y';
}

/// Calculate crop dimensions for rotated Android videos
class VideoCropUtil {
  static int _normalizedQuarterTurns(int rotationDegrees) {
    final normalized = ((rotationDegrees % 360) + 360) % 360;
    return normalized ~/ 90;
  }

  static double _clampNormalized(double value) {
    return value.clamp(0.0, 1.0) as double;
  }

  static int _clampInt(int value, int min, int max) {
    return value.clamp(min, max) as int;
  }

  /// Calculate the crop rectangle in display-space pixels.
  ///
  /// - On Android with 90°/270° metadata rotation, display dimensions are swapped
  ///   (W_display = H_file, H_display = W_file). We return a Rect in this
  ///   display-space so the native plugins can transform to file-space.
  /// - On other platforms / rotations, display == oriented video size.
  static Rect calculateDisplaySpaceCropRect({
    required VideoEditorController controller,
    required int metadataRotation,
  }) {
    final size = controller.video.value.size;
    final turns = _normalizedQuarterTurns(metadataRotation);
    final swap = Platform.isAndroid && turns % 2 == 1;

    double minX = _clampNormalized(controller.minCrop.dx);
    double maxX = _clampNormalized(controller.maxCrop.dx);
    double minY = _clampNormalized(controller.minCrop.dy);
    double maxY = _clampNormalized(controller.maxCrop.dy);

    if (minX > maxX) {
      final temp = minX;
      minX = maxX;
      maxX = temp;
    }
    if (minY > maxY) {
      final temp = minY;
      minY = maxY;
      maxY = temp;
    }

    final displayWidth = swap ? size.height : size.width;
    final displayHeight = swap ? size.width : size.height;

    final widthNormalized = maxX - minX;
    final heightNormalized = maxY - minY;

    if (widthNormalized <= 0 || heightNormalized <= 0) {
      throw ArgumentError('Invalid crop selection: zero or negative span');
    }

    final x = minX * displayWidth;
    final y = minY * displayHeight;
    final w = widthNormalized * displayWidth;
    final h = heightNormalized * displayHeight;

    if (w <= 0 || h <= 0) {
      throw ArgumentError('Invalid crop rectangle after scaling');
    }

    return Rect.fromLTWH(x, y, w, h);
  }

  /// Calculate crop for Android videos with 90°/270° metadata rotation
  ///
  /// For Android videos with metadata rotation, the video file dimensions don't match
  /// the display dimensions (e.g., file is 1920x1080 but displays as 1080x1920).
  /// This method calculates the correct crop in file space.
  static CropCalculation calculateCropForRotation({
    required VideoEditorController controller,
    required int metadataRotation,
  }) {
    final videoSize = controller.video.value.size;
    final metadataQuarterTurns = _normalizedQuarterTurns(metadataRotation);
    final displayCrop = calculateDisplaySpaceCropRect(
      controller: controller,
      metadataRotation: metadataRotation,
    );

    // For 90°/270° rotations on Android, we need special handling
    if (Platform.isAndroid && metadataQuarterTurns % 2 == 1) {
      final normalizedRotation = ((metadataRotation % 360) + 360) % 360;

      final xD = displayCrop.left;
      final yD = displayCrop.top;
      final wD = displayCrop.width;
      final hD = displayCrop.height;

      final int xF, yF, wF, hF;
      if (normalizedRotation == 90) {
        xF = (videoSize.width - (yD + hD)).round().clamp(
          0,
          videoSize.width.toInt(),
        );
        yF = xD.round().clamp(0, videoSize.height.toInt());
        wF = hD.round().clamp(0, (videoSize.width - xF).toInt());
        hF = wD.round().clamp(0, (videoSize.height - yF).toInt());
      } else {
        xF = yD.round().clamp(0, videoSize.width.toInt());
        yF = (videoSize.height - (xD + wD)).round().clamp(
          0,
          videoSize.height.toInt(),
        );
        wF = hD.round().clamp(0, (videoSize.width - xF).toInt());
        hF = wD.round().clamp(0, (videoSize.height - yF).toInt());
      }

      if (wF <= 0 || hF <= 0) {
        throw ArgumentError('Invalid crop dimensions after transform');
      }

      return CropCalculation(x: xF, y: yF, width: wF, height: hF);
    } else {
      // No rotation or iOS - use display coordinates directly (display == file)
      final minX = _clampInt(
        displayCrop.left.floor(),
        0,
        videoSize.width.toInt(),
      );
      final minY = _clampInt(
        displayCrop.top.floor(),
        0,
        videoSize.height.toInt(),
      );
      final maxX = _clampInt(
        displayCrop.right.ceil(),
        0,
        videoSize.width.toInt(),
      );
      final maxY = _clampInt(
        displayCrop.bottom.ceil(),
        0,
        videoSize.height.toInt(),
      );

      final w = maxX - minX;
      final h = maxY - minY;

      if (w <= 0 || h <= 0) {
        throw ArgumentError('Invalid crop dimensions after normalization');
      }

      return CropCalculation(x: minX, y: minY, width: w, height: h);
    }
  }
}
