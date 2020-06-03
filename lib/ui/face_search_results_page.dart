import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/circular_network_image_widget.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/loading_widget.dart';

class FaceSearchResultsPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  final Face _face;

  FaceSearchResultsPage({Key key, Face face})
      : this._face = face,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search results"),
        actions: <Widget>[
          CircularNetworkImageWidget(
              Configuration.instance.getHttpEndpoint() +
                  "/" +
                  _face.thumbnailPath,
              20),
        ],
      ),
      body: Container(
        child: _getBody(),
      ),
    );
  }

  FutureBuilder<List<Photo>> _getBody() {
    return FutureBuilder<List<Photo>>(
      future: _faceSearchManager.getFaceSearchResults(_face),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Gallery(
            snapshot.data,
            Set<Photo>(),
          );
        } else {
          return Center(child: loadWidget);
        }
      },
    );
  }
}
