import "package:flutter/material.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";

class GalleryContextState extends InheritedWidget {
  ///Sorting by creation time
  final bool sortOrderAsc;
  final bool inSelectionMode;
  final GroupType type;

  const GalleryContextState({
    this.inSelectionMode = false,
    this.type = GroupType.day,
    required this.sortOrderAsc,
    required super.child,
    super.key,
  });

  static GalleryContextState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GalleryContextState>();
  }

  @override
  bool updateShouldNotify(GalleryContextState oldWidget) {
    return sortOrderAsc != oldWidget.sortOrderAsc ||
        inSelectionMode != oldWidget.inSelectionMode ||
        type != oldWidget.type;
  }
}
