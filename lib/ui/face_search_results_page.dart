import 'package:flutter/material.dart';
import 'package:photos/services/face_search_service.dart';
import 'package:photos/models/face.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class FaceSearchResultsPage extends StatelessWidget {
  final FaceSearchService _faceSearchManager = FaceSearchService.instance;
  final Face face;
  final selectedFiles = SelectedFiles();

  FaceSearchResultsPage(this.face, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var gallery = Gallery(
      asyncLoader: (lastFile, limit) => _faceSearchManager.getFaceSearchResults(
          face,
          lastFile == null
              ? DateTime.now().microsecondsSinceEpoch
              : lastFile.creationTime,
          limit),
      tagPrefix: "face_search_results",
      selectedFiles: selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.search_results,
        "Search results",
        selectedFiles,
      ),
      body: Container(
        child: gallery,
      ),
    );
  }
}
