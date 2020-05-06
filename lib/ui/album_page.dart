import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/album.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:logging/logging.dart';

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage(this.album, {Key key}) : super(key: key);

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final logger = Logger("AlbumPageState");
  Set<Photo> _selectedPhotos = Set<Photo>();
  StreamSubscription<LocalPhotosUpdatedEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        widget.album.name,
        _selectedPhotos,
        onSelectionClear: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      body: Gallery(
        _getFilteredPhotos(PhotoRepository.instance.photos),
        _selectedPhotos,
        photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
          setState(() {
            _selectedPhotos = selectedPhotos;
          });
        },
      ),
    );
  }

  List<Photo> _getFilteredPhotos(List<Photo> unfilteredPhotos) {
    final List<Photo> filteredPhotos = List<Photo>();
    for (Photo photo in unfilteredPhotos) {
      if (widget.album.filter.shouldInclude(photo)) {
        filteredPhotos.add(photo);
      }
    }
    return filteredPhotos;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
