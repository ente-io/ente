import "dart:async";

import "package:ente_components/ente_components.dart";
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
import "package:photos/models/file_load_result.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ignored_upload_reason.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/pending_translation.dart";

class DeviceFolderPage extends StatefulWidget {
  final DeviceCollection deviceCollection;

  const DeviceFolderPage(this.deviceCollection, {super.key});

  @override
  State<DeviceFolderPage> createState() => _DeviceFolderPageState();
}

class _DeviceFolderPageState extends State<DeviceFolderPage> {
  final _selectedFiles = SelectedFiles();
  final _filterReloadController = StreamController<FilesUpdatedEvent>();
  IgnoredUploadReasonBucket _ignoredUploadFilter =
      IgnoredUploadReasonBucket.all;

  void _onIgnoredUploadFilterChanged(IgnoredUploadReasonBucket bucket) {
    if (!mounted || _ignoredUploadFilter == bucket) {
      return;
    }
    _selectedFiles.clearAll();
    setState(() {
      _ignoredUploadFilter = bucket;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _filterReloadController.add(
        FilesUpdatedEvent(
          const [],
          source: "ignoredUploadFilterChanged:${bucket.name}",
        ),
      );
    });
  }

  Future<FileLoadResult> _loadFiles(
    int creationStartTime,
    int creationEndTime, {
    int? limit,
    bool? asc,
  }) async {
    final int? userID = Configuration.instance.getUserID();
    if (!flagService.resetSplitReason ||
        _ignoredUploadFilter == IgnoredUploadReasonBucket.all) {
      return FilesDB.instance.getFilesInDeviceCollection(
        widget.deviceCollection,
        userID,
        creationStartTime,
        creationEndTime,
        limit: limit,
        asc: asc,
      );
    }

    final result = await FilesDB.instance.getFilesInDeviceCollection(
      widget.deviceCollection,
      userID,
      galleryLoadStartTime,
      galleryLoadEndTime,
      asc: asc,
    );
    final idToReasonMap =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    return FileLoadResult(
      result.files
          .where(
            (file) =>
                _ignoredUploadReasonBucketForFile(idToReasonMap, file) ==
                _ignoredUploadFilter,
          )
          .toList(),
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = GalleryAppBarWidget.sliverConfig(
      GalleryType.localFolder,
      widget.deviceCollection.name,
      _selectedFiles,
      deviceCollection: widget.deviceCollection,
    );
    final gallery = Gallery(
      key: ValueKey("device_folder:${widget.deviceCollection.id}"),
      appBar: appBar,
      asyncLoader: _loadFiles,
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvents: [_filterReloadController.stream],
      removalEventTypes: const {
        EventType.deletedFromDevice,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: "device_folder:${widget.deviceCollection.name}",
      galleryType: GalleryType.localFolder,
      selectedFiles: _selectedFiles,
      header: Configuration.instance.hasConfiguredAccount()
          ? BackupHeaderWidget(
              widget.deviceCollection,
              selectedIgnoredUploadBucket: _ignoredUploadFilter,
              onIgnoredUploadBucketChanged: _onIgnoredUploadFilterChanged,
            )
          : const SizedBox.shrink(),
      initialFiles:
          !flagService.resetSplitReason ||
              _ignoredUploadFilter == IgnoredUploadReasonBucket.all
          ? _initialFiles
          : null,
    );
    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
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
        ),
      ),
    );
  }

  List<EnteFile>? get _initialFiles {
    final thumbnail = widget.deviceCollection.thumbnail;
    return thumbnail != null ? [thumbnail] : null;
  }

  @override
  void dispose() {
    _filterReloadController.close();
    super.dispose();
  }
}

class BackupHeaderWidget extends StatefulWidget {
  final DeviceCollection deviceCollection;
  final IgnoredUploadReasonBucket selectedIgnoredUploadBucket;
  final ValueChanged<IgnoredUploadReasonBucket> onIgnoredUploadBucketChanged;

