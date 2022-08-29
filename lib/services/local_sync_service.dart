import 'dart:async';
import 'dart:io';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/utils/file_sync_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSyncService {
  final _logger = Logger("LocalSyncService");
  final _db = FilesDB.instance;
  final Computer _computer = Computer();
  SharedPreferences _prefs;
  Completer<void> _existingSync;

  static const kDbUpdationTimeKey = "db_updation_time";
  static const kHasCompletedFirstImportKey = "has_completed_firstImport";
  static const kHasGrantedPermissionsKey = "has_granted_permissions";
  static const kPermissionStateKey = "permission_state";
  static const kEditedFileIDsKey = "edited_file_ids";
  static const kDownloadedFileIDsKey = "downloaded_file_ids";

  // Adding `_2` as a suffic to pull files that were earlier ignored due to permission errors
  // See https://github.com/CaiJingLong/flutter_photo_manager/issues/589
  static const kInvalidFileIDsKey = "invalid_file_ids_2";

  LocalSyncService._privateConstructor();

  static final LocalSyncService instance =
      LocalSyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!AppLifecycleService.instance.isForeground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    }
    await _computer.turnOn(workersCount: 1);
    if (hasGrantedPermissions()) {
      _registerChangeCallback();
    }
  }

  Future<void> sync() async {
    if (!_prefs.containsKey(kHasGrantedPermissionsKey)) {
      _logger.info("Skipping local sync since permission has not been granted");
      return;
    }
    if (Platform.isAndroid && AppLifecycleService.instance.isForeground) {
      final permissionState = await PhotoManager.requestPermissionExtend();
      if (permissionState != PermissionState.authorized) {
        _logger.severe(
          "sync requested with invalid permission",
          permissionState.toString(),
        );
        return;
      }
    }
    if (_existingSync != null) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync.future;
    }
    _existingSync = Completer<void>();
    final existingLocalFileIDs = await _db.getExistingLocalFileIDs();
    _logger.info(
      existingLocalFileIDs.length.toString() + " localIDs were discovered",
    );
    final editedFileIDs = getEditedFileIDs().toSet();
    final downloadedFileIDs = getDownloadedFileIDs().toSet();
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    final lastDBUpdationTime = _prefs.getInt(kDbUpdationTimeKey) ?? 0;
    final startTime = DateTime.now().microsecondsSinceEpoch;
    if (lastDBUpdationTime != 0) {
      await _loadAndStorePhotos(
        lastDBUpdationTime,
        syncStartTime,
        existingLocalFileIDs,
        editedFileIDs,
        downloadedFileIDs,
      );
    } else {
      // Load from 0 - 01.01.2010
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.startedFirstGalleryImport));
      var startTime = 0;
      var toYear = 2010;
      var toTime = DateTime(toYear).microsecondsSinceEpoch;
      while (toTime < syncStartTime) {
        await _loadAndStorePhotos(
          startTime,
          toTime,
          existingLocalFileIDs,
          editedFileIDs,
          downloadedFileIDs,
        );
        startTime = toTime;
        toYear++;
        toTime = DateTime(toYear).microsecondsSinceEpoch;
      }
      await _loadAndStorePhotos(
        startTime,
        syncStartTime,
        existingLocalFileIDs,
        editedFileIDs,
        downloadedFileIDs,
      );
    }
    if (!_prefs.containsKey(kHasCompletedFirstImportKey) ||
        !_prefs.getBool(kHasCompletedFirstImportKey)) {
      await _prefs.setBool(kHasCompletedFirstImportKey, true);
      _logger.fine("first gallery import finished");
      Bus.instance
          .fire(SyncStatusUpdate(SyncStatus.completedFirstGalleryImport));
    }
    final endTime = DateTime.now().microsecondsSinceEpoch;
    final duration = Duration(microseconds: endTime - startTime);
    _logger.info("Load took " + duration.inMilliseconds.toString() + "ms");
    _existingSync.complete();
    _existingSync = null;
  }

  Future<bool> syncAll() async {
    final sTime = DateTime.now().microsecondsSinceEpoch;
    final localAssets = await getAllLocalAssets();
    final eTime = DateTime.now().microsecondsSinceEpoch;
    final d = Duration(microseconds: eTime - sTime);
    _logger.info(
      "Loading from the beginning returned " +
          localAssets.length.toString() +
          " assets and took " +
          d.inMilliseconds.toString() +
          "ms",
    );
    final existingIDs = await _db.getExistingLocalFileIDs();
    final invalidIDs = getInvalidFileIDs().toSet();
    final unsyncedFiles =
        await getUnsyncedFiles(localAssets, existingIDs, invalidIDs, _computer);
    if (unsyncedFiles.isNotEmpty) {
      await _db.insertMultiple(unsyncedFiles);
      _logger.info(
        "Inserted " + unsyncedFiles.length.toString() + " unsynced files.",
      );
      _updatePathsToBackup(unsyncedFiles);
      Bus.instance.fire(LocalPhotosUpdatedEvent(unsyncedFiles));
      return true;
    }
    return false;
  }

  Future<void> trackEditedFile(File file) async {
    final editedIDs = getEditedFileIDs();
    editedIDs.add(file.localID);
    await _prefs.setStringList(kEditedFileIDsKey, editedIDs);
  }

  List<String> getEditedFileIDs() {
    if (_prefs.containsKey(kEditedFileIDsKey)) {
      return _prefs.getStringList(kEditedFileIDsKey);
    } else {
      final List<String> editedIDs = [];
      return editedIDs;
    }
  }

  Future<void> trackDownloadedFile(String localID) async {
    final downloadedIDs = getDownloadedFileIDs();
    downloadedIDs.add(localID);
    await _prefs.setStringList(kDownloadedFileIDsKey, downloadedIDs);
  }

  List<String> getDownloadedFileIDs() {
    if (_prefs.containsKey(kDownloadedFileIDsKey)) {
      return _prefs.getStringList(kDownloadedFileIDsKey);
    } else {
      final List<String> downloadedIDs = [];
      return downloadedIDs;
    }
  }

  Future<void> trackInvalidFile(File file) async {
    final invalidIDs = getInvalidFileIDs();
    invalidIDs.add(file.localID);
    await _prefs.setStringList(kInvalidFileIDsKey, invalidIDs);
  }

  List<String> getInvalidFileIDs() {
    if (_prefs.containsKey(kInvalidFileIDsKey)) {
      return _prefs.getStringList(kInvalidFileIDsKey);
    } else {
      final List<String> invalidIDs = [];
      return invalidIDs;
    }
  }

  bool hasGrantedPermissions() {
    return _prefs.getBool(kHasGrantedPermissionsKey) ?? false;
  }

  bool hasGrantedLimitedPermissions() {
    return _prefs.getString(kPermissionStateKey) ==
        PermissionState.limited.toString();
  }

  Future<void> onPermissionGranted(PermissionState state) async {
    await _prefs.setBool(kHasGrantedPermissionsKey, true);
    await _prefs.setString(kPermissionStateKey, state.toString());
    _registerChangeCallback();
  }

  bool hasCompletedFirstImport() {
    return _prefs.getBool(kHasCompletedFirstImportKey) ?? false;
  }

  Future<void> _loadAndStorePhotos(
    int fromTime,
    int toTime,
    Set<String> existingLocalFileIDs,
    Set<String> editedFileIDs,
    Set<String> downloadedFileIDs,
  ) async {
    _logger.info(
      "Loading photos from " +
          DateTime.fromMicrosecondsSinceEpoch(fromTime).toString() +
          " to " +
          DateTime.fromMicrosecondsSinceEpoch(toTime).toString(),
    );
    final files = await getDeviceFiles(fromTime, toTime, _computer);
    if (files.isNotEmpty) {
      _logger.info("Fetched " + files.length.toString() + " files.");
      final updatedFiles = files
          .where((file) => existingLocalFileIDs.contains(file.localID))
          .toList();
      updatedFiles.removeWhere((file) => editedFileIDs.contains(file.localID));
      updatedFiles
          .removeWhere((file) => downloadedFileIDs.contains(file.localID));
      if (updatedFiles.isNotEmpty) {
        _logger.info(
          updatedFiles.length.toString() + " local files were updated.",
        );
      }

      final List<String> updatedLocalIDs = [];
      for (final file in updatedFiles) {
        updatedLocalIDs.add(file.localID);
      }
      await FileUpdationDB.instance.insertMultiple(
        updatedLocalIDs,
        FileUpdationDB.modificationTimeUpdated,
      );
      final List<File> allFiles = [];
      allFiles.addAll(files);
      files.removeWhere((file) => existingLocalFileIDs.contains(file.localID));
      await _db.insertMultiple(files);
      _logger.info("Inserted " + files.length.toString() + " files.");
      _updatePathsToBackup(files);
      Bus.instance.fire(LocalPhotosUpdatedEvent(allFiles));
    }
    await _prefs.setInt(kDbUpdationTimeKey, toTime);
  }

  void _updatePathsToBackup(List<File> files) {
    if (Configuration.instance.hasSelectedAllFoldersForBackup()) {
      final pathsToBackup = Configuration.instance.getPathsToBackUp();
      final newFilePaths = files.map((file) => file.deviceFolder).toList();
      pathsToBackup.addAll(newFilePaths);
      Configuration.instance.setPathsToBackUp(pathsToBackup);
    }
  }

  void _registerChangeCallback() {
    // In case of iOS limit permission, this call back is fired immediately
    // after file selection dialog is dismissed.
    PhotoManager.addChangeCallback((value) async {
      _logger.info("Something changed on disk");
      if (_existingSync != null) {
        await _existingSync.future;
      }
      if (hasGrantedLimitedPermissions()) {
        syncAll();
      } else {
        sync();
      }
    });
    PhotoManager.startChangeNotify();
  }
}
