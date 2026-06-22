import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
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
import 'package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class DeviceFolderPage extends StatefulWidget {
  final DeviceCollection deviceCollection;

  const DeviceFolderPage(this.deviceCollection, {super.key});

  @override
  State<DeviceFolderPage> createState() => _DeviceFolderPageState();
}

class _DeviceFolderPageState extends State<DeviceFolderPage> {
  final _logger = Logger("_DeviceFolderPageState");
  final _selectedFiles = SelectedFiles();
  late bool _shouldBackup;

  @override
  void initState() {
    super.initState();
    _shouldBackup = widget.deviceCollection.shouldBackup;
  }

  Future<FileLoadResult> _loadFiles(
    int creationStartTime,
    int creationEndTime, {
    int? limit,
    bool? asc,
  }) async {
    final int? userID = Configuration.instance.getUserID();
    return FilesDB.instance.getFilesInDeviceCollection(
      widget.deviceCollection,
      userID,
      creationStartTime,
      creationEndTime,
      limit: limit,
      asc: asc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appBar = GalleryAppBarWidget.sliverConfig(
      GalleryType.localFolder,
      widget.deviceCollection.name,
      _selectedFiles,
      subtitle: _shouldBackup ? l10n.backedUpAutomatically : l10n.notBackedUp,
      deviceCollection: widget.deviceCollection,
      isDeviceFolderBackedUp: _shouldBackup,
      onDisableDeviceFolderBackup: () async {
        await _updateBackupStatus(false);
      },
    );
    final gallery = Gallery(
      key: ValueKey("device_folder:${widget.deviceCollection.id}"),
      appBar: appBar,
      asyncLoader: _loadFiles,
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
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
              shouldBackup: _shouldBackup,
              onBackupChanged: _updateBackupStatus,
              onOpenSkippedFiles: _openSkippedFiles,
            )
          : const SizedBox.shrink(),
      initialFiles: _initialFiles,
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

  Future<bool> _updateBackupStatus(bool shouldBackup) async {
    if (_shouldBackup == shouldBackup) {
      return true;
    }
    _logger.info("Toggling device folder sync status to $shouldBackup");
    try {
      await RemoteSyncService.instance.updateDeviceFolderSyncStatus({
        widget.deviceCollection.id: shouldBackup,
      });
      await backupPreferenceService.setHasManualFolderSelection(true);
      if (!mounted) {
        return true;
      }
      setState(() {
        _shouldBackup = shouldBackup;
      });
      return true;
    } catch (e, s) {
      _logger.severe("Could not update device folder sync status", e, s);
      return false;
    }
  }

  Future<void> _openSkippedFiles() async {
    await routeToPage(
      context,
      SkippedDeviceFolderPage(
        widget.deviceCollection,
        shouldBackup: _shouldBackup,
        onBackupChanged: _updateBackupStatus,
      ),
    );
  }
}

class BackupHeaderWidget extends StatefulWidget {
  final DeviceCollection deviceCollection;
  final bool shouldBackup;
  final Future<bool> Function(bool shouldBackup) onBackupChanged;
  final Future<void> Function() onOpenSkippedFiles;

  const BackupHeaderWidget(
    this.deviceCollection, {
    required this.shouldBackup,
    required this.onBackupChanged,
    required this.onOpenSkippedFiles,
    super.key,
  });

  @override
  State<BackupHeaderWidget> createState() => _BackupHeaderWidgetState();
}

class _BackupHeaderWidgetState extends State<BackupHeaderWidget> {
  final _logger = Logger("_BackupHeaderWidgetState");
  Future<Set<IgnoredUploadReasonBucket>> _ignoredUploadBuckets = Future.value(
    const <IgnoredUploadReasonBucket>{},
  );

  @override
  void initState() {
    super.initState();
    if (widget.shouldBackup) {
      _refreshIgnoredState();
    }
  }

  @override
  void didUpdateWidget(covariant BackupHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBackup &&
        (oldWidget.deviceCollection.id != widget.deviceCollection.id ||
            !oldWidget.shouldBackup)) {
      _refreshIgnoredState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shouldBackup) {
      return _buildSkippedFilesRow(context);
    }
    return _paddedHeader(_buildBackupRow(context));
  }

  Widget _buildBackupRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuItemWidgetNew(
      title: l10n.backup,
      subText: l10n.autoUploadFromThisDeviceFolder,
      titleToSubTextSpacing: 2,
      leadingIconWidget: _menuIcon(context, HugeIcons.strokeRoundedUpload01),
      trailingWidget: ToggleSwitchWidget(
        value: () => widget.shouldBackup,
        onChanged: () async {
          await widget.onBackupChanged(!widget.shouldBackup);
        },
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSkippedFilesRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Set<IgnoredUploadReasonBucket>>(
      future: _ignoredUploadBuckets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.severe("Could not check if collection has ignored files");
          return const SizedBox.shrink();
        }
        final visibleBuckets = _visibleIgnoredUploadBuckets(
          snapshot.data ?? <IgnoredUploadReasonBucket>{},
        );
        if (visibleBuckets.isEmpty) {
          return const SizedBox.shrink();
        }
        return _paddedHeader(
          MenuItemWidgetNew(
            title: l10n.skippedFiles,
            subText: l10n.chooseReasonToViewFiles,
            titleToSubTextSpacing: 2,
            leadingIconWidget: _menuIcon(
              context,
              HugeIcons.strokeRoundedReload,
            ),
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () async {
              await widget.onOpenSkippedFiles();
              if (!mounted) {
                return;
              }
              setState(_refreshIgnoredState);
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }

  Widget _paddedHeader(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: child,
    );
  }

  void _refreshIgnoredState() {
    _ignoredUploadBuckets = _ignoredUploadReasonBuckets(
      _filesInDeviceCollectionFor(widget.deviceCollection),
    );
  }
}

class SkippedDeviceFolderPage extends StatefulWidget {
  final DeviceCollection deviceCollection;
  final bool shouldBackup;
  final Future<bool> Function(bool shouldBackup) onBackupChanged;

  const SkippedDeviceFolderPage(
    this.deviceCollection, {
    required this.shouldBackup,
    required this.onBackupChanged,
    super.key,
  });

  @override
  State<SkippedDeviceFolderPage> createState() =>
      _SkippedDeviceFolderPageState();
}

class _SkippedDeviceFolderPageState extends State<SkippedDeviceFolderPage> {
  final _logger = Logger("_SkippedDeviceFolderPageState");
  final _selectedFiles = SelectedFiles();
  final _filterReloadController = StreamController<FilesUpdatedEvent>();
  late final StreamSubscription<LocalPhotosUpdatedEvent> _localPhotosSub;
  late Future<List<EnteFile>> _filesInDeviceCollection;
  late Future<Set<IgnoredUploadReasonBucket>> _ignoredUploadBuckets;
  late bool _shouldBackup;
  IgnoredUploadReasonBucket? _selectedBucket;

  @override
  void initState() {
    super.initState();
    _shouldBackup = widget.shouldBackup;
    _refreshIgnoredState();
    _localPhotosSub = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((_) {
      if (!mounted) {
        return;
      }
      setState(_refreshIgnoredState);
      unawaited(_syncSelectedBucket(popIfEmpty: true));
    });
    unawaited(_syncSelectedBucket(popIfEmpty: false));
  }

  Future<FileLoadResult> _loadFiles(
    int creationStartTime,
    int creationEndTime, {
    int? limit,
    bool? asc,
  }) async {
    final selectedBucket = _selectedBucket;
    if (selectedBucket == null) {
      return FileLoadResult(const [], false);
    }
    final files = await _refreshFilesInDeviceCollection();
    final idToReasonMap =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    return FileLoadResult(
      files
          .where(
            (file) =>
                _ignoredUploadReasonBucketForFile(idToReasonMap, file) ==
                selectedBucket,
          )
          .toList(),
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appBar = GalleryAppBarWidget.sliverConfig(
      GalleryType.localFolder,
      l10n.skippedFiles,
      _selectedFiles,
      deviceCollection: widget.deviceCollection,
      isDeviceFolderBackedUp: _shouldBackup,
      onDisableDeviceFolderBackup: () async {
        await _updateBackupStatus(false);
      },
    );
    final gallery = Gallery(
      key: ValueKey("skipped_device_folder:${widget.deviceCollection.id}"),
      appBar: appBar,
      asyncLoader: _loadFiles,
      forceReloadEvents: [_filterReloadController.stream],
      removalEventTypes: const {
        EventType.deletedFromDevice,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: "skipped_device_folder:${widget.deviceCollection.name}",
      galleryType: GalleryType.localFolder,
      selectedFiles: _selectedFiles,
      header: SkippedFilesHeaderWidget(
        availableBuckets: _ignoredUploadBuckets,
        selectedBucket: _selectedBucket,
        onBucketChanged: _onBucketChanged,
        onResetIgnoredFiles: _resetFilesInSelectedReason,
      ),
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

  void _onBucketChanged(IgnoredUploadReasonBucket bucket) {
    if (_selectedBucket == bucket) {
      return;
    }
    _selectedFiles.clearAll();
    setState(() {
      _selectedBucket = bucket;
    });
    _reloadSkippedFiles("ignoredUploadFilterChanged:${bucket.name}");
  }

  Future<void> _resetFilesInSelectedReason() async {
    final selectedBucket = _selectedBucket;
    if (selectedBucket == null) {
      return;
    }
    final files = await _ignoredFilesForBucket(selectedBucket);
    await IgnoredFilesService.instance.removeIgnoredMappings(files);
    await RemoteSyncService.instance.sync(silently: true);
    if (!mounted) {
      return;
    }
    setState(_refreshIgnoredState);
    await _syncSelectedBucket(popIfEmpty: true);
  }

  Future<void> _updateBackupStatus(bool shouldBackup) async {
    final updated = await widget.onBackupChanged(shouldBackup);
    if (!mounted || !updated) {
      return;
    }
    setState(() {
      _shouldBackup = shouldBackup;
    });
    if (!shouldBackup) {
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _syncSelectedBucket({required bool popIfEmpty}) async {
    try {
      final buckets = await _ignoredUploadBuckets;
      if (!mounted) {
        return;
      }
      final visibleBuckets = _visibleIgnoredUploadBuckets(buckets);
      if (visibleBuckets.isEmpty) {
        setState(() {
          _selectedBucket = null;
        });
        _reloadSkippedFiles("ignoredUploadBucketsEmpty");
        if (popIfEmpty) {
          await Navigator.of(context).maybePop();
        }
        return;
      }
      final currentBucket = _selectedBucket;
      final nextBucket =
          currentBucket != null && visibleBuckets.contains(currentBucket)
          ? currentBucket
          : visibleBuckets.first;
      if (nextBucket != _selectedBucket) {
        setState(() {
          _selectedBucket = nextBucket;
        });
      }
      _reloadSkippedFiles("ignoredUploadBucketsChanged");
    } catch (e, s) {
      _logger.severe("Could not refresh ignored upload buckets", e, s);
    }
  }

  Future<List<EnteFile>> _ignoredFilesForBucket(
    IgnoredUploadReasonBucket bucket,
  ) async {
    final files = await _filesInDeviceCollection;
    final idToReasonMap =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    return files
        .where(
          (file) =>
              _ignoredUploadReasonBucketForFile(idToReasonMap, file) == bucket,
        )
        .toList();
  }

  void _refreshIgnoredState() {
    _filesInDeviceCollection = _refreshFilesInDeviceCollection();
    _ignoredUploadBuckets = _ignoredUploadReasonBuckets(
      _filesInDeviceCollection,
    );
  }

  Future<List<EnteFile>> _refreshFilesInDeviceCollection() {
    final files = _filesInDeviceCollectionFor(widget.deviceCollection);
    _filesInDeviceCollection = files;
    return files;
  }

  void _reloadSkippedFiles(String source) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _filterReloadController.isClosed) {
        return;
      }
      _filterReloadController.add(FilesUpdatedEvent(const [], source: source));
    });
  }

  @override
  void dispose() {
    _localPhotosSub.cancel();
    _filterReloadController.close();
    super.dispose();
  }
}

class SkippedFilesHeaderWidget extends StatelessWidget {
  final Future<Set<IgnoredUploadReasonBucket>> availableBuckets;
  final IgnoredUploadReasonBucket? selectedBucket;
  final ValueChanged<IgnoredUploadReasonBucket> onBucketChanged;
  final Future<void> Function() onResetIgnoredFiles;

  const SkippedFilesHeaderWidget({
    required this.availableBuckets,
    required this.selectedBucket,
    required this.onBucketChanged,
    required this.onResetIgnoredFiles,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<IgnoredUploadReasonBucket>>(
      future: availableBuckets,
      builder: (context, snapshot) {
        final visibleBuckets = _visibleIgnoredUploadBuckets(
          snapshot.data ?? <IgnoredUploadReasonBucket>{},
        );
        if (visibleBuckets.isEmpty) {
          return const SizedBox.shrink();
        }
        final effectiveSelectedBucket = selectedBucket ?? visibleBuckets.first;
        final canResetIgnoredFiles = _canResetIgnoredFiles(
          effectiveSelectedBucket,
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final bucket in visibleBuckets)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TagChipComponent(
                          key: ValueKey("ignored_upload_filter_${bucket.name}"),
                          label: ignoredUploadReasonBucketLabel(
                            context,
                            bucket,
                          ),
                          state: effectiveSelectedBucket == bucket
                              ? TagChipComponentState.selected
                              : TagChipComponentState.unselected,
                          onTap: () => onBucketChanged(bucket),
                        ),
                      ),
                  ],
                ),
              ),
              if (canResetIgnoredFiles) const SizedBox(height: 20),
              if (canResetIgnoredFiles)
                _ResetIgnoredFilesSection(
                  onResetIgnoredFiles: onResetIgnoredFiles,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResetIgnoredFilesSection extends StatelessWidget {
  final Future<void> Function() onResetIgnoredFiles;

  const _ResetIgnoredFilesSection({required this.onResetIgnoredFiles});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).resetIgnoredFilesDescription,
          style: textTheme.smallMuted,
        ),
        const SizedBox(height: 12),
        ButtonComponent(
          variant: ButtonComponentVariant.secondary,
          label: AppLocalizations.of(context).resetIgnoredFiles,
          onTap: onResetIgnoredFiles,
        ),
      ],
    );
  }
}

Future<List<EnteFile>> _filesInDeviceCollectionFor(
  DeviceCollection deviceCollection,
) async {
  return (await FilesDB.instance.getFilesInDeviceCollection(
    deviceCollection,
    Configuration.instance.getUserID(),
    galleryLoadStartTime,
    galleryLoadEndTime,
  )).files;
}

Future<Set<IgnoredUploadReasonBucket>> _ignoredUploadReasonBuckets(
  Future<List<EnteFile>> filesInDeviceCollection,
) async {
  final deviceCollectionFiles = await filesInDeviceCollection;
  final allIgnoredIDs = await IgnoredFilesService.instance.idToIgnoreReasonMap;
  final buckets = <IgnoredUploadReasonBucket>{};
  for (final file in deviceCollectionFiles) {
    final bucket = _ignoredUploadReasonBucketForFile(allIgnoredIDs, file);
    if (bucket != null) {
      buckets.add(bucket);
    }
  }
  return buckets;
}

List<IgnoredUploadReasonBucket> _visibleIgnoredUploadBuckets(
  Set<IgnoredUploadReasonBucket> availableBuckets,
) {
  return [
    IgnoredUploadReasonBucket.deletedFromEnte,
    IgnoredUploadReasonBucket.iCloudUnavailable,
    IgnoredUploadReasonBucket.other,
  ].where(availableBuckets.contains).toList();
}

bool _canResetIgnoredFiles(IgnoredUploadReasonBucket bucket) {
  return bucket == IgnoredUploadReasonBucket.deletedFromEnte ||
      bucket == IgnoredUploadReasonBucket.other;
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

Widget _menuIcon(BuildContext context, List<List<dynamic>> icon) {
  return HugeIcon(
    icon: icon,
    color: getEnteColorScheme(context).menuItemIconStroke,
    size: 20,
  );
}

String ignoredUploadReasonBucketLabel(
  BuildContext context,
  IgnoredUploadReasonBucket bucket,
) {
  final l10n = AppLocalizations.of(context);
  return switch (bucket) {
    IgnoredUploadReasonBucket.iCloudUnavailable => l10n.iCloudUnavailable,
    IgnoredUploadReasonBucket.deletedFromEnte => l10n.deletedFromEnte,
    IgnoredUploadReasonBucket.other => l10n.others,
  };
}
