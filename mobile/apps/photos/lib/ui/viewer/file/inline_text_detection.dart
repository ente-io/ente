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
import "package:photos/states/detail_page_state.dart";
import "package:photos/utils/file_util.dart";

/// Inline text detection widget that mimics Apple's Live Text behavior:
///
/// 1. Quick `hasText()` check runs silently when the image loads.
/// 2. If text is found and user stays on the image for 1 second, full
///    detection runs automatically and text boundaries appear as a
///    transparent overlay.
/// 3. Long press on detected text lets users select and copy.
/// 4. Taps and swipes pass through to the underlying image viewer.
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
  String? _localFilePath;
  int _requestId = 0;
  bool _overlayActive = false;
  Timer? _activationTimer;

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
    _activationTimer?.cancel();
    _detectorController.dispose();
    super.dispose();
  }

  void _resetState() {
    _activationTimer?.cancel();
    setState(() {
      _localFilePath = null;
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

  Future<void> _evaluateFile() async {
    final bool isEligible = _isFileEligible(widget.file);
    final int requestId = ++_requestId;
    _logger.info(
      "evaluateFile: eligible=$isEligible, type=${widget.file.fileType}",
    );

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

    // Check cache first
    final String cacheKey = _cacheKey(widget.file);
    final _HasTextResult? cached = _hasTextCache[cacheKey];
    if (cached != null) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _localFilePath = cached.localPath;
      });
      if (cached.hasText) _scheduleActivation(requestId);
      return;
    }

    // Resolve local file
    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        _hasTextCache[cacheKey] = const _HasTextResult(hasText: false);
        return;
      }

      // Run fast hasText() check
      _logger.info("running hasText check");
      bool hasText = false;
      try {
        hasText = await _mobileOcr.hasText(imagePath: localFile.path);
        _logger.info("hasText result: $hasText");
      } catch (error, stackTrace) {
        _logger.warning("hasText error: $error");
        _logger.severe("Failed to run hasText", error, stackTrace);
      }

      if (!mounted || requestId != _requestId) return;

      final result = _HasTextResult(
        hasText: hasText,
        localPath: hasText ? localFile.path : null,
      );
      _hasTextCache[cacheKey] = result;

      setState(() {
        _localFilePath = result.localPath;
      });

      // If text found, schedule activation after 1 second delay
      if (hasText) _scheduleActivation(requestId);
    } catch (error, stackTrace) {
      _logger.severe("Text detection pre-check failed", error, stackTrace);
      if (!mounted || requestId != _requestId) return;
      _hasTextCache[cacheKey] = const _HasTextResult(hasText: false);
    }
  }

  void _scheduleActivation(int requestId) {
    _activationTimer?.cancel();
    _activationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _overlayActive = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || widget.file is TrashFile) {
      return const SizedBox.shrink();
    }

    if (!_overlayActive || _localFilePath == null) {
      return const SizedBox.shrink();
    }

    final isZoomedNotifier = InheritedDetailPageState.maybeOf(context)
        ?.isZoomedNotifier;

    return ValueListenableBuilder<bool>(
      valueListenable: isZoomedNotifier ?? ValueNotifier(false),
      builder: (context, isZoomed, _) {
        final bool shouldHide = widget.isGuestView || isZoomed;

        return Positioned.fill(
          child: IgnorePointer(
            ignoring: shouldHide,
            child: AnimatedOpacity(
              opacity: shouldHide ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: _buildInlineOverlay(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineOverlay(BuildContext context) {
    final l10n = context.l10n;
    return TextDetectorWidget(
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
    );
  }
}

class _HasTextResult {
  final bool hasText;
  final String? localPath;

  const _HasTextResult({required this.hasText, this.localPath});
}
