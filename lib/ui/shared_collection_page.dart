import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class SharedCollectionPage extends StatefulWidget {
  final Collection collection;

  const SharedCollectionPage(this.collection, {Key key}) : super(key: key);

  @override
  _SharedCollectionPageState createState() => _SharedCollectionPageState();
}

class _SharedCollectionPageState extends State<SharedCollectionPage> {
  final _selectedFiles = SelectedFiles();

  @override
  Widget build(Object context) {
    var gallery = Gallery(
      asyncLoader: (lastFile, limit) => FilesDB.instance
          .getAllInCollectionBeforeCreationTime(
              widget.collection.id,
              lastFile == null
                  ? DateTime.now().microsecondsSinceEpoch
                  : lastFile.creationTime,
              limit),
      // onRefresh: () => FolderSharingService.instance.syncDiff(widget.folder),
      tagPrefix: "shared_collection",
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.shared_collection,
        widget.collection.name,
        _selectedFiles,
      ),
      body: gallery,
    );
  }
}
