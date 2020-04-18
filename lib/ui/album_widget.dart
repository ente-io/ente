import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/models/album.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/gallery.dart';
import 'package:myapp/ui/gallery_app_bar_widget.dart';

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage(this.album, {Key key}) : super(key: key);

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Set<Photo> _selectedPhotos = Set<Photo>();

  @override
  Widget build(Object context) {
    Logger().i("Building with " + widget.album.photos.length.toString());
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
              Logger().i("Deleting " + index.toString());
              widget.album.photos.removeAt(index);
            }
          });
        },
      ),
      body: Gallery(
        widget.album.photos,
        photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
          setState(() {
            _selectedPhotos = selectedPhotos;
          });
        },
      ),
    );
  }
}
