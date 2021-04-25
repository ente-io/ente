import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
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
      asyncLoader: (creationStartTime, creationEndTime, {limit}) {
        return FilesDB.instance.getFilesInPath(
            widget.folder.path, creationStartTime, creationEndTime,
            limit: limit);
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      tagPrefix: "device_folder:" + widget.folder.path,
      selectedFiles: _selectedFiles,
      headerWidget: Configuration.instance.hasConfiguredAccount()
          ? _getHeaderWidget()
          : Container(),
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
    return BackupConfigurationHeaderWidget(widget.folder.path);
  }
}

class BackupConfigurationHeaderWidget extends StatefulWidget {
  final String path;

  BackupConfigurationHeaderWidget(this.path, {Key key}) : super(key: key);

  @override
  _BackupConfigurationHeaderWidgetState createState() =>
      _BackupConfigurationHeaderWidgetState();
}

class _BackupConfigurationHeaderWidgetState
    extends State<BackupConfigurationHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final isBackedUp =
        Configuration.instance.getPathsToBackUp().contains(widget.path);
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12),
      margin: EdgeInsets.only(bottom: 12),
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
                current.add(widget.path);
              } else {
                current.remove(widget.path);
              }
              Configuration.instance.setPathsToBackUp(current);
              setState(() {});
              Bus.instance.fire(BackupFoldersUpdatedEvent());
            },
          ),
        ],
      ),
    );
  }
}
