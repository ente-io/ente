import 'package:flutter/material.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/face_search_manager.dart';
import 'package:myapp/models/face.dart';
import 'package:myapp/models/search_result.dart';
import 'package:myapp/ui/circular_network_image_widget.dart';
import 'package:myapp/core/constants.dart' as Constants;
import 'package:myapp/ui/network_image_detail_page.dart';

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
                Constants.ENDPOINT + _face.thumbnailURL, 20),
          )
        ],
      ),
      body: Container(
        child: _getBody(),
      ),
    );
  }

  FutureBuilder<List<SearchResult>> _getBody() {
    return FutureBuilder<List<SearchResult>>(
      future: _faceSearchManager.getFaceSearchResults(_face),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GridView.builder(
              itemBuilder: (_, index) => _buildItem(
                  context, Constants.ENDPOINT + snapshot.data[index].url),
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

  Widget _buildItem(BuildContext context, String url) {
    return GestureDetector(
      onTap: () {
        _routeToDetailPage(url, context);
      },
      child: Container(
        margin: EdgeInsets.all(2),
        child: Image.network(url, height: 124, width: 124, fit: BoxFit.cover),
      ),
    );
  }

  void _routeToDetailPage(String url, BuildContext context) {
    final page = NetworkImageDetailPage(url);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
