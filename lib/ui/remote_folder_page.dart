import 'package:flutter/material.dart';
import 'package:photos/db/file_db.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class RemoteFolderPage extends StatefulWidget {
  final Folder folder;

  const RemoteFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _RemoteFolderPageState createState() => _RemoteFolderPageState();
}

class _RemoteFolderPageState extends State<RemoteFolderPage> {
  final _selectedFiles = SelectedFiles();

  @override
  Widget build(Object context) {
    var gallery = Gallery(
      asyncLoader: (sinceFile, limit) => FileDB.instance.getAllInFolder(
          widget.folder.id,
          sinceFile == null ? 0 : sinceFile.updationTime,
          limit),
      onRefresh: () => FolderSharingService.instance.syncDiff(widget.folder),
      tagPrefix: "remote_folder",
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.remote_folder,
        widget.folder.name,
        _selectedFiles,
        widget.folder.deviceFolder,
      ),
      body: gallery,
    );
  }
}
