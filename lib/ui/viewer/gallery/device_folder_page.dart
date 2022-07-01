import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/galleryType.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery_overlay_widget.dart';

class DeviceFolderPage extends StatelessWidget {
  final DeviceFolder folder;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInPath(
          folder.path,
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
      tagPrefix: "device_folder:" + folder.path,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? _getHeaderWidget()
          : Container(),
      initialFiles: [folder.thumbnail],
      footer: SizedBox(height: 32),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          GalleryType.local_folder,
          folder.name,
          _selectedFiles,
          path: folder.thumbnail.deviceFolder,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          GalleryOverlayWidget(
            GalleryType.local_folder,
            _selectedFiles,
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
      color: Theme.of(context).colorScheme.backupEnabledBgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isBackedUp
              ? Text("Backup enabled")
              : Text(
                  "Backup disabled",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .defaultTextColor
                        .withOpacity(0.7),
                  ),
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
