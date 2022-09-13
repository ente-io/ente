// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery_overlay_widget.dart';

class DeviceFolderPage extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.deviceCollection, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInDeviceCollection(
          deviceCollection,
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
      tagPrefix: "device_folder:" + deviceCollection.name,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? BackupConfigurationHeaderWidget(deviceCollection)
          : const SizedBox.shrink(),
      initialFiles: [deviceCollection.thumbnail],
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          GalleryType.localFolder,
          deviceCollection.name,
          _selectedFiles,
          deviceCollection: deviceCollection,
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
  final DeviceCollection deviceCollection;

  const BackupConfigurationHeaderWidget(this.deviceCollection, {Key key})
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
    _isBackedUp = widget.deviceCollection.shouldBackup;
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
              await RemoteSyncService.instance.updateDeviceFolderSyncStatus(
                {widget.deviceCollection.id: value},
              );
              _isBackedUp = value;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
