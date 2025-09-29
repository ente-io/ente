import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart';
import 'package:photos/ui/viewer/gallery/state/gallery_swipe_helper.dart';
import 'package:photos/ui/viewer/gallery/swipe_to_select_helper.dart';

/// A wrapper widget that handles swipe-to-select gesture detection and state management
/// for the Gallery widget. This reduces the complexity in the main Gallery build method.
class SwipeSelectionWrapper extends StatefulWidget {
  final Widget child;
  final SwipeToSelectHelper? swipeHelper;
  final SelectedFiles? selectedFiles;
  final bool isEnabled;
  final ValueNotifier<bool> swipeActiveNotifier;
  final ScrollController scrollController;

  const SwipeSelectionWrapper({
    super.key,
    required this.child,
    required this.swipeHelper,
    required this.selectedFiles,
    required this.isEnabled,
    required this.swipeActiveNotifier,
    required this.scrollController,
  });

  @override
  State<SwipeSelectionWrapper> createState() => _SwipeSelectionWrapperState();
}

class _SwipeSelectionWrapperState extends State<SwipeSelectionWrapper> {
  bool? _initialMovementWasHorizontal;

  // Auto-scroll related fields
  Timer? _autoScrollTimer;
  double _currentPointerY = 0;
  double _currentPointerX = 0;
  int? _activePointer;
  double? _cachedScreenHeight;
  double _accumulatedScrollDelta = 0;

  // Auto-scroll constants
  static const double _maxScrollSpeed = 30.0; // Maximum speed cap
  static const double _scrollIntervalMs = 8.33; // ~120fps in milliseconds
  static const double _syntheticEventThreshold =
      10.0; // Pixels before generating event
  static const double _exponentialFactor =
      0.015; // Controls speed increase rate
  static const double _referenceMaxDistance = 200.0; // Distance for max speed
  static const double _edgeThreshold =
      20.0; // Distance from screen edge for boost
  static const double _edgeBoostMultiplier = 1.5; // Speed multiplier at edges
  static const double _minAvailableSpace =
      50.0; // Minimum space for normalization
  // Pre-calculated denominator for speed formula: e^(factor * maxDist) - 1
  static final double _speedDenominator =
      math.exp(_exponentialFactor * _referenceMaxDistance) - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update cached screen height when dependencies change (includes orientation changes)
    final newHeight = MediaQuery.of(context).size.height;
    if (_cachedScreenHeight != newHeight) {
      _cachedScreenHeight = newHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If swipe selection is not enabled, just return the child wrapped in GallerySwipeHelper
    if (!widget.isEnabled) {
      return GallerySwipeHelper(
        helper: null,
        swipeActiveNotifier: widget.swipeActiveNotifier,
        child: widget.child,
      );
    }

    // Wrap with GallerySwipeHelper and Listener for swipe detection
    return GallerySwipeHelper(
      helper: widget.swipeHelper,
      swipeActiveNotifier: widget.swipeActiveNotifier,
      child: Listener(
        onPointerDown: (event) {
          _currentPointerX = event.position.dx;
          _currentPointerY = event.position.dy;
          _activePointer = event.pointer;
          // Reset initial movement tracking for new gesture
          _initialMovementWasHorizontal = null;
        },
        onPointerMove: (event) {
          _currentPointerX = event.position.dx;
          _currentPointerY = event.position.dy;
          _activePointer = event.pointer;
          // Handle case where pointer is dragged after first selection in gallery
          if (widget.selectedFiles != null &&
              widget.selectedFiles!.files.length == 1 &&
              !widget.swipeActiveNotifier.value) {
            // Activate swipe mode for any significant movement when only one file is selected
            // This handles the case of long-press to select first file, then immediate swipe
            // including vertical movement without initial horizontal movement
            final dx = event.delta.dx.abs();
            final dy = event.delta.dy.abs();
            if (dx > 0.1 || dy > 0.1) {
              widget.swipeActiveNotifier.value = true;
            }
          }
          // Check for horizontal swipe if multiple files are selected and swipe is not already active
          else if (!widget.swipeActiveNotifier.value &&
              widget.selectedFiles != null &&
              widget.selectedFiles!.files.isNotEmpty) {
            // Check if movement is primarily horizontal and if delta x is significant
            final dx = event.delta.dx.abs();
            final dy = event.delta.dy.abs();

            // Track initial movement direction if not yet determined
            if (_initialMovementWasHorizontal == null &&
                (dx > 0.1 || dy > 0.1)) {
              _initialMovementWasHorizontal = dx > dy;
            }

            // Only activate swipe if initial movement was horizontal
            if (_initialMovementWasHorizontal == true && dx > dy && dx > 0.1) {
              // Horizontal swipe detected, activate swipe mode
              widget.swipeActiveNotifier.value = true;
            }
          }

          // Check for auto-scroll if swipe is active
          if (widget.swipeActiveNotifier.value) {
            _checkAndHandleAutoScroll();
          }
        },
        onPointerUp: (_) {
          _stopAutoScroll();
          // End swipe selection when pointer is released
          widget.swipeHelper?.endSelection();
          widget.swipeActiveNotifier.value = false;
          _initialMovementWasHorizontal = null;
          _activePointer = null;
        },
        onPointerCancel: (_) {
          _stopAutoScroll();
          // Also end selection on cancel
          widget.swipeHelper?.endSelection();
          widget.swipeActiveNotifier.value = false;
          _initialMovementWasHorizontal = null;
          _activePointer = null;
        },
        child: widget.child,
      ),
    );
  }

