import "package:flutter/material.dart";
import "package:photos/models/file/dummy_file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/viewer/gallery/component/swipe_selectable_file_widget.dart";

/// A widget that displays a dummy placeholder in the gallery grid.
/// Participates in swipe gesture tracking but is not selectable.
class DummyFileWidget extends StatelessWidget {
  final DummyFile file;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;

  const DummyFileWidget({
    required this.file,
    required this.selectedFiles,
    required this.limitSelectionToOne,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final shouldEnableSwipeSelection =
        flagService.internalUser && !limitSelectionToOne;

    const Widget dummyContent = SizedBox.expand();

    if (shouldEnableSwipeSelection) {
      return SwipeSelectableFileWidget(
        file: file,
        selectedFiles: selectedFiles,
        child: dummyContent,
      );
    }

    return dummyContent;
  }
}
