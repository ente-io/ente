import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:logging/logging.dart';

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
        widget.folder.deviceFolder,
        _selectedPhotos,
        onSelectionClear: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      body: Gallery(
          () => PhotoDB.instance.getAllPhotosInFolder(widget.folder.id),
          syncFunction: () =>
              FolderSharingService.instance.syncDiff(widget.folder),
          selectedPhotos: _selectedPhotos,
          photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
            setState(
              () {
                _selectedPhotos = selectedPhotos;
              },
            );
          }),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
