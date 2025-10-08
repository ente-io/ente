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
      // Get normalized crop coordinates in display space (dimensions swapped)
      final minXNorm = controller.minCrop.dx;
      final minYNorm = controller.minCrop.dy;
      final maxXNorm = controller.maxCrop.dx;
      final maxYNorm = controller.maxCrop.dy;

      // Convert to absolute display-space pixels
      final displayWidth = videoSize.height; // swapped
      final displayHeight = videoSize.width; // swapped

      final xD = (minXNorm * displayWidth);
      final yD = (minYNorm * displayHeight);
      final wD = ((maxXNorm - minXNorm) * displayWidth);
      final hD = ((maxYNorm - minYNorm) * displayHeight);

      // Map display-space → file-space based on metadata rotation
      final int xF, yF, wF, hF;
      if ((metadataRotation % 360 + 360) % 360 == 90) {
        // 90° CW
        xF = (videoSize.width - (yD + hD)).round().clamp(0, videoSize.width.toInt());
        yF = xD.round().clamp(0, videoSize.height.toInt());
        wF = hD.round().clamp(0, (videoSize.width - xF).toInt());
        hF = wD.round().clamp(0, (videoSize.height - yF).toInt());
      } else {
        // 270° (90° CCW)
        xF = yD.round().clamp(0, videoSize.width.toInt());
        yF = (videoSize.height - (xD + wD)).round().clamp(0, videoSize.height.toInt());
        wF = hD.round().clamp(0, (videoSize.width - xF).toInt());
        hF = wD.round().clamp(0, (videoSize.height - yF).toInt());
      }

      return CropCalculation(x: xF, y: yF, width: wF, height: hF);
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
