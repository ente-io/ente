import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/huge_listview/place_holder_widget.dart";
import "package:photos/ui/viewer/gallery/component/lazy_loading_gallery.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:visibility_detector/visibility_detector.dart";

class NonRecyclableViewWidget extends StatefulWidget {
  final bool shouldRender;
  final List<File> filesInDay;
  final int photoGridSize;
  final bool limitSelectionToOne;
  final String tag;
  final GalleryLoader asyncLoader;
  final int? currentUserID;
  final SelectedFiles? selectedFiles;
  const NonRecyclableViewWidget({
    required this.shouldRender,
    required this.filesInDay,
    required this.photoGridSize,
    required this.limitSelectionToOne,
    required this.tag,
    required this.asyncLoader,
    this.currentUserID,
    this.selectedFiles,
    super.key,
  });

  @override
  State<NonRecyclableViewWidget> createState() =>
      _NonRecyclableViewWidgetState();
}

class _NonRecyclableViewWidgetState extends State<NonRecyclableViewWidget> {
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
        key: Key("gallery" + widget.filesInDay.first.tag),
        onVisibilityChanged: (visibility) {
          if (mounted && visibility.visibleFraction > 0 && !_shouldRender) {
            setState(() {
              _shouldRender = true;
            });
          }
        },
        child:
            PlaceHolderWidget(widget.filesInDay.length, widget.photoGridSize),
      );
    } else {
      return GalleryGridViewWidget(
        filesInDay: widget.filesInDay,
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
