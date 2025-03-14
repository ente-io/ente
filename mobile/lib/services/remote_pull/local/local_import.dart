import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/errors.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/file_updation_db.dart';
import "package:photos/events/permission_granted_event.dart";
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/extensions/stop_watch.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/ignored_file.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/remote_pull/local/import/local_assets.service.dart";
import "package:photos/services/remote_pull/local/import/model.dart";
import "package:photos/utils/standalone/debouncer.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class LocalImportService {
  final _log = Logger("LocalSyncService");
  late SharedPreferences _prefs;
  Completer<void>? _existingSync;
  final DeviceAssetsService _deviceAssetsService = DeviceAssetsService();
  late Debouncer _changeCallbackDebouncer;
  final Lock _lock = Lock();

  static const lastLocalDBSyncTime = "localImport.lastSyncTime";
  static const kHasCompletedFirstImportKey = "has_completed_firstImport_x";

  LocalImportService._privateConstructor();

  static final LocalImportService instance =
      LocalImportService._privateConstructor();

  Future<void> init(SharedPreferences preferences) async {
    _prefs = preferences;
    if (!AppLifecycleService.instance.isForeground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    }
    if (permissionService.hasGrantedPermissions()) {
      _registerChangeCallback();
    } else {
      Bus.instance.on<PermissionGrantedEvent>().listen((event) async {
        _registerChangeCallback();
      });
    }
  }

  bool get _inForeground => AppLifecycleService.instance.isForeground;

  Future<void> importDiff() async {
    if (!permissionService.hasGrantedPermissions()) {
      _log.info("skip importDiff as permission is not granted");
      return;
    }
    if (Platform.isAndroid && _inForeground) {
      final permissionState =
          await permissionService.requestPhotoMangerPermissions();
      if (permissionState != PermissionState.authorized) {
        _log.warning("sync with invalid permission $permissionState");
        return;
      }
    }
    if (_existingSync != null) {
      _log.info("importDiff already in progress.");
      return _existingSync!.future;
    }
    _existingSync = Completer<void>();

    // We use a lock to prevent synchronisation to occur while it is downloading
    // as this introduces wrong entry in FilesDB due to race condition
    // This is a fix for https://github.com/ente-io/ente/issues/4296
    await _lock.synchronized(() async {
      final syncStartTime = DateTime.now();
      final lastSyncTimeInMs = _prefs.getInt(lastLocalDBSyncTime) ?? 0;
      if (lastSyncTimeInMs == 0) {
        Bus.instance
            .fire(SyncStatusUpdate(SyncStatus.startedFirstGalleryImport));
      }
      final Set<String> existingLocalFileIDs = await localDB.getAssetsIDs();
      _log.info("${existingLocalFileIDs.length} localIDs were discovered");
      final List<DevicePathAssets> result =
          await _deviceAssetsService.getLocalAssets(
        fromTimeInMs: lastSyncTimeInMs,
        toTimeInMs: syncStartTime.microsecondsSinceEpoch,
      );
      await _loadAndStoreDiff(existingLocalFileIDs, result);
      await _prefs.setInt(
        lastLocalDBSyncTime,
        syncStartTime.microsecondsSinceEpoch,
      );

      if (!hasCompletedFirstImport()) {
        await _prefs.setBool(kHasCompletedFirstImportKey, true);
        _log.fine("first gallery import finished");
        Bus.instance
            .fire(SyncStatusUpdate(SyncStatus.completedFirstGalleryImport));
      }
      _log.info(
        "Load took ${syncStartTime.difference(DateTime.now()).inMilliseconds} ms",
      );
    });

    _existingSync?.complete();
    _existingSync = null;
  }

  Future<bool> syncAll() async {
    if (!Configuration.instance.isLoggedIn()) {
      _log.warning("syncCall called when user is not logged in");
      return false;
    }
    final TimeLogger t = TimeLogger(context: "");
    final devicePathAssets = await _deviceAssetsService.getLocalAssets();
    _log.info("loaded devicePathAssets $t");
    final inAppAssetIds = await localDB.getAssetsIDs();
    final inAppPathToAssetIds = await localDB.pathToAssetIDs();
    final localDiffResult =
        await _deviceAssetsService.computeFullDiffWithOnDevice(
      devicePathAssets,
      inAppAssetIds,
      inAppPathToAssetIds,
    );
    final bool hasAnyMappingChanged = localDiffResult.isInOutOfSync;
    // if (localDiffResult.newPathToLocalIDs?.isNotEmpty ?? false) {
    //   await _db
    //       .insertPathIDToLocalIDMapping(localDiffResult.newPathToLocalIDs!);
    //   hasAnyMappingChanged = true;
    // }
    // if (localDiffResult.deletePathToLocalIDs?.isNotEmpty ?? false) {
    //   await _db
    //       .deletePathIDToLocalIDMapping(localDiffResult.deletePathToLocalIDs!);
    //   hasAnyMappingChanged = true;
    // }
    // final bool hasUnsyncedFiles =
    //     localDiffResult.uniqueLocalFiles?.isNotEmpty ?? false;
    // if (hasUnsyncedFiles) {
    //   await _db.insertMultiple(
    //     localDiffResult.uniqueLocalFiles!,
    //     conflictAlgorithm: SqliteAsyncConflictAlgorithm.ignore,
    //   );
    //   _log.info(
    //     "Inserted ${localDiffResult.uniqueLocalFiles?.length} "
    //     "un-synced files",
    //   );
    // }
    // debugPrint(
    //   "syncAll: mappingChange : $hasAnyMappingChanged, "
    //   "unSyncedFiles: $hasUnsyncedFiles",
    // );
    // if (hasAnyMappingChanged || hasUnsyncedFiles) {
    //   Bus.instance.fire(
    //     LocalPhotosUpdatedEvent(
    //       localDiffResult.uniqueLocalFiles ?? [],
    //       source: "syncAllChange",
    //     ),
    //   );
    // }

    return hasAnyMappingChanged;
  }

  Future<void> ignoreUpload(EnteFile file, InvalidFileError error) async {
    if (file.localID == null ||
        file.deviceFolder == null ||
        file.title == null) {
      _log.warning('Invalid file received for ignoring: $file');
      return;
    }
    if (Platform.isIOS && error.reason == InvalidReason.sourceFileMissing) {
      // ignoreSourceFileMissing error on iOS as the file fetch from iCloud might have failed,
      // but the file might be available later
      return;
    }
    final ignored = IgnoredFile(
      file.localID,
      file.title,
      file.deviceFolder,
      error.reason.name,
    );
    await IgnoredFilesService.instance.cacheAndInsert([ignored]);
  }

  Lock getLock() {
    return _lock;
  }

  bool hasCompletedFirstImport() {
    return _prefs.getBool(kHasCompletedFirstImportKey) ?? false;
  }

  Future<void> _loadAndStoreDiff(
    Set<String> existingLocalDs,
    List<DevicePathAssets> devicePathAssets,
  ) async {
    // // final List<EnteFile> files = result.item2;
    // if (files.isNotEmpty) {
    //   // Update the mapping for device path_id to local file id. Also, keep track
    //   // of newly discovered device paths
    //   // await FilesDB.instance.insertLocalAssets(
    //   //   result.item1,
    //   //   shouldAutoBackup:
    //   //       Configuration.instance.hasSelectedAllFoldersForBackup(),
    //   // );
    //
    //   _log.info(
    //     "Loaded ${files.length} photos from " +
    //         DateTime.fromMicrosecondsSinceEpoch(fromTime).toString() +
    //         " to " +
    //         DateTime.fromMicrosecondsSinceEpoch(toTime).toString(),
    //   );
    //   await _trackUpdatedFiles(files, existingLocalDs);
    //   // keep reference of all Files for firing LocalPhotosUpdatedEvent
    //   final List<EnteFile> allFiles = [];
    //   allFiles.addAll(files);
    //   // remove existing files and insert newly imported files in the table
    //   files.removeWhere((file) => existingLocalDs.contains(file.localID));
    //   await _db.insertMultiple(
    //     files,
    //     conflictAlgorithm: SqliteAsyncConflictAlgorithm.ignore,
    //   );
    //   _log.info('Inserted ${files.length} files');
    //   Bus.instance.fire(
    //     LocalPhotosUpdatedEvent(allFiles, source: "loadedPhoto"),
    //   );
    // }
    await _prefs.setInt(lastLocalDBSyncTime, toTime);
  }

  Future<void> _trackUpdatedFiles(
    List<EnteFile> files,
    Set<String> existingLocalFileIDs,
  ) async {
    final List<String> updatedLocalIDs = files
        .where(
          (file) =>
              file.localID != null &&
              existingLocalFileIDs.contains(file.localID),
        )
        .map((e) => e.localID!)
        .toList();
    if (updatedLocalIDs.isNotEmpty) {
      await FileUpdationDB.instance.insertMultiple(
        updatedLocalIDs,
        FileUpdationDB.modificationTimeUpdated,
      );
    }
  }

  void _registerChangeCallback() {
    _changeCallbackDebouncer = Debouncer(const Duration(milliseconds: 500));
    // In case of iOS limit permission, this call back is fired immediately
    // after file selection dialog is dismissed.
    PhotoManager.addChangeCallback((value) async {
      _log.info("Something changed on disk");
      _changeCallbackDebouncer.run(() async {
        unawaited(checkAndSync());
      });
    });
    PhotoManager.startChangeNotify();
  }

  Future<void> checkAndSync() async {
    if (_existingSync != null) {
      await _existingSync!.future;
    }
    if (permissionService.hasGrantedLimitedPermissions()) {
      unawaited(syncAll());
    } else {
      unawaited(importDiff());
    }
  }
}
