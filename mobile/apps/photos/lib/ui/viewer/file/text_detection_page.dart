import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mobile_ocr/mobile_ocr.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/ui/viewer/file/zoomable_image.dart';

class TextDetectionPage extends StatefulWidget {
  final EnteFile file;
  final String imagePath;

  const TextDetectionPage({
    required this.file,
    required this.imagePath,
    super.key,
  });

  @override
  State<TextDetectionPage> createState() => _TextDetectionPageState();
}

class _TextDetectionPageState extends State<TextDetectionPage> {
  @override
  Widget build(BuildContext context) {
    Logger("TextDetectorWidget").info("started");
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ZoomableImage(
                widget.file,
                tagPrefix: "text_detection_",
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),
            TextDetectorWidget(
              imagePath: widget.imagePath,
              autoDetect: true,
              backgroundColor: Colors.transparent,
              showUnselectedBoundaries: true,
              strings: TextDetectorStrings(
                processingOverlayMessage: l10n.ocrProcessingOverlayMessage,
                selectionHint: l10n.ocrSelectionHint,
                noTextDetected: l10n.ocrNoTextDetected,
                retryButtonLabel: l10n.ocrRetryButtonLabel,
                modelsNetworkRequiredError: l10n.ocrModelsNetworkRequiredError,
                modelsPrepareFailed: l10n.ocrModelsPrepareFailed,
                imageNotFoundError: l10n.ocrImageNotFoundError,
                imageDecodeFailedError: l10n.ocrImageDecodeFailedError,
                genericDetectError: l10n.ocrGenericDetectError,
              ),
              onTextCopied: (text) {
                HapticFeedback.lightImpact();
              },
            ),
            // Back button on top left
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
