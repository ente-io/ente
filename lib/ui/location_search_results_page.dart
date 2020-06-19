import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/file.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/ui/gallery.dart';

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
        child: Gallery(
          () => _getResult(),
        ),
      ),
    );
  }

  FutureOr<List<File>> _getResult() async {
    final files = FileRepository.instance.files;
    final args = Map<String, dynamic>();
    args['files'] = files;
    args['viewPort'] = widget.viewPort;
    return _filterPhotos(args);
  }

  static List<File> _filterPhotos(Map<String, dynamic> args) {
    List<File> files = args['files'];
    ViewPort viewPort = args['viewPort'];
    final result = List<File>();
    for (final file in files) {
      if (file.location != null &&
          viewPort.northEast.latitude > file.location.latitude &&
          viewPort.southWest.latitude < file.location.latitude &&
          viewPort.northEast.longitude > file.location.longitude &&
          viewPort.southWest.longitude < file.location.longitude) {
        result.add(file);
      } else {}
    }
    return result;
  }
}
