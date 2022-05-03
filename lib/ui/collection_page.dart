import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class CollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final GalleryAppBarType appBarType;
  final _selectedFiles = SelectedFiles();

  CollectionPage(this.c,
      {this.tagPrefix = "collection",
      this.appBarType = GalleryAppBarType.owned_collection,
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
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
      },
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
      smallerTodayFont: true,
      albumName: c.collection.name,
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryAppBarWidget(
              appBarType,
              c.collection.name,
              _selectedFiles,
              collection: c.collection,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
              child: Text(
                c.collection.name,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
          ],
        ),
      ),
      body: gallery,
    );
  }
}
