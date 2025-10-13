import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mobile_ocr/mobile_ocr.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/ui/common/loading_widget.dart';

class TextDetectionPage extends StatefulWidget {
  final String imagePath;

  const TextDetectionPage({required this.imagePath, super.key});

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
          children: [
            TextDetectorWidget(
              imagePath: widget.imagePath,
              autoDetect: true,
              backgroundColor: Colors.black,
              showUnselectedBoundaries: true,
              strings: TextDetectorStrings(
                processingOverlayMessage: l10n.ocrProcessingOverlayMessage,
                loadingIndicatorLabel: l10n.ocrLoadingIndicatorLabel,
                selectionHint: l10n.ocrSelectionHint,
                noTextDetected: l10n.ocrNoTextDetected,
                retryButtonLabel: l10n.ocrRetryButtonLabel,
                modelsNetworkRequiredError: l10n.ocrModelsNetworkRequiredError,
                modelsPrepareFailed: l10n.ocrModelsPrepareFailed,
                imageNotFoundError: l10n.ocrImageNotFoundError,
                imageDecodeFailedError: l10n.ocrImageDecodeFailedError,
                genericDetectError: l10n.ocrGenericDetectError,
              ),
              loadingWidget: const Center(
                child: EnteLoadingWidget(color: Colors.white, size: 24),
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
