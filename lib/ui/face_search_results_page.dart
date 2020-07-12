import 'package:flutter/material.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/ui/circular_network_image_widget.dart';
import 'package:photos/ui/gallery.dart';

class FaceSearchResultsPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  final Face face;

  FaceSearchResultsPage(this.face, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search results"),
        actions: <Widget>[
          CircularNetworkImageWidget(face.getThumbnailUrl(), 20),
        ],
      ),
      body: Container(
        child: Gallery(
          asyncLoader: () => _faceSearchManager.getFaceSearchResults(face),
        ),
      ),
    );
  }
}
