import 'package:flutter/material.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class FaceSearchResultsPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  final Face face;

  FaceSearchResultsPage(this.face, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var gallery = Gallery(
      asyncLoader: (offset, limit) =>
          _faceSearchManager.getFaceSearchResults(face, offset, limit),
      tagPrefix: "face_search_results",
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        gallery,
        GalleryAppBarType.search_results,
        "Search results",
      ),
      body: Container(
        child: gallery,
      ),
    );
  }
}
