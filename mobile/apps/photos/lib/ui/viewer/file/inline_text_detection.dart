import "dart:async";
import "dart:io";
import "dart:math" as math;

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
  Offset? _pendingLongPressPosition;

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
      _localFilePath = null;
      _overlayActive = false;
      _pendingLongPressPosition = null;
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
      if (cached.hasText) _activateOverlay();
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
        hasText = await _mobileOcr
            .hasText(imagePath: localFile.path)
            .timeout(const Duration(seconds: 5));
        _logger.info("hasText result: $hasText");
      } catch (error, stackTrace) {
        // On error or timeout, optimistically assume text may be present
        // so the full detection pipeline can make the final determination.
        hasText = true;
        _logger.warning(
          "hasText failed, falling back to optimistic",
          error,
          stackTrace,
        );
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

      if (hasText) _activateOverlay();
    } catch (error, stackTrace) {
      _logger.severe("Text detection pre-check failed", error, stackTrace);
      if (!mounted || requestId != _requestId) return;
      _hasTextCache[cacheKey] = const _HasTextResult(hasText: false);
    }
  }

  void _activateOverlay() {
    setState(() {
      _overlayActive = true;
    });
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (_overlayActive) return; // Already active, let overlay handle it
    setState(() {
      _pendingLongPressPosition = details.globalPosition;
    });
    // If hasText already completed and file path is ready, activate now
    if (_localFilePath != null) {
      setState(() {
        _overlayActive = true;
      });
    }
    // Otherwise _evaluateFile will activate when hasText completes
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || widget.file is TrashFile) {
      return const SizedBox.shrink();
    }

    final isZoomedNotifier =
        InheritedDetailPageState.maybeOf(context)?.isZoomedNotifier;

    // During the wait period (hasText passed but 1s timer hasn't fired),
    // show a transparent gesture layer to capture long press.
    if (!_overlayActive || _localFilePath == null) {
      if (!_isEligible || widget.isGuestView) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: _handleLongPress,
          child: const SizedBox.expand(),
        ),
      );
    }

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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Block touches during processing so the package's internal
        // long-press handler cannot trigger its green scan animation.
        ListenableBuilder(
          listenable: _detectorController,
          builder: (context, child) {
            final bool isProcessing = _detectorController.isProcessing &&
                !_detectorController.hasSelectableText;
            return AbsorbPointer(
              absorbing: isProcessing,
              child: child,
            );
          },
          child: TextDetectorWidget(
            key: ValueKey("ocr_$_localFilePath"),
            imagePath: _localFilePath!,
            autoDetect: true,
            backgroundColor: Colors.transparent,
            showUnselectedBoundaries: true,
            overlayOnly: true,
            showProcessingOverlay: false,
            showEditorHint: false,
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
        ),
        ListenableBuilder(
          listenable: _detectorController,
          builder: (context, _) {
            if (_detectorController.isProcessing &&
                !_detectorController.hasSelectableText) {
              return IgnorePointer(
                child: _RippleDotAnimation(
                  origin: _pendingLongPressPosition,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _HasTextResult {
  final bool hasText;
  final String? localPath;

  const _HasTextResult({required this.hasText, this.localPath});
}

/// Ripple-dot animation that radiates outward from the touch point.
/// Dots pulse in a wave pattern, fading as the ripple expands.
class _RippleDotAnimation extends StatefulWidget {
  final Offset? origin;

  const _RippleDotAnimation({this.origin});

  @override
  State<_RippleDotAnimation> createState() => _RippleDotAnimationState();
}

class _RippleDotAnimationState extends State<_RippleDotAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        Offset? localOrigin;
        if (widget.origin != null) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            localOrigin = box.globalToLocal(widget.origin!);
          }
        }
        return CustomPaint(
          painter: _RippleDotPainter(
            progress: _controller.value,
            origin: localOrigin,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RippleDotPainter extends CustomPainter {
  static const int _cols = 24;
  static const int _rows = 16;

  /// Max stagger delay: 1.8s / 2.4s = 0.75
  static const double _maxDelayRatio = 0.75;

  final double progress;
  final Offset? origin;

  _RippleDotPainter({required this.progress, this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = origin?.dy ?? size.height / 2;
    final double maxDist =
        math.max(cy, size.height - cy).clamp(1.0, double.infinity);

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final double x = ((c + 0.5) / _cols) * size.width;
        final double y = ((r + 0.5) / _rows) * size.height;

        // Vertical distance from origin row — all dots in the same
        // row pulse together, creating a top-to-bottom wave.
        final double dist = (y - cy).abs();

        final double delay = (dist / maxDist) * _maxDelayRatio;

        double t = (progress - delay) % 1.0;
        if (t < 0) t += 1.0;

        // Cubic ease-in-out
        final double eased =
            t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

        // Ping-pong: full → 25% → full
        final double pingPong = eased < 0.5 ? eased * 2 : 2 - eased * 2;

        final double opacity = 1.0 - pingPong * 0.75;
        final double radius = 2.0 - pingPong * 1.0;

        final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
        canvas.drawCircle(Offset(x, y), radius, paint);

        // Subtle white glow
        if (opacity > 0.4) {
          final glowPaint = Paint()
            ..color = Color.fromRGBO(255, 255, 255, opacity * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(Offset(x, y), radius + 2, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RippleDotPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}
