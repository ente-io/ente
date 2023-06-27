import "package:flutter/material.dart";

class GalleryContextState extends InheritedWidget {
  final bool sortOrderAsc;

  const GalleryContextState({
    required this.sortOrderAsc,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static GalleryContextState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GalleryContextState>();
  }

  @override
  bool updateShouldNotify(GalleryContextState oldWidget) {
    return sortOrderAsc != oldWidget.sortOrderAsc;
  }
}
