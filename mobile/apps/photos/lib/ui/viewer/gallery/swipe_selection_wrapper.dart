import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
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

  @override
  void initState() {
    widget.swipeActiveNotifier.addListener(() {
      print(
        'DEBUG SWIPE: swipeActiveNotifier changed to ${widget.swipeActiveNotifier.value}',
      );
    });
    super.initState();
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
        onPointerDown: (_) {
          // Reset initial movement tracking for new gesture
          _initialMovementWasHorizontal = null;
        },
        onPointerMove: (event) {
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
        },
        onPointerUp: (_) {
          // End swipe selection when pointer is released
          widget.swipeHelper?.endSelection();
          widget.swipeActiveNotifier.value = false;
          _initialMovementWasHorizontal = null;
        },
        onPointerCancel: (_) {
          // Also end selection on cancel
          widget.swipeHelper?.endSelection();
          widget.swipeActiveNotifier.value = false;
          _initialMovementWasHorizontal = null;
        },
        child: widget.child,
      ),
    );
  }
}
