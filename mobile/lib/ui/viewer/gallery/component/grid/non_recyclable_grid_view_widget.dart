import "package:flutter/material.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/component/grid/gallery_grid_view_widget.dart";
import "package:photos/ui/viewer/gallery/component/grid/place_holder_grid_view_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:visibility_detector/visibility_detector.dart";

class NonRecyclableGridViewWidget extends StatefulWidget {
  final bool shouldRender;
  final List<EnteFile> filesInGroup;
  final int photoGridSize;
  final bool limitSelectionToOne;
  final String tag;
  final GalleryLoader asyncLoader;
  final int? currentUserID;
  final SelectedFiles? selectedFiles;
  const NonRecyclableGridViewWidget({
    required this.shouldRender,
    required this.filesInGroup,
    required this.photoGridSize,
    required this.limitSelectionToOne,
    required this.tag,
    required this.asyncLoader,
    this.currentUserID,
    this.selectedFiles,
    super.key,
  });

  @override
  State<NonRecyclableGridViewWidget> createState() =>
      _NonRecyclableGridViewWidgetState();
}

class _NonRecyclableGridViewWidgetState
    extends State<NonRecyclableGridViewWidget> {
  late bool _shouldRender;
  @override
  void initState() {
    _shouldRender = widget.shouldRender;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender) {
      return VisibilityDetector(
        key: Key("gallery" + widget.filesInGroup.first.tag),
        onVisibilityChanged: (visibility) {
          if (mounted && visibility.visibleFraction > 0 && !_shouldRender) {
            setState(() {
              _shouldRender = true;
            });
          }
        },
        child: PlaceHolderGridViewWidget(
          widget.filesInGroup.length,
          widget.photoGridSize,
        ),
      );
    } else {
      return GalleryGridViewWidget(
        filesInGroup: widget.filesInGroup,
        photoGridSize: widget.photoGridSize,
        limitSelectionToOne: widget.limitSelectionToOne,
        tag: widget.tag,
        asyncLoader: widget.asyncLoader,
        selectedFiles: widget.selectedFiles,
        currentUserID: widget.currentUserID,
      );
    }
  }
}