  const BackupHeaderWidget(
    this.deviceCollection, {
    required this.selectedIgnoredUploadBucket,
    required this.onIgnoredUploadBucketChanged,
    super.key,
  });

  @override
  State<BackupHeaderWidget> createState() => _BackupHeaderWidgetState();
}

class _BackupHeaderWidgetState extends State<BackupHeaderWidget> {
  late bool shouldBackup;
  final Logger _logger = Logger("_BackupHeaderWidgetState");
  @override
  void initState() {
    shouldBackup = widget.deviceCollection.shouldBackup;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: AppLocalizations.of(context).backup,
            ),
            singleBorderRadius: 8.0,
            menuItemColor: colorScheme.fillFaint,
            alignCaptionedTextToLeft: true,
            trailingWidget: ToggleSwitchWidget(
              value: () => shouldBackup,
              onChanged: () async {
                _logger.info(
                  "Toggling device folder sync status to ${!shouldBackup}",
                );
                try {
                  await RemoteSyncService.instance.updateDeviceFolderSyncStatus(
                    {widget.deviceCollection.id: !shouldBackup},
                  );
                  await backupPreferenceService.setHasManualFolderSelection(
                    true,
                  );
                  if (mounted) {
                    final newShouldBackup = !shouldBackup;
                    setState(() {
                      shouldBackup = newShouldBackup;
                    });
                    if (!newShouldBackup) {
                      widget.onIgnoredUploadBucketChanged(
                        IgnoredUploadReasonBucket.all,
                      );
                    }
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
          MenuSectionDescriptionWidget(
            content: shouldBackup
                ? AppLocalizations.of(context).deviceFilesAutoUploading
                : AppLocalizations.of(context).turnOnBackupForAutoUpload,
          ),
          if (shouldBackup) _buildIgnoredUploadsControl(),
        ],
      ),
    );
  }

  Widget _buildIgnoredUploadsControl() {
    final filesInDeviceCollection = _filesInDeviceCollection();
    return flagService.resetSplitReason
        ? _buildIgnoredUploadFilter(filesInDeviceCollection)
        : _buildResetIgnoredFiles(filesInDeviceCollection);
  }

  Widget _buildIgnoredUploadFilter(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) {
    return FutureBuilder<Set<IgnoredUploadReasonBucket>>(
      future: _ignoredUploadReasonBuckets(filesInDeviceCollection),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.severe("Could not check if collection has ignored files");
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final buckets = snapshot.data!;
        _resetUnavailableIgnoredUploadFilter(buckets);
        if (buckets.isEmpty) {
          return const SizedBox.shrink();
        }
        return IgnoredUploadFilterWidget(
          availableBuckets: buckets,
          selectedBucket: widget.selectedIgnoredUploadBucket,
          onBucketChanged: widget.onIgnoredUploadBucketChanged,
        );
      },
    );
  }

  Widget _buildResetIgnoredFiles(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) {
    return FutureBuilder<bool>(
      future: _hasIgnoredFiles(filesInDeviceCollection),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.severe("Could not check if collection has ignored files");
          return const SizedBox.shrink();
        }
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return ResetIgnoredFilesWidget(
          filesInDeviceCollection,
          () => setState(() {}),
        );
      },
    );
  }

  Future<List<EnteFile>> _filesInDeviceCollection() async {
    return (await FilesDB.instance.getFilesInDeviceCollection(
      widget.deviceCollection,
      Configuration.instance.getUserID(),
      galleryLoadStartTime,
      galleryLoadEndTime,
    )).files;
  }

  Future<Set<IgnoredUploadReasonBucket>> _ignoredUploadReasonBuckets(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) async {
    final List<EnteFile> deviceCollectionFiles = await filesInDeviceCollection;
    final allIgnoredIDs =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    final buckets = <IgnoredUploadReasonBucket>{};
    for (final file in deviceCollectionFiles) {
      final bucket = _ignoredUploadReasonBucketForFile(allIgnoredIDs, file);
      if (bucket != null) {
        buckets.add(bucket);
      }
    }
    return buckets;
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
    for (final file in deviceCollectionFiles) {
      final ignoreID = IgnoredFilesService.instance.getIgnoredIDForFile(file);
      if (ignoreID != null && allIgnoredIDs.containsKey(ignoreID)) {
        return true;
      }
    }
    return false;
  }

  void _resetUnavailableIgnoredUploadFilter(
    Set<IgnoredUploadReasonBucket> buckets,
  ) {
    final selectedBucket = widget.selectedIgnoredUploadBucket;
    if (selectedBucket == IgnoredUploadReasonBucket.all) {
      return;
    }
    if (buckets.contains(selectedBucket)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onIgnoredUploadBucketChanged(IgnoredUploadReasonBucket.all);
    });
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
            title: AppLocalizations.of(context).resetIgnoredFiles,
          ),
          singleBorderRadius: 8.0,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          leadingIcon: Icons.cloud_off_outlined,
          alwaysShowSuccessState: true,
          onTap: () async {
            await _removeFilesFromIgnoredFiles(widget.filesInDeviceCollection);
            // ignore: unawaited_futures
            RemoteSyncService.instance.sync(silently: true).then((value) {
              if (mounted) {
                widget.parentSetState.call();
              }
            });
          },
        ),
        MenuSectionDescriptionWidget(
          content: AppLocalizations.of(context).ignoredFolderUploadReason,
        ),
      ],
    );
  }

  Future<void> _removeFilesFromIgnoredFiles(
    Future<List<EnteFile>> filesInDeviceCollection,
  ) async {
    final List<EnteFile> deviceCollectionFiles = await filesInDeviceCollection;
    await IgnoredFilesService.instance.removeIgnoredMappings(
      deviceCollectionFiles,
    );
  }
}

