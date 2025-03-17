import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/errors.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/events/permission_granted_event.dart";
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/extensions/stop_watch.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/ignored_file.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/remote_pull/local/import/device_assets.service.dart";
import "package:photos/services/remote_pull/local/import/model.dart";
import "package:photos/utils/standalone/debouncer.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class LocalImportService {
  final _log = Logger("LocalSyncService");
  late SharedPreferences _prefs;
  Completer<void>? _existingSync;
  Completer<bool>? _fullSync;
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

  Future<void> incrementalSync() async {
    if (!await _canSync("incrementalSync")) {
      return;
    }
    if (_existingSync != null) {
      _log.info("incrementalSync already in progress.");
      return _existingSync!.future;
    }
    _existingSync = Completer<void>();
    try {
      if (!_prefs.containsKey(lastLocalDBSyncTime)) {
        Bus.instance
            .fire(SyncStatusUpdate(SyncStatus.startedFirstGalleryImport));
      }

      // We use a lock to prevent synchronisation to occur while it is downloading
      // as this introduces wrong entry in FilesDB due to race condition
      // This is a fix for https://github.com/ente-io/ente/issues/4296
      await _lock.synchronized(() async {
        final TimeLogger tl = TimeLogger(context: "incrementalSync");
        final syncTime = DateTime.now().microsecondsSinceEpoch;
        final Set<String> inAppAssetIds = await localDB.getAssetsIDs();
        _log.info("${inAppAssetIds.length} assets in app $tl");
        final diff = await _deviceAssetsService.incrementalDiffWithOnDevice(
          inAppAssetIds,
          tl,
          fromTimeInMs: _prefs.getInt(lastLocalDBSyncTime) ?? 0,
          toTimeInMs: syncTime,
        );
        await _storeDiff(incrementalDiff: diff);
        await _prefs.setInt(lastLocalDBSyncTime, syncTime);
        if (!hasCompletedFirstImport()) {
          await _prefs.setBool(kHasCompletedFirstImportKey, true);
          _log.fine("initial incrementalSync completed $tl");
          Bus.instance
              .fire(SyncStatusUpdate(SyncStatus.completedFirstGalleryImport));
        } else {
          _log.info("incrementalSync completed $tl");
        }
      });
    } catch (e, st) {
      _log.severe("incrementalSync failed", e, st);
      rethrow;
    } finally {
      _existingSync?.complete();
      _existingSync = null;
    }
  }

  Future<bool> fullSync() async {
    if (!await _canSync("fullSync")) {
      return false;
    }
    if (_fullSync != null) {
      _log.info("fullSync already in progress.");
      return _fullSync!.future;
    }
    bool hasChanges = false;
    _fullSync = Completer<bool>();
    try {
      final TimeLogger tL = TimeLogger(context: "fullSync");
      final inAppAssetIds = await localDB.getAssetsIDs();
      final inAppPathToAssetIds = await localDB.pathToAssetIDs();
      _log.info("loaded inApp State $tL");
      final fullDiff = await _deviceAssetsService.fullDiffWithOnDevice(
        inAppAssetIds,
        inAppPathToAssetIds,
        tL,
      );
      if (fullDiff.isInOutOfSync) {
        _log.info("fullSyncDiff: ${fullDiff.countLog()} ${tL.elapsed}");
        await _storeDiff(fullDiff: fullDiff);
      }
      _log.fine(
        "${fullDiff.isInOutOfSync ? 'changed saved ${fullDiff.countLog()} $tL)' : 'no change'}, completeTime ${tL.elapsed}",
      );
      hasChanges = fullDiff.isInOutOfSync;
    } catch (e, s) {
      _log.severe("fullSync failed", e, s);
      rethrow;
    } finally {
      _fullSync?.complete(hasChanges);
      _fullSync = null;
    }
    return hasChanges;
  }

  Future<bool> _canSync(String tag) async {
    if (!permissionService.hasGrantedPermissions()) {
      _log.info("skip $tag sync  as permission is not granted");
      return false;
    }
    if (Platform.isAndroid && _inForeground) {
      final permissionState =
          await permissionService.requestPhotoMangerPermissions();
      if (permissionState != PermissionState.authorized) {
        _log.warning("skip $tag sync with invalid permission $permissionState");
        return false;
      }
    }
    return true;
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

  Future<void> _storeDiff({
    IncrementalDiffWithOnDevice? incrementalDiff,
    FullDiffWithOnDevice? fullDiff,
  }) async {
    if (incrementalDiff != null) {
      await localDB.insertAssets(incrementalDiff.assets);
      await localDB.insertDBPaths(incrementalDiff.addedOrModifiedPaths);
      await localDB
          .insertPathToAssetIDs(incrementalDiff.newOrUpdatedPathToLocalIDs);
    } else if (fullDiff != null) {
      await Future.wait([
        localDB.deleteAssets(fullDiff.extraAssetIDsInApp),
        localDB.deletePaths(fullDiff.extraPathIDsInApp),
      ]);
      await localDB.insertAssets(fullDiff.missingAssetsInApp);
      await localDB.insertPathToAssetIDs(
        fullDiff.updatePathToLocalIDs,
        clearOldMappingsIdsInInput: true,
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
    if (permissionService.hasGrantedLimitedPermissions()) {
      if (_fullSync != null) {
        await _fullSync!.future;
      }
      unawaited(fullSync());
    } else {
      if (_existingSync != null) {
        await _existingSync!.future;
      }
      unawaited(incrementalSync());
    }
  }
}
