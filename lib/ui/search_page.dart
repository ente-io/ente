import 'package:flutter/material.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/ui/circular_network_image_widget.dart';
import 'package:photos/ui/face_search_results_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/location_search_widget.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FaceSearchManager _faceSearchManager = FaceSearchManager.instance;
  String _searchString = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LocationSearchWidget(),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: Container(
        child: _searchString.isEmpty ? _getSearchSuggestions() : Container(),
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
      child: CircularNetworkImageWidget(face.getThumbnailUrl(), 60),
    );
  }

  void _routeToSearchResults(Face face, BuildContext context) {
    final page = FaceSearchResultsPage(face);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