class IgnoredUploadFilterWidget extends StatelessWidget {
  final Set<IgnoredUploadReasonBucket> availableBuckets;
  final IgnoredUploadReasonBucket selectedBucket;
  final ValueChanged<IgnoredUploadReasonBucket> onBucketChanged;

  const IgnoredUploadFilterWidget({
    required this.availableBuckets,
    required this.selectedBucket,
    required this.onBucketChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBuckets = _visibleBuckets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final bucket in visibleBuckets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TagChipComponent(
                    key: ValueKey("ignored_upload_filter_${bucket.name}"),
                    label: ignoredUploadReasonBucketLabel(context, bucket),
                    state: selectedBucket == bucket
                        ? TagChipComponentState.selected
                        : TagChipComponentState.unselected,
                    onTap: () => onBucketChanged(bucket),
                  ),
                ),
            ],
          ),
        ),
        MenuSectionDescriptionWidget(
          content: pendingTranslation(
            "Some files in this album are excluded from backup. Select a reason to view them.",
          ),
        ),
      ],
    );
  }

  List<IgnoredUploadReasonBucket> get _visibleBuckets {
    return [
      IgnoredUploadReasonBucket.all,
      ...IgnoredUploadReasonBucket.values
          .where((bucket) => bucket != IgnoredUploadReasonBucket.all)
          .where(availableBuckets.contains),
    ];
  }
}

IgnoredUploadReasonBucket? _ignoredUploadReasonBucketForFile(
  Map<String, String> idToReasonMap,
  EnteFile file,
) {
  final reason = IgnoredFilesService.instance.getUploadSkipReason(
    idToReasonMap,
    file,
  );
  return reason == null ? null : ignoredUploadReasonBucketFor(reason);
}

String ignoredUploadReasonBucketLabel(
  BuildContext context,
  IgnoredUploadReasonBucket bucket,
) {
  final l10n = AppLocalizations.of(context);
  return switch (bucket) {
    IgnoredUploadReasonBucket.all => l10n.all,
    IgnoredUploadReasonBucket.iCloudUnavailable => pendingTranslation(
      "iCloud unavailable",
    ),
    IgnoredUploadReasonBucket.deletedFromEnte => pendingTranslation(
      "Deleted from Ente",
    ),
    IgnoredUploadReasonBucket.other => pendingTranslation("Other"),
  };
}
