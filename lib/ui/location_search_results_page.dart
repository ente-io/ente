import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/loading_widget.dart';

class LocationSearchResultsPage extends StatefulWidget {
  final LatLng location;
  final String name;

  LocationSearchResultsPage(this.location, this.name, {Key key})
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
          return Gallery(
            snapshot.data,
            Set<Photo>(),
          );
        } else {
          return Center(child: loadWidget);
        }
      },
    );
  }

  Future<List<Photo>> _getResult() async {
    final photos = PhotoRepository.instance.photos;
    final args = Map<String, dynamic>();
    args['photos'] = photos;
    args['location'] = widget.location;
    args['maxDistance'] = 5000;
    return await compute(_filterPhotos, args);
  }

  static List<Photo> _filterPhotos(Map<String, dynamic> args) {
    List<Photo> photos = args['photos'];
    LatLng location = args['location'];
    int maxDistance = args['maxDistance'];
    final result = List<Photo>();
    for (final photo in photos) {
      final distance = Distance().as(LengthUnit.Meter, location,
          new LatLng(photo.latitude, photo.longitude));
      if (distance < maxDistance) {
        result.add(photo);
      }
    }
    return result;
  }
}
