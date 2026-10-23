import "package:flutter/widgets.dart";

class GalleryVisibilityScope extends InheritedWidget {
  const GalleryVisibilityScope({
    required this.visible,
    required super.child,
    super.key,
  });

  final bool visible;

  static bool isVisibleOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GalleryVisibilityScope>()
          ?.visible ??
      true;

  @override
  bool updateShouldNotify(GalleryVisibilityScope oldWidget) =>
      visible != oldWidget.visible;
}
