import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/face_search_manager.dart';
import 'package:photos/models/face.dart';
import 'package:photos/ui/circular_network_image_widget.dart';
import 'package:photos/ui/face_search_results_page.dart';
import 'package:photos/ui/loading_widget.dart';

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
        title: TypeAheadField(
          textFieldConfiguration: TextFieldConfiguration(
            autofocus: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search your photos',
              contentPadding: const EdgeInsets.all(0.0),
            ),
          ),
          hideOnEmpty: true,
          hideOnLoading: true,
          loadingBuilder: (context) {
            return loadWidget;
          },
          debounceDuration: Duration(milliseconds: 100),
          suggestionsCallback: (pattern) async {
            if (pattern.isEmpty) {
              return null;
            }
            return (await Dio().get(
                    "https://maps.googleapis.com/maps/api/place/textsearch/json",
                    queryParameters: {
                  "query": pattern,
                  "key": "AIzaSyC9lAYIERrNFsCkdLxX6DmZfPhybTKod8U",
                }))
                .data["results"];
          },
          itemBuilder: (context, suggestion) {
            if (suggestion == null) {
              return null;
            }
            return LocationSearchResultWidget(suggestion['name']);
          },
          onSuggestionSelected: (suggestion) {
            // Navigator.of(context).push(MaterialPageRoute(
            //     builder: (context) => ProductPage(product: suggestion)));
          },
        ),
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

class LocationSearchResultWidget extends StatelessWidget {
  final String name;
  const LocationSearchResultWidget(
    this.name, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: new EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
      margin: EdgeInsets.symmetric(vertical: 6.0),
      child: Column(children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.location_on,
            ),
            Padding(padding: EdgeInsets.only(left: 20.0)),
            Flexible(
              child: Container(
                child: Text(
                  name,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
