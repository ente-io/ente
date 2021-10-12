import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class TrashPage extends StatelessWidget {
  final String tagPrefix;
  final GalleryAppBarType appBarType;
  final _selectedFiles = SelectedFiles();

  TrashPage(
      {this.tagPrefix = "trash_page",
      this.appBarType = GalleryAppBarType.trash,
      Key key})
      : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return TrashDB.instance.getTrashedFiles(
            creationStartTime, creationEndTime,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance.on<CollectionUpdatedEvent>(),
      forceReloadEvents: [Bus.instance.on<CollectionUpdatedEvent>()],
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: null,
    );
    return Scaffold(
      body: Stack(children: [
        Padding(
          padding: EdgeInsets.only(top: Platform.isAndroid ? 80 : 100),
          child: gallery,
        ),
        SizedBox(
          height: Platform.isAndroid ? 80 : 100,
          child: GalleryAppBarWidget(
            appBarType,
            "trash",
            _selectedFiles,
          ),
        )
      ]),
    );
  }
}
