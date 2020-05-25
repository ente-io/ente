import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/loading_widget.dart';

class RemoteFolderPage extends StatefulWidget {
  final Folder folder;

  const RemoteFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _RemoteFolderPageState createState() => _RemoteFolderPageState();
}

class _RemoteFolderPageState extends State<RemoteFolderPage> {
  final _logger = Logger("RemoteFolderPageState");
  Set<Photo> _selectedPhotos = Set<Photo>();
  StreamSubscription<RemoteSyncEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<RemoteSyncEvent>().listen((event) {
      if (event.success) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.remote_folder,
        widget.folder.name,
        widget.folder.thumbnailPhoto.deviceFolder,
        _selectedPhotos,
        onSelectionClear: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      body: FutureBuilder<List<Photo>>(
        future: PhotoDB.instance.getAllPhotosInFolder(widget.folder.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Gallery(snapshot.data, _selectedPhotos,
                photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
              setState(() {
                _selectedPhotos = selectedPhotos;
              });
            });
          } else if (snapshot.hasError) {
            _logger.shout(snapshot.error);
            return Text(snapshot.error.toString());
          } else {
            return loadWidget;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
