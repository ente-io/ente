import 'package:flutter/material.dart';

/// InheritedWidget to share gallery boundaries and scroll controller
/// between Gallery and its surrounding widgets for auto-scroll functionality
class GalleryBoundariesProvider extends InheritedWidget {
  /// Bottom edge position of the top fixed widget (e.g., AppBar)
  final ValueNotifier<double?> topBoundaryNotifier;

  /// Top edge position of the bottom fixed widget (e.g., FileSelectionOverlayBar)
  final ValueNotifier<double?> bottomBoundaryNotifier;

  /// Reference to Gallery's ScrollController
  /// Using ValueNotifier to maintain immutability
  final ValueNotifier<ScrollController?> scrollControllerNotifier;

  const GalleryBoundariesProvider({
    super.key,
    required super.child,
    required this.topBoundaryNotifier,
    required this.bottomBoundaryNotifier,
    required this.scrollControllerNotifier,
  });

  /// Set the scroll controller from Gallery widget
  void setScrollController(ScrollController? controller) {
    scrollControllerNotifier.value = controller;
  }

  /// Set the top boundary position
  void setTopBoundary(double? boundary) {
    topBoundaryNotifier.value = boundary;
  }

  /// Set the bottom boundary position
  void setBottomBoundary(double? boundary) {
    bottomBoundaryNotifier.value = boundary;
  }

  static GalleryBoundariesProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GalleryBoundariesProvider>();
  }

  @override
  bool updateShouldNotify(GalleryBoundariesProvider oldWidget) {
    return scrollControllerNotifier != oldWidget.scrollControllerNotifier ||
        topBoundaryNotifier != oldWidget.topBoundaryNotifier ||
        bottomBoundaryNotifier != oldWidget.bottomBoundaryNotifier;
  }

  void dispose() {
    topBoundaryNotifier.dispose();
    bottomBoundaryNotifier.dispose();
    scrollControllerNotifier.dispose();
  }
}
