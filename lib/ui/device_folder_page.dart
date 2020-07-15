import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/file.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';

class DeviceFolderPage extends StatefulWidget {
  final DeviceFolder folder;

  const DeviceFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _DeviceFolderPageState createState() => _DeviceFolderPageState();
}

class _DeviceFolderPageState extends State<DeviceFolderPage> {
  final _selectedFiles = SelectedFiles();

  @override
  Widget build(Object context) {
    var gallery = Gallery(
      syncLoader: () => _getFilteredFiles(FileRepository.instance.files),
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      tagPrefix: "device_folder",
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.local_folder,
        widget.folder.name,
        _selectedFiles,
        widget.folder.thumbnail.deviceFolder,
      ),
      body: gallery,
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
