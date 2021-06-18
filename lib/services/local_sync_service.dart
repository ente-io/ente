import 'dart:async';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
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
  static const kEditedFileIDsKey = "edited_file_ids";
  static const kDownloadedFileIDsKey = "downloaded_file_ids";

  LocalSyncService._privateConstructor() {}

  static final LocalSyncService instance =
      LocalSyncService._privateConstructor();

  Future<void> init(bool isBackground) async {
    _isBackground = isBackground;
    _prefs = await SharedPreferences.getInstance();
    await _computer.turnOn(workersCount: 1);
  }

  Future<void> sync() async {
    if (!_prefs.containsKey(kHasGrantedPermissionsKey)) {
      _logger.info("Skipping local sync since permission has not been granted");
      return;
    }
    final existingLocalFileIDs = await _db.getExistingLocalFileIDs();
    final editedFileIDs = getEditedFiles().toSet();
    final downloadedFileIDs = getDownloadedFiles().toSet();
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    if (_isBackground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    } else {
      final result = await PhotoManager.requestPermission();
      if (!result) {
        _logger.severe("Did not get permission");
        await _prefs.setInt(kDbUpdationTimeKey, syncStartTime);
        Bus.instance.fire(LocalPhotosUpdatedEvent(List<File>.empty()));
        return;
      }
    }
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
    final unsyncedFiles =
        await getUnsyncedFiles(localAssets, existingIDs, _computer);
    await _db.insertMultiple(unsyncedFiles);
    _logger.info(
        "Inserted " + unsyncedFiles.length.toString() + " unsynced files.");
    Bus.instance.fire(LocalPhotosUpdatedEvent(unsyncedFiles));
    return true;
  }

  Future<void> trackEditedFile(File file) async {
    final editedIDs = getEditedFiles();
    editedIDs.add(file.localID);
    await _prefs.setStringList(kEditedFileIDsKey, editedIDs);
  }

  List<String> getEditedFiles() {
    if (_prefs.containsKey(kEditedFileIDsKey)) {
      return _prefs.getStringList(kEditedFileIDsKey);
    } else {
      List<String> editedIDs = [];
      return editedIDs;
    }
  }

  Future<void> trackDownloadedFile(File file) async {
    final downloadedIDs = getDownloadedFiles();
    downloadedIDs.add(file.localID);
    await _prefs.setStringList(kDownloadedFileIDsKey, downloadedIDs);
  }

  List<String> getDownloadedFiles() {
    if (_prefs.containsKey(kDownloadedFileIDsKey)) {
      return _prefs.getStringList(kDownloadedFileIDsKey);
    } else {
      List<String> downloadedIDs = [];
      return downloadedIDs;
    }
  }

  bool hasGrantedPermissions() {
    return _prefs.getBool(kHasGrantedPermissionsKey) ?? false;
  }

  Future<void> setPermissionGranted() async {
    await _prefs.setBool(kHasGrantedPermissionsKey, true);
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
      Bus.instance.fire(LocalPhotosUpdatedEvent(allFiles));
    }
    await _prefs.setInt(kDbUpdationTimeKey, toTime);
  }
}
