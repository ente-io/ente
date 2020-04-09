import 'package:flutter/material.dart';
import 'package:myapp/face_search_manager.dart';
import 'package:myapp/models/face.dart';
import 'package:myapp/core/constants.dart' as Constants;
import 'package:myapp/ui/circular_network_image_widget.dart';
import 'package:myapp/ui/face_search_results_page.dart';

class SearchPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: "search",
          flightShuttleBuilder: (BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext) =>
              Material(child: toHeroContext.widget),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search your photos',
              contentPadding: const EdgeInsets.all(0.0),
            ),
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
        } else {
          return Text("Loading...");
        }
      },
    );
  }

  Widget _buildItem(BuildContext context, Face face) {
    return GestureDetector(
      onTap: () {
        _routeToSearchResults(face, context);
      },
      child: Hero(
        tag: "face_" + face.faceID.toString(),
        child: CircularNetworkImageWidget(
            Constants.ENDPOINT + "/" + face.thumbnailPath, 60),
      ),
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
