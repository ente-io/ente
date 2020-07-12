import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/file.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:logging/logging.dart';

class DeviceFolderPage extends StatefulWidget {
  final DeviceFolder folder;

  const DeviceFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _DeviceFolderPageState createState() => _DeviceFolderPageState();
}

class _DeviceFolderPageState extends State<DeviceFolderPage> {
  final logger = Logger("DeviceFolderPageState");
  Set<File> _selectedFiles = Set<File>();

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.local_folder,
        widget.folder.name,
        widget.folder.thumbnail.deviceFolder,
        _selectedFiles,
        onSelectionClear: () {
          setState(() {
            _selectedFiles.clear();
          });
        },
      ),
      body: Gallery(
        syncLoader: () => _getFilteredFiles(FileRepository.instance.files),
        selectedFiles: _selectedFiles,
        onFileSelectionChange: (Set<File> selectedFiles) {
          setState(() {
            _selectedFiles = selectedFiles;
          });
        },
        reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      ),
    );
  }

  List<File> _getFilteredFiles(List<File> unfilteredFiles) {
    if (widget.folder.filter == null) {
      return unfilteredFiles;
    }
    final List<File> filteredFiles = List<File>();
    for (File file in unfilteredFiles) {
      if (widget.folder.filter.shouldInclude(file)) {
        filteredFiles.add(file);
      }
    }
    return filteredFiles;
  }
}
