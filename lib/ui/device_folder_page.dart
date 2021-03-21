import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
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
    final gallery = Gallery(
      asyncLoader: (_, __) => FilesDB.instance.getAllInPath(widget.folder.path),
      shouldLoadAll: true,
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      tagPrefix: "device_folder:" + widget.folder.path,
      selectedFiles: _selectedFiles,
      headerWidget: _getHeaderWidget(),
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

  Widget _getHeaderWidget() {
    final isBackedUp =
        Configuration.instance.getPathsToBackUp().contains(widget.folder.path);
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12),
      color: Colors.grey.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isBackedUp
              ? Text("backup enabled")
              : Text(
                  "backup disabled",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
          Switch(
            value: isBackedUp,
            onChanged: (value) async {
              final current = Configuration.instance.getPathsToBackUp();
              if (value) {
                current.add(widget.folder.path);
              } else {
                current.remove(widget.folder.path);
              }
              Configuration.instance.setPathsToBackUp(current);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
