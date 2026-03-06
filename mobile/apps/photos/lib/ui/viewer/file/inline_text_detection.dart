import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:mobile_ocr/mobile_ocr.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/utils/file_util.dart";

/// Inline text detection widget that mimics Apple's Live Text behavior:
///
/// 1. When the user stays on an eligible image, full OCR detection runs
///    automatically after the local file is resolved.
/// 2. Detected text boundaries appear as an overlay on top of the image.
/// 3. Long press on detected text lets users select and copy text.
/// 4. A close button dismisses the overlay; swiping to another image resets.
class InlineTextDetection extends StatefulWidget {
  final EnteFile file;
  final ValueListenable<bool> enableFullScreenNotifier;
  final bool isGuestView;

  const InlineTextDetection({
    required this.file,
    required this.enableFullScreenNotifier,
    required this.isGuestView,
    super.key,
  });

  @override
  State<InlineTextDetection> createState() => _InlineTextDetectionState();
}

class _InlineTextDetectionState extends State<InlineTextDetection> {
  final TextDetectorController _detectorController = TextDetectorController();

  bool _isEligible = false;
  String? _localFilePath;
  int _requestId = 0;
  bool _overlayActive = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _resolveFile();
  }

  @override
  void didUpdateWidget(covariant InlineTextDetection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didFileChange(oldWidget.file, widget.file)) {
      _resetState();
      _resolveFile();
    }
  }

  @override
  void dispose() {
    _detectorController.dispose();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _localFilePath = null;
      _overlayActive = false;
      _dismissed = false;
    });
  }

  bool _didFileChange(EnteFile oldFile, EnteFile newFile) {
    if (oldFile.generatedID != newFile.generatedID) return true;
    if (oldFile.uploadedFileID != newFile.uploadedFileID) return true;
    if (oldFile.localID != newFile.localID) return true;
    return false;
  }

  bool _isFileEligible(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  Future<void> _resolveFile() async {
    final bool isEligible = _isFileEligible(widget.file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      setState(() {
        _isEligible = false;
        _localFilePath = null;
      });
      return;
    }

    setState(() {
      _isEligible = true;
      _localFilePath = null;
    });

    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        setState(() {
          _localFilePath = null;
        });
        return;
      }

      setState(() {
        _localFilePath = localFile.path;
        _overlayActive = true;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _localFilePath = null;
      });
    }
  }

  void _dismissOverlay() {
    HapticFeedback.selectionClick();
    setState(() {
      _overlayActive = false;
      _dismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || widget.file is TrashFile) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        if (isFullScreen || widget.isGuestView || _dismissed) {
          return const SizedBox.shrink();
        }

        if (_overlayActive && _localFilePath != null) {
          return Stack(
            children: [
              _buildInlineOverlay(context),
              _buildCloseButton(context),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInlineOverlay(BuildContext context) {
    final l10n = context.l10n;
    return Positioned.fill(
      child: TextDetectorWidget(
        key: ValueKey("ocr_$_localFilePath"),
        imagePath: _localFilePath!,
        autoDetect: true,
        backgroundColor: Colors.transparent,
        showUnselectedBoundaries: true,
        overlayOnly: true,
        controller: _detectorController,
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
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 8,
      child: GestureDetector(
        onTap: _dismissOverlay,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
