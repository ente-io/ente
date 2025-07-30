import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/home/home_gallery_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/utils/navigation_util.dart";

class JumpToDateGallery extends StatelessWidget {
  final EnteFile file;
  const JumpToDateGallery({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: HomeGalleryWidget(
          selectedFiles: SelectedFiles(),
          groupType: GroupType.day,
          fileToJumpScrollTo: file,
        ),
      ),
      appBar: AppBar(),
    );
  }

  static jumpToDate(EnteFile file, BuildContext context) {
    routeToPage(context, JumpToDateGallery(file: file));
  }
}
