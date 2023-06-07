import "package:flutter/material.dart";

class GallerySortOrder extends InheritedWidget {
  final bool sortOrderAsc;

  const GallerySortOrder({
    required this.sortOrderAsc,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static GallerySortOrder? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GallerySortOrder>();
  }

  @override
  bool updateShouldNotify(GallerySortOrder oldWidget) {
    return sortOrderAsc != oldWidget.sortOrderAsc;
  }
}
