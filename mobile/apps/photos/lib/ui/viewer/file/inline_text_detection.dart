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
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/file_util.dart";

/// Inline text detection widget that mimics Apple's Live Text behavior:
///
/// 1. Quick `hasText()` check runs immediately when the image loads.
/// 2. If text is found and the user stays on the image for [dwellDuration],
///    full OCR runs automatically and an inline overlay appears.
/// 3. The user can select and copy text directly on the image.
/// 4. A small Live-Text-style indicator in the corner lets the user
///    toggle the overlay on/off.
class InlineTextDetection extends StatefulWidget {
  final EnteFile file;
  final ValueListenable<bool> enableFullScreenNotifier;
  final bool isGuestView;

  /// How long the user must stay on the image before auto-detecting.
  final Duration dwellDuration;

  const InlineTextDetection({
    required this.file,
    required this.enableFullScreenNotifier,
    required this.isGuestView,
    this.dwellDuration = const Duration(seconds: 2),
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

  /// Lifecycle: idle → checking → dwellWaiting → detecting → overlay / noText
  bool _isEligible = false;
  bool _hasText = false;
  bool _isChecking = false;
  String? _localFilePath;
  int _requestId = 0;

  Timer? _dwellTimer;
  bool _overlayActive = false;
  bool _overlayDismissed = false;

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
    _dwellTimer?.cancel();
    _detectorController.dispose();
    super.dispose();
  }

  void _resetState() {
    _dwellTimer?.cancel();
    setState(() {
      _hasText = false;
      _localFilePath = null;
      _isChecking = false;
      _overlayActive = false;
      _overlayDismissed = false;
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

  // Phase 1: Quick hasText() check
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
      if (cached.hasText) {
        _startDwellTimer();
      }
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

      // Phase 2: Start dwell timer if text was found
      if (hasText) {
        _startDwellTimer();
      }
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

  // Phase 2: Dwell timer — auto-activate after user stays on image
  void _startDwellTimer() {
    _dwellTimer?.cancel();
    if (_overlayDismissed) return;
    _dwellTimer = Timer(widget.dwellDuration, () {
      if (!mounted || _overlayDismissed) return;
      _activateOverlay();
    });
  }

  // Phase 3: Show inline overlay
  void _activateOverlay() {
    setState(() {
      _overlayActive = true;
    });
  }

  void _toggleOverlay() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_overlayActive) {
        _overlayActive = false;
        _overlayDismissed = true;
        _dwellTimer?.cancel();
      } else {
        _overlayActive = true;
        _overlayDismissed = false;
      }
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

        return Stack(
          children: [
            // The inline text overlay (full-screen, on top of the image)
            if (_overlayActive && _localFilePath != null)
              _buildInlineOverlay(context),

            // The Live Text indicator icon
            if (_hasText && !_isChecking) _buildLiveTextIndicator(context),
          ],
        );
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

  Widget _buildLiveTextIndicator(BuildContext context) {
    double bottomOffset = MediaQuery.paddingOf(context).bottom + 72.0;

    final caption = widget.file.caption;
    if (caption != null && caption.trim().isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: caption.trim(),
          style: getEnteTextTheme(context).mini,
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 3,
      );
      final double maxWidth = MediaQuery.sizeOf(context).width - 16.0;
      textPainter.layout(maxWidth: maxWidth);
      bottomOffset += textPainter.height + 24.0;
    }

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _toggleOverlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _overlayActive
                  ? getEnteColorScheme(context)
                      .primary700
                      .withAlpha(200)
                  : Colors.black.withAlpha(160),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: _overlayActive
                    ? getEnteColorScheme(context)
                        .primary700
                        .withAlpha(120)
                    : Colors.white.withAlpha(60),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _overlayActive
                      ? Icons.text_fields
                      : Icons.text_fields_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _overlayActive ? "Hide text" : "Select text",
                  style: getEnteTextTheme(context).mini.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
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
