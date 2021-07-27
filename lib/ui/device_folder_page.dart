import 'dart:io';

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

class DeviceFolderPage extends StatelessWidget {
  final DeviceFolder folder;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInPath(
            folder.path, creationStartTime, creationEndTime,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      tagPrefix: "device_folder:" + folder.path,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? _getHeaderWidget()
          : Container(),
      initialFiles: [folder.thumbnail],
    );
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: Platform.isAndroid ? 80 : 100),
            child: gallery,
          ),
          SizedBox(
            height: Platform.isAndroid ? 80 : 100,
            child: GalleryAppBarWidget(
              GalleryAppBarType.local_folder,
              folder.name,
              _selectedFiles,
              path: folder.thumbnail.deviceFolder,
            ),
          )
        ],
      ),
    );
  }

  Widget _getHeaderWidget() {
    return BackupConfigurationHeaderWidget(folder.path);
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
      padding: EdgeInsets.only(left: 20, right: 12, top: 4, bottom: 4),
      margin: EdgeInsets.only(bottom: 12),
      color: Color.fromRGBO(10, 40, 40, 0.3),
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
              await Configuration.instance.setPathsToBackUp(current);
              setState(() {});
              Bus.instance.fire(BackupFoldersUpdatedEvent());
            },
          ),
        ],
      ),
    );
  }
}
