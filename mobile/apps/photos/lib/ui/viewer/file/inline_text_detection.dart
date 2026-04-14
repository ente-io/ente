import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:mobile_ocr/mobile_ocr.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/reset_zoom_of_photo_view_event.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/states/detail_page_state.dart";
import "package:photos/utils/file_util.dart";

/// Inline text detection widget that mimics Apple's Live Text behavior:
///
/// 1. Quick `hasText()` check runs silently when the image loads.
/// 2. If text is found and the user stays on the image for 1 second, full
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
  static const int _maxCacheSize = 200;
  static const Duration _autoActivateDelay = Duration(seconds: 1);
  static const double _globalGestureSlop = 18.0;
  static final Map<String, _HasTextResult> _hasTextCache = {};
  static final ValueNotifier<bool> _defaultZoomNotifier = ValueNotifier(false);
  final Logger _logger = Logger("InlineTextDetection");
  final MobileOcr _mobileOcr = MobileOcr();
  final TextDetectorController _detectorController = TextDetectorController();

  bool _isEligible = false;
  String? _localFilePath;
  int _requestId = 0;
  bool _overlayActive = false;
  Offset? _pendingLongPressPosition;
  Timer? _autoActivateTimer;
  bool _zoomGestureSettled = false;
  Timer? _zoomSettleTimer;
  ZoomTransform? _lastSeenTransform;
  int _activePointers = 0;
  bool _isPinching = false;
  bool _isCurrentlyZoomed = false;
  int _globalActivePointers = 0;
  int? _trackedGlobalPointer;
  Offset? _trackedGlobalPointerDownPosition;
  bool _trackedGlobalPointerMoved = false;
  bool _trackedGlobalLongPressTriggered = false;
  Timer? _globalLongPressTimer;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
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
    _autoActivateTimer?.cancel();
    _zoomSettleTimer?.cancel();
    _globalLongPressTimer?.cancel();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _detectorController.dispose();
    super.dispose();
  }

  void _resetState() {
    _autoActivateTimer?.cancel();
    _cancelTrackedGlobalPointer();
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

  static void _cacheResult(String key, _HasTextResult result) {
    if (_hasTextCache.length >= _maxCacheSize) {
      _hasTextCache.remove(_hasTextCache.keys.first);
    }
    _hasTextCache[key] = result;
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
      if (cached.hasText) _scheduleAutoActivate(requestId);
      return;
    }

    // Resolve local file
    try {
      final File? localFile = await getFile(widget.file);
      if (!mounted || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        _cacheResult(cacheKey, const _HasTextResult(hasText: false));
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
      _cacheResult(cacheKey, result);

      setState(() {
        _localFilePath = result.localPath;
      });

      if (hasText) _scheduleAutoActivate(requestId);
    } catch (error, stackTrace) {
      _logger.severe("Text detection pre-check failed", error, stackTrace);
      if (!mounted || requestId != _requestId) return;
      _cacheResult(cacheKey, const _HasTextResult(hasText: false));
    }
  }

  void _activateOverlay() {
    _autoActivateTimer?.cancel();
    if (_overlayActive) return;
    setState(() {
      _overlayActive = true;
    });
  }

  void _scheduleAutoActivate(int requestId) {
    _autoActivateTimer?.cancel();
    _autoActivateTimer = Timer(_autoActivateDelay, () {
      if (!mounted || requestId != _requestId) return;
      if (_localFilePath == null || _overlayActive) return;
      _activateOverlay();
    });
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (_overlayActive) return; // Already active, let overlay handle it
    _autoActivateTimer?.cancel();
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

  bool get _canTrackTapToClearSelection =>
      _overlayActive && _detectorController.hasActiveSelection;

  bool get _canTrackZoomedPanFirstLongPress =>
      _overlayActive &&
      _isCurrentlyZoomed &&
      _zoomGestureSettled &&
      !_isPinching;

  bool _isPrimaryGlobalPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      return event.buttons == kPrimaryMouseButton;
    }
    return true;
  }

  void _cancelTrackedGlobalPointer() {
    _globalLongPressTimer?.cancel();
    _globalLongPressTimer = null;
    _trackedGlobalPointer = null;
    _trackedGlobalPointerDownPosition = null;
    _trackedGlobalPointerMoved = false;
    _trackedGlobalLongPressTriggered = false;
  }

  void _handleGlobalPointerDown(PointerDownEvent event) {
    _globalActivePointers++;
    if (!_isPrimaryGlobalPointer(event)) {
      return;
    }
    if (_globalActivePointers != 1) {
      _cancelTrackedGlobalPointer();
      return;
    }

    final bool tapCanClearSelection = _canTrackTapToClearSelection;
    final bool pointOnInteractiveUi =
        _detectorController.isPointOnInteractiveSelectionUi(event.position);
    final bool longPressCanSelect = _canTrackZoomedPanFirstLongPress &&
        !pointOnInteractiveUi &&
        _detectorController.isPointOnSelectableText(event.position);

    if (!tapCanClearSelection && !longPressCanSelect) {
      return;
    }

    if (pointOnInteractiveUi) {
      _cancelTrackedGlobalPointer();
      return;
    }

    _trackedGlobalPointer = event.pointer;
    _trackedGlobalPointerDownPosition = event.position;
    _trackedGlobalPointerMoved = false;
    _trackedGlobalLongPressTriggered = false;

    if (longPressCanSelect) {
      final Offset position = event.position;
      final int pointer = event.pointer;
      _globalLongPressTimer = Timer(kLongPressTimeout, () {
        if (!mounted ||
            _trackedGlobalPointer != pointer ||
            _trackedGlobalPointerMoved ||
            _globalActivePointers != 1 ||
            !_canTrackZoomedPanFirstLongPress) {
          return;
        }
        _trackedGlobalLongPressTriggered =
            _detectorController.selectTextAtPosition(position);
      });
    }
  }

  void _handleGlobalPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackedGlobalPointer) {
      return;
    }
    final Offset? initialPosition = _trackedGlobalPointerDownPosition;
    if (initialPosition == null) {
      return;
    }
    if ((event.position - initialPosition).distance > _globalGestureSlop) {
      _trackedGlobalPointerMoved = true;
      _globalLongPressTimer?.cancel();
      _globalLongPressTimer = null;
    }
  }

  void _handleGlobalPointerEnd(PointerEvent event) {
    if (event.pointer == _trackedGlobalPointer) {
      final bool shouldClearSelection = !_trackedGlobalLongPressTriggered &&
          !_trackedGlobalPointerMoved &&
          _canTrackTapToClearSelection &&
          !_detectorController.isPointOnInteractiveSelectionUi(event.position);
      if (shouldClearSelection) {
        _detectorController.clearSelection();
      }
      _cancelTrackedGlobalPointer();
    }
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _handleGlobalPointerDown(event);
      return;
    }

    if (event is PointerMoveEvent) {
      _handleGlobalPointerMove(event);
      return;
    }

    if (event is PointerUpEvent) {
      _globalActivePointers =
          _globalActivePointers > 0 ? _globalActivePointers - 1 : 0;
      _handleGlobalPointerEnd(event);
      return;
    }

    if (event is PointerCancelEvent) {
      _globalActivePointers =
          _globalActivePointers > 0 ? _globalActivePointers - 1 : 0;
      _handleGlobalPointerEnd(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || widget.file is TrashFile || widget.isGuestView) {
      return const SizedBox.shrink();
    }

    final isZoomedNotifier =
        InheritedDetailPageState.maybeOf(context)?.isZoomedNotifier;

    // During the wait period (hasText passed but 1s timer hasn't fired),
    // show a transparent gesture layer to capture long press.
    // Only show when we know text exists to avoid blocking motion photo gestures.
    if (_localFilePath == null) {
      return const SizedBox.shrink();
    }
    if (!_overlayActive) {
      return Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: _handleLongPress,
          child: const SizedBox.expand(),
        ),
      );
    }

    final detailState = InheritedDetailPageState.maybeOf(context);
    final zoomTransformNotifier = detailState?.zoomTransformNotifier;

    return ValueListenableBuilder<bool>(
      valueListenable: isZoomedNotifier ?? _defaultZoomNotifier,
      builder: (context, isZoomed, _) {
        _isCurrentlyZoomed = isZoomed;
        if (!isZoomed) {
          _zoomGestureSettled = false;
          _zoomSettleTimer?.cancel();
          _lastSeenTransform = null;
        }
        return ValueListenableBuilder<ZoomTransform>(
          valueListenable:
              zoomTransformNotifier ?? ValueNotifier(ZoomTransform.identity),
          builder: (context, transform, _) {
            // Only reset the debounce when the transform has genuinely changed.
            // Guarding on value change prevents the setState rebuild from the
            // timer itself from re-entering this block and restarting the timer,
            // which would create an infinite loop where _zoomGestureSettled
            // can never stay true.
            if (isZoomed && transform != _lastSeenTransform) {
              _lastSeenTransform = transform;
              _zoomGestureSettled = false;
              _zoomSettleTimer?.cancel();
              _zoomSettleTimer = Timer(const Duration(milliseconds: 200), () {
                if (mounted) {
                  setState(() {
                    _zoomGestureSettled = true;
                  });
                }
              });
            }

            Widget overlay = _buildInlineOverlay(
              context,
              isZoomed: isZoomed,
              uiScale: transform.scale,
              uiOffset: transform.offset,
            );

            // Always apply the Transform, even when not zoomed.
            // When not zoomed, transform == ZoomTransform.identity (scale=1,
            // offset=zero), so this is a no-op visually. Applying it
            // unconditionally means teardrops and text boundaries immediately
            // track zoom from the very first stream event, with no flash at
            // the unscaled position that occurs when the Transform was only
            // added after isZoomedNotifier fired.
            overlay = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(transform.offset.dx, transform.offset.dy)
                ..scale(transform.scale),
              child: overlay,
            );

            // Ignore pointer events when:
            // - Actively pinching (2+ fingers down) — let PhotoView handle zoom
            // - Zoomed but gesture not yet settled — transform is still changing
            final shouldIgnore =
                _isPinching || (isZoomed && !_zoomGestureSettled);

            return Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  _activePointers++;
                  if (_activePointers >= 2 && !_isPinching) {
                    setState(() {
                      _isPinching = true;
                      _zoomGestureSettled = false;
                    });
                  }
                },
                onPointerUp: (_) {
                  if (_activePointers > 0) _activePointers--;
                  if (_activePointers < 2 && _isPinching) {
                    setState(() => _isPinching = false);
                  }
                },
                onPointerCancel: (_) {
                  if (_activePointers > 0) _activePointers--;
                  if (_activePointers < 2 && _isPinching) {
                    setState(() => _isPinching = false);
                  }
                },
                child: IgnorePointer(
                  ignoring: shouldIgnore,
                  child: overlay,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInlineOverlay(
    BuildContext context, {
    required bool isZoomed,
    double uiScale = 1.0,
    Offset uiOffset = Offset.zero,
  }) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _detectorController,
      builder: (context, child) {
        final bool isProcessing =
            _detectorController.userAttemptedInteraction &&
                _detectorController.isProcessing &&
                !_detectorController.hasSelectableText;
        return IgnorePointer(
          ignoring: isProcessing,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child!,
              if (isProcessing)
                IgnorePointer(
                  child: Center(
                    child: widget.file.hasDimensions
                        ? AspectRatio(
                            aspectRatio: widget.file.width / widget.file.height,
                            child: const _WhiteDotWaveOverlay(),
                          )
                        : const _WhiteDotWaveOverlay(),
                  ),
                ),
            ],
          ),
        );
      },
      child: TextDetectorWidget(
        key: ValueKey("ocr_$_localFilePath"),
        imagePath: _localFilePath!,
        autoDetect: true,
        backgroundColor: Colors.transparent,
        showUnselectedBoundaries: false,
        overlayOnly: true,
        showProcessingOverlay: false,
        showScanAnimation: false,
        showEditorHint: false,
        initialInteractionPosition: _pendingLongPressPosition,
        controller: _detectorController,
        isImageZoomed: isZoomed,
        onDoubleTapWhenZoomed: isZoomed
            ? () {
                Bus.instance.fire(
                  ResetZoomOfPhotoView(
                    uploadedFileID: widget.file.uploadedFileID,
                    localID: widget.file.localID,
                  ),
                );
              }
            : null,
        uiScale: uiScale,
        uiOffset: uiOffset,
        zoomedInteractionPolicy: ZoomedInteractionPolicy.panFirst,
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
}

class _HasTextResult {
  final bool hasText;
  final String? localPath;

  const _HasTextResult({required this.hasText, this.localPath});
}

/// White dot grid that pulses in a radial wave from center outward.
class _WhiteDotWaveOverlay extends StatefulWidget {
  const _WhiteDotWaveOverlay();

  @override
  State<_WhiteDotWaveOverlay> createState() => _WhiteDotWaveOverlayState();
}

class _WhiteDotWaveOverlayState extends State<_WhiteDotWaveOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
        return CustomPaint(
          painter: _WhiteDotWavePainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WhiteDotWavePainter extends CustomPainter {
  static const double _spacing = 16.0;
  static const double _maxDelay = 0.85;

  final double progress;

  _WhiteDotWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double maxDist = Offset(cx, cy).distance;

    final int cols = (size.width / _spacing).floor();
    final int rows = (size.height / _spacing).floor();
    final double offsetX = (size.width - (cols - 1) * _spacing) / 2;
    final double offsetY = (size.height - (rows - 1) * _spacing) / 2;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = offsetX + c * _spacing;
        final double y = offsetY + r * _spacing;

        final double dist = (Offset(x, y) - Offset(cx, cy)).distance;
        final double delay = (dist / maxDist) * _maxDelay;

        double phase = (progress - delay) % 1.0;
        if (phase < 0) phase += 1.0;

        // Ping-pong with ease-in-out in each half
        double t;
        if (phase < 0.5) {
          t = _easeInOut(phase * 2);
        } else {
          t = _easeInOut((1.0 - phase) * 2);
        }

        if (t < 0.01) continue;

        final double radius = 3.0 * t;
        final double opacity = 0.5 * t;

        final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  static double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(_WhiteDotWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
