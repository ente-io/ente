import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class CollectionPage extends StatefulWidget {
  final Collection collection;
  final String tagPrefix;

  const CollectionPage(this.collection, {this.tagPrefix = "collection", Key key}) : super(key: key);

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
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == widget.collection.id),
      tagPrefix: widget.tagPrefix,
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.collection,
        widget.collection.name,
        _selectedFiles,
        collection: widget.collection,
      ),
      body: gallery,
    );
  }
}
