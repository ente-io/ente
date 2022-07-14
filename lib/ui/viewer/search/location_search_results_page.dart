import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';

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

  const LocationSearchResultsPage(this.viewPort, this.name, {Key key})
      : super(key: key);

  @override
  State<LocationSearchResultsPage> createState() =>
      _LocationSearchResultsPageState();
}

class _LocationSearchResultsPageState extends State<LocationSearchResultsPage> {
  final _selectedFiles = SelectedFiles();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Gallery(
        tagPrefix: "location_search",
        selectedFiles: _selectedFiles,
        footer: const SizedBox(height: 120),
      ),
    );
  }

  List<File> _getResult() {
    List<File> files = [];
    final Map<String, dynamic> args = <String, dynamic>{};
    args['files'] = files;
    args['viewPort'] = widget.viewPort;
    return _filterPhotos(args);
  }

  static List<File> _filterPhotos(Map<String, dynamic> args) {
    List<File> files = args['files'];
    ViewPort viewPort = args['viewPort'];
    final result = <File>[];
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
