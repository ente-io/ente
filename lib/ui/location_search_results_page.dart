import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/loading_widget.dart';

class ViewPort {
  final Location northEast;
  final Location southWest;

  ViewPort(this.northEast, this.southWest);

  @override
  String toString() => 'ViewPort(northEast: $northEast, southWest: $southWest)';
}

class LocationSearchResultsPage extends StatefulWidget {
  final ViewPort viewPort;
  final String name;

  LocationSearchResultsPage(this.viewPort, this.name, {Key key})
      : super(key: key);

  @override
  _LocationSearchResultsPageState createState() =>
      _LocationSearchResultsPageState();
}

class _LocationSearchResultsPageState extends State<LocationSearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        child: _getBody(),
      ),
    );
  }

  FutureBuilder<List<Photo>> _getBody() {
    return FutureBuilder<List<Photo>>(
      future: _getResult(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return Center(child: Text("Nothing to see here."));
          }
          return Gallery(
            snapshot.data,
            Set<Photo>(),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return Center(child: loadWidget);
        }
      },
    );
  }

  FutureOr<List<Photo>> _getResult() async {
    final photos = PhotoRepository.instance.photos;
    final args = Map<String, dynamic>();
    args['photos'] = photos;
    args['viewPort'] = widget.viewPort;
    return _filterPhotos(args);
  }

  static List<Photo> _filterPhotos(Map<String, dynamic> args) {
    List<Photo> photos = args['photos'];
    ViewPort viewPort = args['viewPort'];
    final result = List<Photo>();
    for (final photo in photos) {
      if (photo.location != null &&
          viewPort.northEast.latitude > photo.location.latitude &&
          viewPort.southWest.latitude < photo.location.latitude &&
          viewPort.northEast.longitude > photo.location.longitude &&
          viewPort.southWest.longitude < photo.location.longitude) {
        result.add(photo);
      } else {}
    }
    return result;
  }
}
