import 'dart:async';
import 'dart:io';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_sync_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSyncService {
  final _logger = Logger("LocalSyncService");
  final _db = FilesDB.instance;
  final Computer _computer = Computer();
  bool _isBackground = false;
  SharedPreferences _prefs;

  static const kDbUpdationTimeKey = "db_updation_time";
  static const kHasCompletedFirstImportKey = "has_completed_firstImport";
  static const kHasGrantedPermissionsKey = "has_granted_permissions";
  static const kPermissionStateKey = "permission_state";
  static const kEditedFileIDsKey = "edited_file_ids";
  static const kDownloadedFileIDsKey = "downloaded_file_ids";
  static const kInvalidFileIDsKey = "invalid_file_ids";

  LocalSyncService._privateConstructor();

  static final LocalSyncService instance =
      LocalSyncService._privateConstructor();

  Future<void> init(bool isBackground) async {
    _isBackground = isBackground;
    _prefs = await SharedPreferences.getInstance();
    if (_isBackground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    }
    await _computer.turnOn(workersCount: 1);
  }

  void addChangeCallback(Function() callback) {
    PhotoManager.addChangeCallback((value) {
      _logger.info("Something changed on disk");
      callback();
    });
    PhotoManager.startChangeNotify();
  }

  Future<void> sync({bool isAppInBackground = false}) async {
    if (!_prefs.containsKey(kHasGrantedPermissionsKey)) {
      _logger.info("Skipping local sync since permission has not been granted");
      return;
    }

    if (Platform.isAndroid && !isAppInBackground) {
      var permissionState = await PhotoManager.requestPermissionExtend();
      if (permissionState != PermissionState.authorized) {
        _logger.severe(
            "sync requested with invalid permission", permissionState);
        return;
      }
    }
    final existingLocalFileIDs = await _db.getExistingLocalFileIDs();
    _logger.info(
        existingLocalFileIDs.length.toString() + " localIDs were discovered");
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
      Bus.instance
          .fire(SyncStatusUpdate(SyncStatus.started_first_gallery_import));
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
      Bus.instance
          .fire(SyncStatusUpdate(SyncStatus.completed_first_gallery_import));
    }
    final endTime = DateTime.now().microsecondsSinceEpoch;
    final duration = Duration(microseconds: endTime - startTime);
    _logger.info("Load took " + duration.inMilliseconds.toString() + "ms");
  }

  Future<bool> syncAll() async {
    final sTime = DateTime.now().microsecondsSinceEpoch;
    final localAssets = await getAllLocalAssets();
    final eTime = DateTime.now().microsecondsSinceEpoch;
    final d = Duration(microseconds: eTime - sTime);
    _logger.info("Loading from the beginning returned " +
        localAssets.length.toString() +
        " assets and took " +
        d.inMilliseconds.toString() +
        "ms");
    final existingIDs = await _db.getExistingLocalFileIDs();
    final invalidIDs = getInvalidFileIDs().toSet();
    final unsyncedFiles =
        await getUnsyncedFiles(localAssets, existingIDs, invalidIDs, _computer);
    if (unsyncedFiles.isNotEmpty) {
      await _db.insertMultiple(unsyncedFiles);
      _logger.info(
          "Inserted " + unsyncedFiles.length.toString() + " unsynced files.");
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
      List<String> editedIDs = [];
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
      List<String> downloadedIDs = [];
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
      List<String> invalidIDs = [];
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
    _logger.info("Loading photos from " +
        DateTime.fromMicrosecondsSinceEpoch(fromTime).toString() +
        " to " +
        DateTime.fromMicrosecondsSinceEpoch(toTime).toString());
    final files = await getDeviceFiles(fromTime, toTime, _computer);
    if (files.isNotEmpty) {
      _logger.info("Fetched " + files.length.toString() + " files.");
      final updatedFiles = files
          .where((file) => existingLocalFileIDs.contains(file.localID))
          .toList();
      updatedFiles.removeWhere((file) => editedFileIDs.contains(file.localID));
      updatedFiles
          .removeWhere((file) => downloadedFileIDs.contains(file.localID));
      _logger.info(updatedFiles.length.toString() + " files were updated.");
      for (final file in updatedFiles) {
        await _db.updateUploadedFile(
          file.localID,
          file.title,
          file.location,
          file.creationTime,
          file.modificationTime,
          null,
        );
      }
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
}
