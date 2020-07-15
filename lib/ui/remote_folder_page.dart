import 'package:flutter/material.dart';
import 'package:photos/db/file_db.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class RemoteFolderPage extends StatefulWidget {
  final Folder folder;

  const RemoteFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _RemoteFolderPageState createState() => _RemoteFolderPageState();
}

class _RemoteFolderPageState extends State<RemoteFolderPage> {
  @override
  Widget build(Object context) {
    var gallery = Gallery(
      asyncLoader: (offset, limit) =>
          FileDB.instance.getAllInFolder(widget.folder.id, offset, limit),
      onRefresh: () => FolderSharingService.instance.syncDiff(widget.folder),
      tagPrefix: "remote_folder",
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        gallery,
        GalleryAppBarType.remote_folder,
        widget.folder.name,
        widget.folder.deviceFolder,
      ),
      body: gallery,
    );
  }
}
