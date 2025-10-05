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
    final metadataQuarterTurns = (metadataRotation / 90).round();

    // For 90°/270° rotations on Android, we need special handling
    if (Platform.isAndroid && metadataQuarterTurns % 2 == 1) {
      // Get normalized crop coordinates in display space
      double minXNorm = controller.minCrop.dx;
      double minYNorm = controller.minCrop.dy;
      double maxXNorm = controller.maxCrop.dx;
      double maxYNorm = controller.maxCrop.dy;

      // Swap axes for 90°/270° rotation
      // Display X → File Y, Display Y → File X
      final tempMinX = minXNorm;
      final tempMaxX = maxXNorm;
      minXNorm = minYNorm;
      maxXNorm = maxYNorm;
      minYNorm = tempMinX;
      maxYNorm = tempMaxX;

      // Apply to original video dimensions (after swap)
      // Display width=1080, height=1920 → File width=1920, height=1080
      final minX = (minXNorm * videoSize.height).round();
      final maxX = (maxXNorm * videoSize.height).round();
      final minY = (minYNorm * videoSize.width).round();
      final maxY = (maxYNorm * videoSize.width).round();

      final w = maxX - minX;
      final h = maxY - minY;

      return CropCalculation(x: minX, y: minY, width: w, height: h);
    } else {
      // No rotation or iOS - use display coordinates directly
      final minX = (controller.minCrop.dx * videoSize.width).round();
      final maxX = (controller.maxCrop.dx * videoSize.width).round();
      final minY = (controller.minCrop.dy * videoSize.height).round();
      final maxY = (controller.maxCrop.dy * videoSize.height).round();

      final w = maxX - minX;
      final h = maxY - minY;

      return CropCalculation(x: minX, y: minY, width: w, height: h);
    }
  }
}
