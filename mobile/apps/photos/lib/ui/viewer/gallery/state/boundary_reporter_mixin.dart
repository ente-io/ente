import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart';

enum BoundaryPosition { top, bottom }

/// Mixin for widgets that act as boundaries for auto-scroll
/// Reports their position to GalleryBoundariesProvider with debouncing
mixin BoundaryReporter<T extends StatefulWidget> on State<T> {
  final _boundaryKey = GlobalKey();
  Timer? _boundaryUpdateTimer;

  /// Report this widget's boundary to the provider
  /// Call this in initState, didUpdateWidget, and when size might change
  void reportBoundary(BoundaryPosition position) {
    // Debounce updates to avoid excessive recalculation
    _boundaryUpdateTimer?.cancel();
    _boundaryUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final renderBox =
          _boundaryKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final offset = renderBox.localToGlobal(Offset.zero);
        final boundary = position == BoundaryPosition.top
            ? offset.dy + renderBox.size.height // Bottom edge of top widget
            : offset.dy; // Top edge of bottom widget

        final provider = GalleryBoundariesProvider.of(context);
        if (provider != null) {
          if (position == BoundaryPosition.top) {
            provider.setTopBoundary(boundary);
          } else {
            provider.setBottomBoundary(boundary);
          }
        }
      }
    });
  }

  /// Widget that should have its boundary tracked
  /// Wrap your widget content with this
  Widget boundaryWidget({
    required Widget child,
    required BoundaryPosition position,
  }) {
    // Report boundary after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportBoundary(position);
    });

    return Container(
      key: _boundaryKey,
      child: child,
    );
  }

  @override
  void dispose() {
    _boundaryUpdateTimer?.cancel();
    super.dispose();
  }
}
