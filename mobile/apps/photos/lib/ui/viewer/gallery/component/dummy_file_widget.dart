import "package:flutter/material.dart";
import "package:photos/models/file/dummy_file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/viewer/gallery/component/swipe_selectable_file_widget.dart";

/// A widget that displays a dummy placeholder in the gallery grid.
/// Participates in swipe gesture tracking but is not selectable.
class DummyFileWidget extends StatefulWidget {
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
  State<DummyFileWidget> createState() => _DummyFileWidgetState();
}

class _DummyFileWidgetState extends State<DummyFileWidget> {
  @override
  Widget build(BuildContext context) {
    // Check if swipe selection should be enabled (same as GalleryFileWidget)
    final shouldEnableSwipeSelection =
        flagService.internalUser && !widget.limitSelectionToOne;

    final Widget dummyContent = _buildDummyContent();

    // Wrap with swipe selection if enabled
    if (shouldEnableSwipeSelection) {
      return SwipeSelectableFileWidget(
        file: widget.file,
        selectedFiles: widget.selectedFiles,
        onPointerStateChanged: (pointerId, isInside) {
          // Track pointer state but don't use it since dummies aren't selectable
        },
        child: dummyContent,
      );
    }

    return dummyContent;
  }

  Widget _buildDummyContent() {
    // Simple grey placeholder that doesn't respond to taps or selections
    return Container(
      color: Colors.grey.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }
}
