import "dart:async";

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

class _QrTapRegion extends StatefulWidget {
  final QrDetection detection;
  final double offsetX;
  final double offsetY;
  final double displayWidth;
  final double displayHeight;

  const _QrTapRegion({
    required this.detection,
    required this.offsetX,
    required this.offsetY,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  State<_QrTapRegion> createState() => _QrTapRegionState();
}

class _QrTapRegionState extends State<_QrTapRegion> {
  static const _longPressDuration = Duration(milliseconds: 500);
  static const _moveThreshold = 20.0;
  Timer? _timer;
  Offset? _downPosition;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onLongPress() async {
    await HapticFeedback.lightImpact();
    final uri = Uri.tryParse(widget.detection.content);
    final isUpi = uri != null && uri.scheme == "upi";
    if (isUpi) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          await showQrCodeContentSheet(
            context,
            detections: [widget.detection],
          );
        }
      } catch (_) {
        if (mounted) {
          await showQrCodeContentSheet(
            context,
            detections: [widget.detection],
          );
        }
      }
    } else {
      await showQrCodeContentSheet(
        context,
        detections: [widget.detection],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawW = widget.detection.width * widget.displayWidth;
    final rawH = widget.detection.height * widget.displayHeight;
    const double minTapTarget = 48.0;
    final screenW = rawW < minTapTarget ? minTapTarget : rawW;
    final screenH = rawH < minTapTarget ? minTapTarget : rawH;
    final screenX = widget.offsetX +
        widget.detection.x * widget.displayWidth -
        (screenW - rawW) / 2;
    final screenY = widget.offsetY +
        widget.detection.y * widget.displayHeight -
        (screenH - rawH) / 2;

    return Positioned(
      left: screenX,
      top: screenY,
      width: screenW,
      height: screenH,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _downPosition = event.position;
          _timer?.cancel();
          _timer = Timer(_longPressDuration, _onLongPress);
        },
        onPointerMove: (event) {
          if (_downPosition != null &&
              (event.position - _downPosition!).distance > _moveThreshold) {
            _timer?.cancel();
          }
        },
        onPointerUp: (_) => _timer?.cancel(),
        onPointerCancel: (_) => _timer?.cancel(),
        child: const SizedBox.expand(),
      ),
    );
  }
}
