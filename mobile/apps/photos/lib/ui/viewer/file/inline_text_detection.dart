import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:mobile_ocr/mobile_ocr.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/utils/file_util.dart";

/// Inline text detection widget that mimics Apple's Live Text behavior:
///
/// 1. Quick `hasText()` check runs silently when the image loads.
/// 2. If text is found, a transparent long-press detector covers the image.
/// 3. Long press triggers haptic feedback and shows the text overlay inline,
///    letting users select and copy text directly on the image.
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
  static final Map<String, _HasTextResult> _hasTextCache = {};
  final Logger _logger = Logger("InlineTextDetection");
  final MobileOcr _mobileOcr = MobileOcr();
  final TextDetectorController _detectorController = TextDetectorController();

  bool _isEligible = false;
  bool _hasText = false;
  bool _isChecking = false;
  String? _localFilePath;
  int _requestId = 0;

  bool _overlayActive = false;

  @override
  void initState() {
    super.initState();
    _evaluateFile();
  }

  @override
  void didUpdateWidget(covariant InlineTextDetection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didFileChange(oldWidget.file, widget.file)) {
      _resetState();
      _evaluateFile();
    }
  }

  @override
  void dispose() {
    _detectorController.dispose();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _hasText = false;
      _localFilePath = null;
      _isChecking = false;
      _overlayActive = false;
    });
  }

  bool _didFileChange(EnteFile oldFile, EnteFile newFile) {
    if (oldFile.generatedID != newFile.generatedID) return true;
    if (oldFile.uploadedFileID != newFile.uploadedFileID) return true;
    if (oldFile.localID != newFile.localID) return true;
    return false;
  }

  String _cacheKey(EnteFile file) {
    if (file.uploadedFileID != null) return "uploaded_${file.uploadedFileID}";
    if (file.localID != null) return "local_${file.localID}";
    return "generated_${file.generatedID}";
  }

  bool _isFileEligible(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  // Phase 1: Silent hasText() check
  Future<void> _evaluateFile() async {
    final bool isEligible = _isFileEligible(widget.file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      setState(() {
        _isEligible = false;
        _hasText = false;
        _localFilePath = null;
        _isChecking = false;
      });
      return;
    }

    final String cacheKey = _cacheKey(widget.file);
    final _HasTextResult? cached = _hasTextCache[cacheKey];
    if (cached != null) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isEligible = true;
        _hasText = cached.hasText;
        _localFilePath = cached.localPath;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isEligible = true;
      _hasText = false;
      _localFilePath = null;
      _isChecking = true;
    });

    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        _hasTextCache[cacheKey] = const _HasTextResult(hasText: false);
        setState(() {
          _hasText = false;
          _localFilePath = null;
          _isChecking = false;
        });
        return;
      }

      bool hasText = false;
      try {
        hasText = await _mobileOcr.hasText(imagePath: localFile.path);
      } catch (error, stackTrace) {
        _logger.severe("Failed to run hasText", error, stackTrace);
      }

      if (!mounted || requestId != _requestId) return;

      final result = _HasTextResult(
        hasText: hasText,
        localPath: hasText ? localFile.path : null,
      );
      _hasTextCache[cacheKey] = result;
      setState(() {
        _hasText = result.hasText;
        _localFilePath = result.localPath;
        _isChecking = false;
      });
    } catch (error, stackTrace) {
      _logger.severe("Text detection pre-check failed", error, stackTrace);
      if (!mounted || requestId != _requestId) return;
      _hasTextCache[cacheKey] = const _HasTextResult(hasText: false);
      setState(() {
        _hasText = false;
        _localFilePath = null;
        _isChecking = false;
      });
    }
  }

  void _onLongPress() {
    if (!_hasText || _localFilePath == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _overlayActive = true;
    });
  }

  void _dismissOverlay() {
    HapticFeedback.selectionClick();
    setState(() {
      _overlayActive = false;
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
        if (isFullScreen || widget.isGuestView) {
          return const SizedBox.shrink();
        }

        // Overlay active: show TextDetectorWidget + close button
        if (_overlayActive && _localFilePath != null) {
          return Stack(
            children: [
              _buildInlineOverlay(context),
              _buildCloseButton(context),
            ],
          );
        }

        // Overlay inactive but text detected: invisible long-press detector
        if (_hasText && !_isChecking && _localFilePath != null) {
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: _onLongPress,
              child: const SizedBox.expand(),
            ),
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

class _HasTextResult {
  final bool hasText;
  final String? localPath;

  const _HasTextResult({required this.hasText, this.localPath});
}
