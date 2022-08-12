import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery_overlay_widget.dart';

// This page is used to display all photos which are present on the local device
class DeviceAllPage extends StatelessWidget {
  final _selectedFiles = SelectedFiles();

  DeviceAllPage({Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getLocalDeviceFiles(
          creationStartTime,
          creationEndTime,
          limit: limit,
          asc: asc,
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromDevice,
        EventType.deletedFromEverywhere,
      },
      tagPrefix: "device_all",
      selectedFiles: _selectedFiles,
      initialFiles: null,
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          GalleryType.localAll,
          "On device",
          _selectedFiles,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          GalleryOverlayWidget(
            GalleryType.localFolder,
            _selectedFiles,
          )
        ],
      ),
    );
  }
}
