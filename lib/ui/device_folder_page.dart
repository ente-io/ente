import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
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
      syncLoader: widget.folder.loader,
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      tagPrefix: "device_folder:" + widget.folder.path,
      selectedFiles: _selectedFiles,
    );
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.local_folder,
        widget.folder.name,
        _selectedFiles,
        path: widget.folder.thumbnail.deviceFolder,
      ),
      body: gallery,
    );
  }
}
