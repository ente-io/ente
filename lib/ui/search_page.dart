import 'package:flutter/material.dart';
import 'package:myapp/face_search_manager.dart';
import 'package:myapp/models/face.dart';
import 'package:myapp/core/constants.dart' as Constants;

class SearchPage extends StatelessWidget {
  final FaceSearchManager _faceSearchManager = FaceSearchManager();
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
    return new Container(
        width: 60.0,
        height: 60.0,
        margin: const EdgeInsets.only(right: 8),
        decoration: new BoxDecoration(
            shape: BoxShape.circle,
            image: new DecorationImage(
                fit: BoxFit.contain,
                image:
                    new NetworkImage(Constants.ENDPOINT + face.thumbnailURL))));
  }
}
