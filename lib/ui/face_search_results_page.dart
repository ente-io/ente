import 'package:flutter/material.dart';
import 'package:myapp/face_search_manager.dart';
import 'package:myapp/models/face.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/circular_network_image_widget.dart';
import 'package:myapp/core/constants.dart' as Constants;
import 'package:myapp/ui/image_widget.dart';

import 'detail_page.dart';

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
          Hero(
            tag: "face_" + _face.faceID.toString(),
            child: CircularNetworkImageWidget(
                Constants.ENDPOINT + "/" + _face.thumbnailPath, 20),
          )
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
          return GridView.builder(
              itemBuilder: (_, index) =>
                  _buildItem(context, snapshot.data, index),
              itemCount: snapshot.data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ));
        } else {
          return Text("Loading...");
        }
      },
    );
  }

  Widget _buildItem(BuildContext context, List<Photo> photos, int index) {
    return GestureDetector(
      onTap: () async {
        _routeToDetailPage(photos, index, context);
      },
      child: ImageWidget(photos[index]),
    );
  }

  void _routeToDetailPage(
      List<Photo> photos, int index, BuildContext context) async {
    var page = DetailPage(photos, index);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
