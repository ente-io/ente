import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mobile_ocr/mobile_ocr.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/notification/toast.dart';

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
              loadingWidget: const Center(
                child: EnteLoadingWidget(color: Colors.white, size: 24),
              ),
              onTextCopied: (text) {
                HapticFeedback.lightImpact();
                showShortToast(context, "Text copied to clipboard");
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
