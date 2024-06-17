import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class DeviceFolderPage extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final _selectedFiles = SelectedFiles();

  DeviceFolderPage(this.deviceCollection, {Key? key}) : super(key: key);

  @override
  Widget build(Object context) {
    final int? userID = Configuration.instance.getUserID();
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInDeviceCollection(
          deviceCollection,
          userID,
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
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            FileSelectionOverlayBar(
              GalleryType.localFolder,
              _selectedFiles,
            ),
          ],
        ),
      ),
    );
  }
}

class BackupHeaderWidget extends StatefulWidget {
  final DeviceCollection deviceCollection;

  const BackupHeaderWidget(this.deviceCollection, {super.key});

  @override
  State<BackupHeaderWidget> createState() => _BackupHeaderWidgetState();
}

class _BackupHeaderWidgetState extends State<BackupHeaderWidget> {
  late Future<List<EnteFile>> filesInDeviceCollection;
  late ValueNotifier<bool> shouldBackup;
  final Logger _logger = Logger("_BackupHeaderWidgetState");
  @override
  void initState() {
    shouldBackup = ValueNotifier(widget.deviceCollection.shouldBackup);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filesInDeviceCollection = _filesInDeviceCollection();

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
                captionedTextWidget:
                    CaptionedTextWidget(title: S.of(context).backup),
                singleBorderRadius: 8.0,
                menuItemColor: colorScheme.fillFaint,
                alignCaptionedTextToLeft: true,
                trailingWidget: ToggleSwitchWidget(
                  value: () => shouldBackup.value,
                  onChanged: () async {
                    _logger.fine(
                      "Toggling device folder sync status to "
                      "${!shouldBackup.value}",
                    );
                    try {
                      await RemoteSyncService.instance
                          .updateDeviceFolderSyncStatus(
                        {widget.deviceCollection.id: !shouldBackup.value},
                      );
                      if (mounted) {
                        setState(() {
                          shouldBackup.value = !shouldBackup.value;
                        });
                      }
                    } catch (e) {
                      _logger.severe(
                        "Could not update device folder sync status",
                        e,
                      );
                    }
                  },
                ),
              ),
              ValueListenableBuilder(
                valueListenable: shouldBackup,
                builder: (BuildContext context, bool value, _) {
                  return MenuSectionDescriptionWidget(
                    content: value
                        ? S.of(context).deviceFilesAutoUploading
                        : S.of(context).turnOnBackupForAutoUpload,
                  );
                },
              ),
              FutureBuilder(
                future: _hasIgnoredFiles(filesInDeviceCollection),
                builder: (context, snapshot) {
                  bool shouldShowReset = false;
                  if (snapshot.hasData &&
                      snapshot.data as bool &&
                      shouldBackup.value) {
                    shouldShowReset = true;
                  } else if (snapshot.hasError) {
                    Logger("BackupHeaderWidget").severe(
                      "Could not check if collection has ignored files",
                    );
                  }
                  return AnimatedCrossFade(
                    firstCurve: Curves.easeInOutExpo,
                    secondCurve: Curves.easeInOutExpo,
                    sizeCurve: Curves.easeInOutExpo,
                    firstChild: ResetIgnoredFilesWidget(
                      filesInDeviceCollection,
                      () => setState(() {}),
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                    crossFadeState: shouldShowReset
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 1000),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<EnteFile>> _filesInDeviceCollection() async {
    return (await FilesDB.instance.getFilesInDeviceCollection(
      widget.deviceCollection,
      Configuration.instance.getUserID(),
      galleryLoadStartTime,
      galleryLoadEndTime,
    ))
        .files;
  }

  Future<bool> _hasIgnoredFiles(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) async {
    final List<EnteFile> deviceCollectionFiles = await filesInDeviceCollection;
    final allIgnoredIDs =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    if (allIgnoredIDs.isEmpty) {
      return false;
    }
    for (EnteFile file in deviceCollectionFiles) {
      final String? ignoreID =
          IgnoredFilesService.instance.getIgnoredIDForFile(file);
      if (ignoreID != null && allIgnoredIDs.containsKey(ignoreID)) {
        return true;
      }
    }
    return false;
  }
}

class ResetIgnoredFilesWidget extends StatefulWidget {
  final Future<List<EnteFile>> filesInDeviceCollection;
  final VoidCallback parentSetState;
  const ResetIgnoredFilesWidget(
    this.filesInDeviceCollection,
    this.parentSetState, {
    super.key,
  });

  @override
  State<ResetIgnoredFilesWidget> createState() =>
      _ResetIgnoredFilesWidgetState();
}

class _ResetIgnoredFilesWidgetState extends State<ResetIgnoredFilesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).resetIgnoredFiles,
          ),
          singleBorderRadius: 8.0,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          leadingIcon: Icons.cloud_off_outlined,
          alwaysShowSuccessState: true,
          onTap: () async {
            await _removeFilesFromIgnoredFiles(
              widget.filesInDeviceCollection,
            );
            // ignore: unawaited_futures
            RemoteSyncService.instance.sync(silently: true).then((value) {
              if (mounted) {
                widget.parentSetState.call();
              }
            });
          },
        ),
        MenuSectionDescriptionWidget(
          content: S.of(context).ignoredFolderUploadReason,
        ),
      ],
    );
  }

  Future<void> _removeFilesFromIgnoredFiles(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) async {
    final List<EnteFile> deviceCollectionFiles = await filesInDeviceCollection;
    await IgnoredFilesService.instance
        .removeIgnoredMappings(deviceCollectionFiles);
  }
}
