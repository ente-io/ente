import "package:flutter/widgets.dart";
import "package:photos/core/constants.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

class GalleryGridViewWidget extends StatelessWidget {
  final List<EnteFile> filesInGroup;
  final int photoGridSize;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tag;
  final int? currentUserID;
  final GalleryLoader asyncLoader;
  const GalleryGridViewWidget({
    required this.filesInGroup,
    required this.photoGridSize,
    this.selectedFiles,
    required this.limitSelectionToOne,
    required this.tag,
    super.key,
    this.currentUserID,
    required this.asyncLoader,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return GalleryFileWidget(
          file: filesInGroup[index],
          selectedFiles: selectedFiles,
          limitSelectionToOne: limitSelectionToOne,
          tag: tag,
          photoGridSize: photoGridSize,
          currentUserID: currentUserID,
          filesInGroup: filesInGroup,
          asyncLoader: asyncLoader,
        );
      },
      itemCount: filesInGroup.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        crossAxisCount: photoGridSize,
      ),
      padding: const EdgeInsets.symmetric(vertical: (galleryGridSpacing / 2)),
    );
  }
}
