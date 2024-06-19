import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";

///This is an inherited widget that needs to be wrapped around Gallery and
///FileSelectionOverlayBar to make select all work.
// ignore: must_be_immutable
class SelectionState extends InheritedWidget {
  final SelectedFiles selectedFiles;

  ///Should be assigned later in gallery when files are loaded.
  ///Note: EnteFiles in this list should be references of the same EnteFiles
  ///that are grouped in gallery, so that when files are added/deleted,
  ///both lists are in sync.
  List<EnteFile>? allGalleryFiles;

  SelectionState({
    Key? key,
    required this.selectedFiles,
    required Widget child,
  }) : super(key: key, child: child);

  static SelectionState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SelectionState>();
  }

  static SelectionState? of(BuildContext context) {
    final SelectionState? result = maybeOf(context);
    if (result == null) {
      Logger("SelectionState").warning(
        "No SelectionState found in context. Ignore this if file selection is disabled in the gallery used.",
      );
    }
    return result;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
