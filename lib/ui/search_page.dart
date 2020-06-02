import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/ui/circular_network_image_widget.dart';
import 'package:photos/ui/face_search_results_page.dart';
import 'package:photos/ui/loading_widget.dart';

class SearchPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search your photos',
            contentPadding: const EdgeInsets.all(0.0),
          ),
        ),
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: Container(
        child: _getSearchSuggestions(),
      ),
    );
  }

  Widget _getSearchSuggestions() {
    return FutureBuilder<List<Face>>(
      future: _faceSearchManager.getFaces(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            height: 60,
            margin: EdgeInsets.only(top: 4, left: 4),
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  return _buildItem(context, snapshot.data[index]);
                }),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: " + snapshot.error.toString()));
        } else {
          return Center(child: loadWidget);
        }
      },
    );
  }

  Widget _buildItem(BuildContext context, Face face) {
    return GestureDetector(
      onTap: () {
        _routeToSearchResults(face, context);
      },
      child: CircularNetworkImageWidget(
          Configuration.instance.getHttpEndpoint() + "/" + face.thumbnailPath,
          60),
    );
  }

  void _routeToSearchResults(Face face, BuildContext context) {
    final page = FaceSearchResultsPage(
      face: face,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
