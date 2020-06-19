import 'package:flutter/material.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class RemoteFolderPage extends StatefulWidget {
  final Folder folder;

  const RemoteFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _RemoteFolderPageState createState() => _RemoteFolderPageState();
}

class _RemoteFolderPageState extends State<RemoteFolderPage> {
  Set<File> _selectedPhotos = Set<File>();

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
      body: Gallery(() => FileDB.instance.getAllInFolder(widget.folder.id),
          onRefresh: () =>
              FolderSharingService.instance.syncDiff(widget.folder),
          selectedFiles: _selectedPhotos,
          onFileSelectionChange: (Set<File> selectedPhotos) {
            setState(
              () {
                _selectedPhotos = selectedPhotos;
              },
            );
          }),
    );
  }
}
