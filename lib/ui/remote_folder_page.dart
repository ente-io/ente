import 'package:flutter/material.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class RemoteFolderPage extends StatefulWidget {
  final Folder folder;

  const RemoteFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _RemoteFolderPageState createState() => _RemoteFolderPageState();
}

class _RemoteFolderPageState extends State<RemoteFolderPage> {
  Set<Photo> _selectedPhotos = Set<Photo>();

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
          onRefresh: () =>
              FolderSharingService.instance.syncDiff(widget.folder),
          selectedPhotos: _selectedPhotos,
          onPhotoSelectionChange: (Set<Photo> selectedPhotos) {
            setState(
              () {
                _selectedPhotos = selectedPhotos;
              },
            );
          }),
    );
  }
}
