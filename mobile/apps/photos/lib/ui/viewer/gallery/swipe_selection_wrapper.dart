import 'dart:async';
import 'dart:math' as math;

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

  // Auto-scroll constants
  static const double _baseScrollSpeed = 2.0; // Base speed in pixels per frame
  static const double _maxScrollSpeed = 15.0; // Maximum speed cap
  static const double _scrollIntervalMs = 8.33; // ~120fps in milliseconds
  static const double _exponentialFactor =
      0.015; // Controls speed increase rate

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
          _currentPointerY = event.position.dy;
          // Reset initial movement tracking for new gesture
          _initialMovementWasHorizontal = null;
        },
        onPointerMove: (event) {
          _currentPointerY = event.position.dy;
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
        },
        onPointerCancel: (_) {
          _stopAutoScroll();
          // Also end selection on cancel
          widget.swipeHelper?.endSelection();
          widget.swipeActiveNotifier.value = false;
          _initialMovementWasHorizontal = null;
        },
        child: widget.child,
      ),
    );
  }

  /// Calculate exponential scroll speed based on distance from boundary
  double _calculateScrollSpeed(double distanceFromBoundary) {
    // Exponential formula: speed = base * e^(factor * distance)
    final speed =
        _baseScrollSpeed * math.exp(_exponentialFactor * distanceFromBoundary);
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
      _startAutoScroll(scrollController, -1, distance);
    } else if (bottomBoundary != null && _currentPointerY > bottomBoundary) {
      // Pointer is below bottom boundary - scroll down
      final distance = _currentPointerY - bottomBoundary;
      _startAutoScroll(scrollController, 1, distance);
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
  ) {
    // Cancel existing timer if any
    _stopAutoScroll();

    final scrollSpeed = _calculateScrollSpeed(distance);

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
          controller.jumpTo(clampedOffset);
        }
      },
    );
  }

  /// Stop auto-scrolling
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }
}
