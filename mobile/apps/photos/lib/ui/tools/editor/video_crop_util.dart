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

class VideoCropException implements Exception {
  VideoCropException(this.message);
  final String message;

  @override
  String toString() => 'VideoCropException: $message';
}

/// Helpers to derive display- and file-space crop rectangles for native export
class VideoCropUtil {
  static int _normalizedQuarterTurns(int rotationDegrees) {
    final normalized = ((rotationDegrees % 360) + 360) % 360;
    return normalized ~/ 90;
  }

  static double _clampNormalized(double value) {
    return value.clamp(0.0, 1.0);
  }

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
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
    bool? isAndroidOverride,
  }) {
    return calculateDisplaySpaceCropRectFromData(
      minCrop: controller.minCrop,
      maxCrop: controller.maxCrop,
      videoSize: controller.video.value.size,
      metadataRotation: metadataRotation,
      isAndroidOverride: isAndroidOverride,
    );
  }

  /// Testability helper: bypasses controller and platform checks by accepting
  /// raw crop data. Only used in unit tests.
  @visibleForTesting
  static Rect calculateDisplaySpaceCropRectFromData({
    required Offset minCrop,
    required Offset maxCrop,
    required Size videoSize,
    required int metadataRotation,
    bool? isAndroidOverride,
  }) {
    final turns = _normalizedQuarterTurns(metadataRotation);
    final isAndroid = isAndroidOverride ?? Platform.isAndroid;
    final swap = isAndroid && turns % 2 == 1;

    double minX = _clampNormalized(minCrop.dx);
    double maxX = _clampNormalized(maxCrop.dx);
    double minY = _clampNormalized(minCrop.dy);
    double maxY = _clampNormalized(maxCrop.dy);

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

    final displayWidth = swap ? videoSize.height : videoSize.width;
    final displayHeight = swap ? videoSize.width : videoSize.height;

    final widthNormalized = maxX - minX;
    final heightNormalized = maxY - minY;

    if (widthNormalized <= 0 || heightNormalized <= 0) {
      throw VideoCropException('Invalid crop selection: zero or negative span');
    }

    final x = minX * displayWidth;
    final y = minY * displayHeight;
    final w = widthNormalized * displayWidth;
    final h = heightNormalized * displayHeight;

    if (w <= 0 || h <= 0) {
      throw VideoCropException('Invalid crop rectangle after scaling');
    }

    return Rect.fromLTWH(x, y, w, h);
  }

  /// Convert the normalised crop selection into file-space coordinates
  /// (taking metadata rotation on Android into account).
  static CropCalculation calculateFileSpaceCrop({
    required VideoEditorController controller,
    required int metadataRotation,
    bool? isAndroidOverride,
  }) {
    final videoSize = controller.video.value.size;
    return calculateFileSpaceCropFromData(
      minCrop: controller.minCrop,
      maxCrop: controller.maxCrop,
      videoSize: videoSize,
      metadataRotation: metadataRotation,
      isAndroidOverride: isAndroidOverride,
    );
  }

  /// Testability helper: skips controller/platform usage to make unit tests
  /// deterministic. Not for production callers.
  @visibleForTesting
  static CropCalculation calculateFileSpaceCropFromData({
    required Offset minCrop,
    required Offset maxCrop,
    required Size videoSize,
    required int metadataRotation,
    bool? isAndroidOverride,
  }) {
    final metadataQuarterTurns = _normalizedQuarterTurns(metadataRotation);
    final isAndroid = isAndroidOverride ?? Platform.isAndroid;
    final displayCrop = calculateDisplaySpaceCropRectFromData(
      minCrop: minCrop,
      maxCrop: maxCrop,
      videoSize: videoSize,
      metadataRotation: metadataRotation,
      isAndroidOverride: isAndroidOverride,
    );

    // For 90°/270° rotations on Android, we need special handling
    if (isAndroid && metadataQuarterTurns % 2 == 1) {
      return _calculateRotatedFileSpaceCrop(
        videoSize,
        displayCrop,
        metadataRotation,
      );
    }

    return _calculateStandardFileSpaceCrop(videoSize, displayCrop);
  }

  static CropCalculation _calculateRotatedFileSpaceCrop(
    Size videoSize,
    Rect displayCrop,
    int metadataRotation,
  ) {
    const int rotation90 = 90;
    const int rotation270 = 270;
    final normalizedRotation = ((metadataRotation % 360) + 360) % 360;

    final xD = displayCrop.left;
    final yD = displayCrop.top;
    final wD = displayCrop.width;
    final hD = displayCrop.height;

    int xF;
    int yF;
    int wF;
    int hF;

    if (normalizedRotation == rotation90) {
      xF = (videoSize.width - (yD + hD)).round().clamp(
            0,
            videoSize.width.toInt(),
          );
      yF = xD.round().clamp(0, videoSize.height.toInt());
    } else if (normalizedRotation == rotation270) {
      xF = yD.round().clamp(0, videoSize.width.toInt());
      yF = (videoSize.height - (xD + wD)).round().clamp(
            0,
            videoSize.height.toInt(),
          );
    } else {
      throw VideoCropException(
        'Unsupported rotation $normalizedRotation for Android crop',
      );
    }

    wF = hD.round().clamp(0, (videoSize.width - xF).toInt());
    hF = wD.round().clamp(0, (videoSize.height - yF).toInt());

    if (wF <= 0 || hF <= 0) {
      throw VideoCropException(
        'Invalid crop dimensions after rotation transform',
      );
    }

    return CropCalculation(x: xF, y: yF, width: wF, height: hF);
  }

  static CropCalculation _calculateStandardFileSpaceCrop(
    Size videoSize,
    Rect displayCrop,
  ) {
    final minX = _clampInt(
      displayCrop.left.round(),
      0,
      videoSize.width.toInt(),
    );
    final minY = _clampInt(
      displayCrop.top.round(),
      0,
      videoSize.height.toInt(),
    );
    final maxX = _clampInt(
      displayCrop.right.round(),
      0,
      videoSize.width.toInt(),
    );
    final maxY = _clampInt(
      displayCrop.bottom.round(),
      0,
      videoSize.height.toInt(),
    );

    final w = maxX - minX;
    final h = maxY - minY;

    // Note: we round to the nearest pixel before clamping so that symmetric
    // crops retain parity after multiple transformations. This avoids repeated
    // floor/ceil adjustments that previously caused ±1px drift.
    if (w <= 0 || h <= 0) {
      throw VideoCropException('Invalid crop dimensions after normalization');
    }

    return CropCalculation(x: minX, y: minY, width: w, height: h);
  }
}
