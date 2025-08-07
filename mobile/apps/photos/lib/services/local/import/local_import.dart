import 'dart:async';
import 'dart:io';

import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/cache/lru_map.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/permission_granted_event.dart";
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/extensions/stop_watch.dart';
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/local/import/device_assets.service.dart";
import "package:photos/services/local/import/model.dart";
import "package:photos/services/local/local_assets_cache.dart";
import "package:photos/services/local/metadata/metadata.service.dart";
import "package:photos/utils/standalone/debouncer.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

// This map is used to track if a iOS origin file is being fetched for uploading
// or ML processing. In such cases, we want to ignore these files if they come in response
// from the local sync service. When a file is download
final LRUMap<String, bool> trackOriginFetchForUploadOrML = LRUMap(200);

class LocalImportService {
  final _log = Logger("LocalImportService");
  late SharedPreferences _prefs;
  Completer<void>? _existingSync;
  Completer<bool>? _fullSync;
  LocalAssetsCache? _localAssetsCache;
  final DeviceAssetsService _deviceAssetsService = DeviceAssetsService();
  late final Debouncer _changeCallbackDebouncer = Debouncer(
    const Duration(milliseconds: 1000),
    executionInterval: const Duration(milliseconds: 3000),
    leading: true,
  );
  final Lock _lock = Lock();

  static const lastLocalDBSyncTime = "localImport.lastSyncTime_2";
  static const kHasCompletedFirstImportKey = "has_completed_firstImport_2";

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
        final syncTime = DateTime.now().millisecondsSinceEpoch;
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
      await _lock.synchronized(() async {
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
      });
    } catch (e, s) {
      _log.severe("fullSync failed", e, s);
      rethrow;
    } finally {
      _fullSync?.complete(hasChanges);
      _fullSync = null;
    }
    return hasChanges;
  }

  bool _isMetaScanRunning = false;
  Future<void> metadataScan() async {
    if (_isMetaScanRunning) {
      _log.info("metadata scan already in progress");
      return;
    } else if (kDebugMode) {
      _log.info("metadata scan not implemented in kDebugMode yet");
      return;
    }

    _isMetaScanRunning = true;
    try {
      final Set<String> pendingScan =
          await localDB.getAssetsIDs(pendingScan: true);
      if (pendingScan.isEmpty) {
        _log.info("no pending scan");
        return;
      }
      _log.info("pending scan ${pendingScan.length}");
      for (final id in pendingScan) {
        final metadata = await LocalMetadataService.getMetadata(id);
        await localDB.updateMetadata(id, droid: metadata);
      }
    } catch (e, s) {
      _log.severe("metadata scan failed", e, s);
      rethrow;
    } finally {
      _isMetaScanRunning = false;
    }
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
    await _loadCache();
    return true;
  }

  Future<void> _loadCache() async {
    if (_localAssetsCache == null) {
      await _lock.synchronized(
        () async {
          if (_localAssetsCache == null) {
            _log.info("loading local assets cache");
            final List<AssetPathEntity> paths = await localDB.getAssetPaths();
            final List<EnteFile> assets = await localDB.getAssets();
            final Map<String, Set<String>> pathToAssetIDs =
                await localDB.pathToAssetIDs();
            _localAssetsCache = LocalAssetsCache(
              assetPaths: Map.fromEntries(paths.map((e) => MapEntry(e.id, e))),
              assets:
                  Map.fromEntries(assets.map((e) => MapEntry(e.localID!, e))),
              pathToAssetIDs: pathToAssetIDs,
              sortedAssets: assets,
            );
          }
        },
        timeout: const Duration(seconds: 10),
      );
    }
  }

  Future<LocalAssetsCache> getLocalAssetsCache() async {
    if (_localAssetsCache != null) {
      return _localAssetsCache!;
    }
    await _loadCache();
    return _localAssetsCache!;
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
    bool anythingChanged = fullDiff != null;
    if (incrementalDiff != null) {
      await localDB.insertAssets(incrementalDiff.assets);
      await localDB.insertDBPaths(incrementalDiff.addedOrModifiedPaths);
      await localDB
          .insertPathToAssetIDs(incrementalDiff.newOrUpdatedPathToLocalIDs);
      if (incrementalDiff.assets.isNotEmpty) {
        anythingChanged = true;
      }
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
    _localAssetsCache?.updateForDiff(
      incrementalDiff: incrementalDiff,
      fullDiff: fullDiff,
    );
    if (anythingChanged) {
      Bus.instance.fire(LocalPhotosUpdatedEvent([], source: "localImport"));
    }
  }

  void _registerChangeCallback() {
    // In case of iOS limit permission, this call back is fired immediately
    // after file selection dialog is dismissed.
    PhotoManager.addChangeCallback((value) async {
      _log.info("Something changed on disk");
      _changeCallbackDebouncer.run(() async {
        _log.info("sync assets due to change on disk");
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
