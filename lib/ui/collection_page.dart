import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class CollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final GalleryAppBarType appBarType;
  final _selectedFiles = SelectedFiles();

  CollectionPage(this.c,
      {this.tagPrefix = "collection",
      this.appBarType = GalleryAppBarType.collection,
      Key key})
      : super(key: key);

  @override
  Widget build(Object context) {
    final initialFiles = c.thumbnail != null ? [c.thumbnail] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInCollection(
            c.collection.id, creationStartTime, creationEndTime,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == c.collection.id),
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
    );
    return Scaffold(
      body: Stack(children: [
        Padding(
          padding: EdgeInsets.only(top: Platform.isAndroid ? 80 : 100),
          child: gallery,
        ),
        Container(
          height: Platform.isAndroid ? 80 : 100,
          child: GalleryAppBarWidget(
            appBarType,
            c.collection.name,
            _selectedFiles,
            collection: c.collection,
          ),
        )
      ]),
    );
  }
}
