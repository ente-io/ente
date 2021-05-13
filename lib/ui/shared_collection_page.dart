import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class SharedCollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final _selectedFiles = SelectedFiles();

  SharedCollectionPage(this.c, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    var gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInCollection(
            c.collection.id, creationStartTime, creationEndTime,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == c.collection.id),
      tagPrefix: "shared_collection",
      selectedFiles: _selectedFiles,
      initialFiles: [c.thumbnail],
    );
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: gallery,
          ),
          Container(
            height: 80,
            child: GalleryAppBarWidget(
              GalleryAppBarType.shared_collection,
              c.collection.name,
              _selectedFiles,
              collection: c.collection,
            ),
          )
        ],
      ),
    );
  }
}
