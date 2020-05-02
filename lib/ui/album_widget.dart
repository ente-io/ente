import 'package:flutter/material.dart';
import 'package:photos/models/album.dart';
import 'package:photos/models/photo.dart';
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
        onPhotosDeleted: (deletedPhotos) {
          setState(() {
            for (Photo deletedPhoto in deletedPhotos) {
              var index = widget.album.photos.indexOf(deletedPhoto);
              logger.info("Deleting " + index.toString());
              widget.album.photos.removeAt(index);
            }
            _selectedPhotos.clear();
          });
        },
      ),
      body: Gallery(
        widget.album.photos,
        _selectedPhotos,
        photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
          setState(() {
            _selectedPhotos = selectedPhotos;
          });
        },
      ),
    );
  }
}