  /// Calculate exponential scroll speed with adaptive scaling based on available space
  double _calculateScrollSpeed(
    double distanceFromBoundary,
    double boundaryPosition,
    bool scrollingUp,
  ) {
    if (distanceFromBoundary <= 0) return 0;

    // Use cached screen height for better performance
    final screenHeight =
        _cachedScreenHeight ?? MediaQuery.of(context).size.height;

    // Calculate available space from boundary to screen edge
    final availableSpace = scrollingUp
        ? boundaryPosition // Space from top boundary to screen top
        : (screenHeight -
            boundaryPosition); // Space from bottom boundary to screen bottom

    // Normalize distance based on available space (adaptive scaling)
    // This ensures consistent speed progression regardless of boundary position
    final normalizedDistance = math.min(
      1.0,
      distanceFromBoundary / math.max(_minAvailableSpace, availableSpace),
    );

    // Map normalized distance (0-1) to effective distance for speed calculation
    final effectiveDistance = normalizedDistance * _referenceMaxDistance;

    // Calculate base speed using exponential formula with normalized distance
    final numerator = math.exp(_exponentialFactor * effectiveDistance) - 1;
    double speed = _maxScrollSpeed * (numerator / _speedDenominator);

    // Apply edge boost when pointer is very close to screen edges
    final pointerY = scrollingUp
        ? (boundaryPosition - distanceFromBoundary)
        : (boundaryPosition + distanceFromBoundary);

    if ((scrollingUp && pointerY < _edgeThreshold) ||
        (!scrollingUp && pointerY > screenHeight - _edgeThreshold)) {
      // Apply boost multiplier when near screen edges
      speed = math.min(_maxScrollSpeed, speed * _edgeBoostMultiplier);
    }

    return math.min(speed, _maxScrollSpeed);
  }

  /// Check if pointer is outside boundaries and start/stop auto-scroll
  void _checkAndHandleAutoScroll() {
    final provider = GalleryBoundariesProvider.of(context);
    if (provider == null) return;

    final topBoundary = provider.topBoundaryNotifier.value;
    final bottomBoundary = provider.bottomBoundaryNotifier.value;
    final scrollController = provider.scrollControllerNotifier.value;

    if (scrollController == null || !scrollController.hasClients) return;

    // Validate boundaries don't overlap (viewport too small)
    if (topBoundary != null &&
        bottomBoundary != null &&
        topBoundary >= bottomBoundary) {
      _stopAutoScroll();
      throw Exception(
        'Invalid boundaries: top boundary ($topBoundary) >= bottom boundary ($bottomBoundary). '
        'Viewport is too small for auto-scroll.',
      );
    }

    // Determine if we need to scroll and in which direction
    if (topBoundary != null && _currentPointerY < topBoundary) {
      // Pointer is above top boundary - scroll up
      final distance = topBoundary - _currentPointerY;
      _startAutoScroll(scrollController, -1, distance, topBoundary, true);
    } else if (bottomBoundary != null && _currentPointerY > bottomBoundary) {
      // Pointer is below bottom boundary - scroll down
      final distance = _currentPointerY - bottomBoundary;
      _startAutoScroll(scrollController, 1, distance, bottomBoundary, false);
    } else {
      // Pointer is within boundaries - stop scrolling
      _stopAutoScroll();
    }
  }

  /// Start auto-scrolling in the specified direction
  void _startAutoScroll(
    ScrollController controller,
    int direction,
    double distance,
    double boundaryPosition,
    bool scrollingUp,
  ) {
    // Cancel existing timer if any
    _stopAutoScroll();

    final scrollSpeed =
        _calculateScrollSpeed(distance, boundaryPosition, scrollingUp);

    // Start periodic timer for smooth scrolling at 120fps
    _autoScrollTimer = Timer.periodic(
      Duration(microseconds: (_scrollIntervalMs * 1000).toInt()),
      (_) {
        if (!mounted || !controller.hasClients) {
          _stopAutoScroll();
          return;
        }

        // Calculate new scroll position
        final currentOffset = controller.offset;
        final scrollDelta = scrollSpeed * direction;
        final newOffset = currentOffset + scrollDelta;

        // Clamp to scroll bounds
        final clampedOffset = newOffset.clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        );

        // Use jumpTo for immediate positioning (smoother than animateTo for continuous scroll)
        if (clampedOffset != currentOffset) {
          final scrollDelta = (clampedOffset - currentOffset).abs();
          controller.jumpTo(clampedOffset);

          // Accumulate scroll delta for synthetic event generation
          _accumulatedScrollDelta += scrollDelta;

          // Generate synthetic pointer event when threshold is reached
          // This reduces event frequency while maintaining selection responsiveness
          if (_accumulatedScrollDelta >= _syntheticEventThreshold &&
              widget.swipeActiveNotifier.value &&
              _activePointer != null) {
            final syntheticEvent = PointerMoveEvent(
              position: Offset(_currentPointerX, _currentPointerY),
              pointer: _activePointer!,
              timeStamp:
                  Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
            );
            GestureBinding.instance.handlePointerEvent(syntheticEvent);
            // Reset accumulator after generating event
            _accumulatedScrollDelta = 0;
          }
        }
      },
    );
  }

  /// Stop auto-scrolling
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _accumulatedScrollDelta = 0; // Reset accumulator when stopping
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }
}
