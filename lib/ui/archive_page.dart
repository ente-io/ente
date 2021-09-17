import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/selected_files.dart';

import 'gallery.dart';
import 'gallery_app_bar_widget.dart';

class ArchivePage extends StatelessWidget {
  final String tagPrefix;
  final GalleryAppBarType appBarType;
  final _selectedFiles = SelectedFiles();

  ArchivePage(
      {this.tagPrefix = "archived_page",
      this.appBarType = GalleryAppBarType.archivedPage,
      Key key})
      : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesWithVisibility(
            creationStartTime, creationEndTime, 1,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where((event) =>
      event.updatedFiles
              .firstWhere((element) => element.uploadedFileID != null) !=
          null),
      forceReloadEvent: Bus.instance.on<FilesUpdatedEvent>().where((event) =>
      event.updatedFiles
          .firstWhere((element) => element.uploadedFileID != null) !=
          null),
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
            "archived memories",
            _selectedFiles,
          ),
        )
      ]),
    );
  }
}
