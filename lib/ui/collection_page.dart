import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class CollectionPage extends StatelessWidget {
  final Collection collection;
  final String tagPrefix;
  final _selectedFiles = SelectedFiles();

  CollectionPage(this.collection, {this.tagPrefix = "collection", Key key})
      : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit}) {
        return FilesDB.instance.getFilesInCollection(
            collection.id, creationStartTime, creationEndTime,
            limit: limit);
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == collection.id),
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: gallery,
        ),
        Container(
          height: 80,
          child: GalleryAppBarWidget(
            GalleryAppBarType.collection,
            collection.name,
            _selectedFiles,
            collection: collection,
          ),
        )
      ]),
    );
  }
}
