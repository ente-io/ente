import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';

class DeviceFolderPage extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.deviceCollection, {Key? key}) : super(key: key);

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
        EventType.hide,
      },
      tagPrefix: "device_folder:" + deviceCollection.name,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? BackupHeaderWidget(deviceCollection)
          : const SizedBox.shrink(),
      initialFiles: [deviceCollection.thumbnail!],
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
          FileSelectionOverlayBar(
            GalleryType.localFolder,
            _selectedFiles,
          )
        ],
      ),
    );
  }
}

class BackupHeaderWidget extends StatelessWidget {
  final DeviceCollection deviceCollection;

  const BackupHeaderWidget(this.deviceCollection, {super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> shouldBackup =
        ValueNotifier(deviceCollection.shouldBackup);
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuItemWidget(
                captionedTextWidget: const CaptionedTextWidget(title: "Backup"),
                borderRadius: 8.0,
                menuItemColor: colorScheme.fillFaint,
                alignCaptionedTextToLeft: true,
                trailingWidget: ToggleSwitchWidget(
                  value: () => shouldBackup.value,
                  onChanged: () async {
                    await RemoteSyncService.instance
                        .updateDeviceFolderSyncStatus(
                      {deviceCollection.id: !shouldBackup.value},
                    ).then(
                      (val) => shouldBackup.value = !shouldBackup.value,
                      onError: (e) {
                        Logger("BackupHeaderWidget").severe(
                          "Could not update device folder sync status",
                        );
                      },
                    );
                  },
                ),
              ),
              ValueListenableBuilder(
                valueListenable: shouldBackup,
                builder: (BuildContext context, bool value, _) {
                  return MenuSectionDescriptionWidget(
                    content: value
                        ? "Files added to this device album will automatically get uploaded to ente."
                        : "Turn on backup to automatically upload files added to this device folder to ente.",
                  );
                },
              ),
              const SizedBox(height: 24),
              MenuItemWidget(
                captionedTextWidget:
                    const CaptionedTextWidget(title: "Reset ignored files"),
                borderRadius: 8.0,
                menuItemColor: colorScheme.fillFaint,
                leadingIcon: Icons.cloud_off_outlined,
                onTap: () async {
                  await _removeFilesFromIgnoredFiles();
                  RemoteSyncService.instance.sync(silently: true);
                },
              ),
              const MenuSectionDescriptionWidget(
                content:
                    "Some files in this album are ignored from upload because they had previously been deleted from ente.",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeFilesFromIgnoredFiles() async {
    final List<File> filesInDeviceCollection =
        (await FilesDB.instance.getFilesInDeviceCollection(
      deviceCollection,
      galleryLoadStartTime,
      galleryLoadEndTime,
    ))
            .files;
    await IgnoredFilesService.instance
        .removeIgnoredMappings(filesInDeviceCollection);
  }
}
