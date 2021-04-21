import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
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
      creationTimesLoader: () => FilesDB.instance
          .getAllCreationTimesInCollection(widget.collection.id),
      asyncLoader: (creationStartTime, creationEndTime, {limit}) {
        return FilesDB.instance.getFilesInCollection(
            widget.collection.id, creationStartTime, creationEndTime,
            limit: limit);
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == widget.collection.id),
      tagPrefix: "shared_collection",
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.shared_collection,
        widget.collection.name,
        _selectedFiles,
        collection: widget.collection,
      ),
      body: gallery,
    );
  }
}
