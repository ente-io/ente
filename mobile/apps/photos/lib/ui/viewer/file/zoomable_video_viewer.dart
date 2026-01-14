import "package:flutter/widgets.dart";

/// Threshold for considering the view as "zoomed in".
/// Using 1.01 instead of 1.0 to account for floating-point precision.
const double kZoomThreshold = 1.01;

/// A widget that wraps [InteractiveViewer] with multi-touch detection.
///
/// This widget solves a gesture arena race condition: when pinch-to-zoom
/// is attempted on a video inside a PageView, the PageView's drag gesture
/// recognizer can claim single-finger touches before InteractiveViewer's
/// scale gesture recognizer detects the second finger.
///
/// By using a low-level [Listener], we detect multi-touch at the pointer
/// level (before gesture arena processing) and immediately disable the
/// parent PageView's scrolling.
class ZoomableVideoViewer extends StatefulWidget {
  final TransformationController transformationController;
  final Function(bool)? shouldDisableScroll;
  final Widget child;

  const ZoomableVideoViewer({
    super.key,
    required this.transformationController,
    this.shouldDisableScroll,
    required this.child,
  });

  @override
  State<ZoomableVideoViewer> createState() => _ZoomableVideoViewerState();
}

class _ZoomableVideoViewerState extends State<ZoomableVideoViewer> {
  int _activePointers = 0;

  void _onPointerDown(PointerDownEvent _) {
    _activePointers++;
    if (_activePointers >= 2) {
      widget.shouldDisableScroll?.call(true);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    _activePointers = (_activePointers - 1).clamp(0, 99);
    _maybeReenableScroll();
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _activePointers = (_activePointers - 1).clamp(0, 99);
    _maybeReenableScroll();
  }

  void _maybeReenableScroll() {
    if (_activePointers < 2) {
      final scale = widget.transformationController.value.getMaxScaleOnAxis();
      if (scale <= kZoomThreshold) {
        widget.shouldDisableScroll?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: InteractiveViewer(
        transformationController: widget.transformationController,
        maxScale: 10.0,
        minScale: 1.0,
        child: widget.child,
      ),
    );
  }
}
