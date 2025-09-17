import 'package:flutter/widgets.dart';
import 'package:photos/ui/viewer/gallery/swipe_to_select_helper.dart';

/// InheritedWidget to provide SwipeToSelectHelper to descendant widgets.
///
/// This allows GalleryFileWidget instances to access the swipe helper
/// without passing it through multiple widget constructors.
class GallerySwipeHelper extends InheritedWidget {
  final SwipeToSelectHelper? helper;

  const GallerySwipeHelper({
    super.key,
    this.helper,
    required super.child,
  });

  /// Get the SwipeToSelectHelper from the nearest ancestor GallerySwipeHelper.
  static SwipeToSelectHelper? of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<GallerySwipeHelper>();
    return widget?.helper;
  }

  @override
  bool updateShouldNotify(GallerySwipeHelper oldWidget) {
    // Only notify if the helper instance changes
    return helper != oldWidget.helper;
  }
}
