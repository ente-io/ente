import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/file/qr_code_content_sheet.dart";
import "package:url_launcher/url_launcher.dart";

class QrCodeHighlightOverlay extends StatelessWidget {
  final List<QrDetection> detections;
  final EnteFile file;
  final ValueListenable<bool> enableFullScreenNotifier;

  const QrCodeHighlightOverlay({
    required this.detections,
    required this.file,
    required this.enableFullScreenNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty || !file.hasDimensions) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: enableFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        if (isFullScreen) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final imageAspect = file.width / file.height;
            final screenAspect = screenWidth / screenHeight;

            double displayWidth;
            double displayHeight;
            if (imageAspect > screenAspect) {
              displayWidth = screenWidth;
              displayHeight = screenWidth / imageAspect;
            } else {
              displayHeight = screenHeight;
              displayWidth = screenHeight * imageAspect;
            }

            final offsetX = (screenWidth - displayWidth) / 2;
            final offsetY = (screenHeight - displayHeight) / 2;

            return Stack(
              children: [
                for (final detection in detections)
                  _QrTapRegion(
                    detection: detection,
                    allDetections: detections,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    displayWidth: displayWidth,
                    displayHeight: displayHeight,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _QrTapRegion extends StatelessWidget {
  final QrDetection detection;
  final List<QrDetection> allDetections;
  final double offsetX;
  final double offsetY;
  final double displayWidth;
  final double displayHeight;

  const _QrTapRegion({
    required this.detection,
    required this.allDetections,
    required this.offsetX,
    required this.offsetY,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenX = offsetX + detection.x * displayWidth;
    final screenY = offsetY + detection.y * displayHeight;
    final screenW = detection.width * displayWidth;
    final screenH = detection.height * displayHeight;

    return Positioned(
      left: screenX,
      top: screenY,
      width: screenW,
      height: screenH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.lightImpact();
          final uri = Uri.tryParse(detection.content);
          final isUrl =
              uri != null && (uri.scheme == "http" || uri.scheme == "https");
          if (isUrl) {
            launchUrl(uri);
          } else {
            showQrCodeContentSheet(
              context,
              detections: [detection],
            );
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}
