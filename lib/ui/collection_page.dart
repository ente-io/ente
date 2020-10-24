import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class CollectionPage extends StatefulWidget {
  final Collection collection;

  const CollectionPage(this.collection, {Key key}) : super(key: key);

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
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
      tagPrefix: "collection",
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.collection,
        widget.collection.name,
        _selectedFiles,
      ),
      body: gallery,
    );
  }
}
