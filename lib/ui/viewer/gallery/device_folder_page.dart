import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery_overlay_widget.dart';

class DeviceFolderPage extends StatelessWidget {
  final DevicePathCollection devicePathCollection;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.devicePathCollection, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInDevicePathCollection(
          devicePathCollection,
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
      tagPrefix: "device_folder:" + devicePathCollection.name,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? BackupConfigurationHeaderWidget(devicePathCollection)
          : const SizedBox.shrink(),
      initialFiles: [devicePathCollection.thumbnail],
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          GalleryType.localFolder,
          devicePathCollection.name,
          _selectedFiles,
          devicePathCollection: devicePathCollection,
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

class BackupConfigurationHeaderWidget extends StatefulWidget {
  final DevicePathCollection devicePathCollection;

  const BackupConfigurationHeaderWidget(this.devicePathCollection, {Key key})
      : super(key: key);

  @override
  State<BackupConfigurationHeaderWidget> createState() =>
      _BackupConfigurationHeaderWidgetState();
}

class _BackupConfigurationHeaderWidgetState
    extends State<BackupConfigurationHeaderWidget> {
  bool _isBackedUp;

  @override
  void initState() {
    _isBackedUp = widget.devicePathCollection.sync;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 4, bottom: 4),
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.backupEnabledBgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _isBackedUp
              ? const Text("Backup enabled")
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
            value: _isBackedUp,
            onChanged: (value) async {
              await FilesDB.instance.updateDevicePathSyncStatus(
                {widget.devicePathCollection.id: value},
              );
              _isBackedUp = value;
              setState(() {});
              Bus.instance.fire(BackupFoldersUpdatedEvent());
            },
          ),
        ],
      ),
    );
  }
}
