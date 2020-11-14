import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_downloader.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/utils/file_sync_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:photos/models/file.dart';

import 'package:photos/core/configuration.dart';

class SyncService {
  final _logger = Logger("SyncService");
  final _dio = Dio();
  final _db = FilesDB.instance;
  final _uploader = FileUploader.instance;
  final _collectionsService = CollectionsService.instance;
  final _downloader = DiffFetcher();
  bool _isSyncInProgress = false;
  bool _syncStopRequested = false;
  Future<void> _existingSync;
  SharedPreferences _prefs;

  static final _collectionSyncTimeKeyPrefix = "collection_sync_time_";
  static final _dbUpdationTimeKey = "db_updation_time";
  static final _diffLimit = 100;

  SyncService._privateConstructor() {
    Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      sync();
    });
  }

  static final SyncService instance = SyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> sync() async {
    _syncStopRequested = false;
    if (_isSyncInProgress) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync;
    }
    _isSyncInProgress = true;
    _existingSync = Future<void>(() async {
      _logger.info("Syncing...");
      try {
        await _doSync();
      } catch (e, s) {
        _logger.severe(e, s);
      } finally {
        _isSyncInProgress = false;
        Bus.instance.fire(SyncStatusUpdate(hasError: true));
      }
    });
    return _existingSync;
  }

  void stopSync() {
    _logger.info("Sync stop requested");
    _syncStopRequested = true;
  }

  bool shouldStopSync() {
    return _syncStopRequested;
  }

  bool hasScannedDisk() {
    return _prefs.containsKey(_dbUpdationTimeKey);
  }

  bool isSyncInProgress() {
    return _isSyncInProgress;
  }

  Future<void> _doSync() async {
    final result = await PhotoManager.requestPermission();
    if (!result) {
      _logger.severe("Did not get permission");
    }
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    final lastDBUpdationTime = _prefs.getInt(_dbUpdationTimeKey);
    if (lastDBUpdationTime != null && lastDBUpdationTime != 0) {
      await _loadAndStorePhotos(lastDBUpdationTime, syncStartTime);
    } else {
      // Load from 0 - 01.01.2010
      var startTime = 0;
      var toYear = 2010;
      var toTime = DateTime(toYear).microsecondsSinceEpoch;
      while (toTime < syncStartTime) {
        await _loadAndStorePhotos(startTime, toTime);
        startTime = toTime;
        toYear++;
        toTime = DateTime(toYear).microsecondsSinceEpoch;
      }
      await _loadAndStorePhotos(startTime, syncStartTime);
    }
    await syncWithRemote();
  }

  Future<void> _loadAndStorePhotos(int fromTime, int toTime) async {
    _logger.info("Loading photos from " +
        getMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(fromTime)) +
        " to " +
        getMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(toTime)));
    final files = await getDeviceFiles(fromTime, toTime);
    if (files.isNotEmpty) {
      _logger.info("Fetched " + files.length.toString() + " files.");
      await _db.insertMultiple(files);
      _logger.info("Inserted " + files.length.toString() + " files.");
      await _prefs.setInt(_dbUpdationTimeKey, toTime);
      await FileRepository.instance.reloadFiles();
    }
  }

  Future<void> syncWithRemote() async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      return Future.error("Account not configured yet");
    }
    await _collectionsService.sync();
    final collections = _collectionsService.getCollections();
    for (final collection in collections) {
      await _fetchEncryptedFilesDiff(collection.id);
    }
    await deleteFilesOnServer();
    await _uploadDiff();
  }

  Future<void> _fetchEncryptedFilesDiff(int collectionID) async {
    final diff = await _downloader.getEncryptedFilesDiff(
      collectionID,
      _getCollectionSyncTime(collectionID),
      _diffLimit,
    );
    if (diff.isNotEmpty) {
      await _storeDiff(diff, collectionID);
      FileRepository.instance.reloadFiles();
      Bus.instance.fire(CollectionUpdatedEvent(collectionID: collectionID));
      if (diff.length == _diffLimit) {
        return await _fetchEncryptedFilesDiff(collectionID);
      }
    }
  }

  int _getCollectionSyncTime(int collectionID) {
    var syncTime =
        _prefs.getInt(_collectionSyncTimeKeyPrefix + collectionID.toString());
    if (syncTime == null) {
      syncTime = 0;
    }
    return syncTime;
  }

  Future<void> _setCollectionSyncTime(int collectionID, int time) async {
    return _prefs.setInt(
        _collectionSyncTimeKeyPrefix + collectionID.toString(), time);
  }

  Future<void> _uploadDiff() async {
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    List<File> filesToBeUploaded =
        await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    if (kDebugMode) {
      filesToBeUploaded = filesToBeUploaded
          .where((element) => element.fileType != FileType.video)
          .toList();
    }
    final futures = List<Future>();
    for (int i = 0; i < filesToBeUploaded.length; i++) {
      if (_syncStopRequested) {
        _syncStopRequested = false;
        Bus.instance.fire(SyncStatusUpdate(wasStopped: true));
        return;
      }
      File file = filesToBeUploaded[i];
      try {
        final collectionID = (await CollectionsService.instance
                .getOrCreateForPath(file.deviceFolder))
            .id;
        final future = _uploader.upload(file, collectionID).then((value) {
          Bus.instance
              .fire(CollectionUpdatedEvent(collectionID: file.collectionID));
          Bus.instance.fire(SyncStatusUpdate(
              completed: i + 1, total: filesToBeUploaded.length));
        });
        futures.add(future);
      } catch (e, s) {
        Bus.instance.fire(SyncStatusUpdate(hasError: true));
        _logger.severe(e, s);
      }
    }
    try {
      await Future.wait(futures);
    } catch (e, s) {
      _isSyncInProgress = false;
      Bus.instance.fire(SyncStatusUpdate(hasError: true));
      _logger.severe("Error in syncing files", e, s);
    }
  }

  Future _storeDiff(List<File> diff, int collectionID) async {
    for (File file in diff) {
      final existingFiles = await _db.getMatchingFiles(file.title,
          file.deviceFolder, file.creationTime, file.modificationTime,
          alternateTitle: getHEICFileNameForJPG(file));
      if (existingFiles == null) {
        // File uploaded from a different device
        file.localID = null;
        await _db.insert(file);
      } else {
        // File exists on device
        file.localID = existingFiles[0]
            .localID; // File should ideally have the same localID
        bool wasUploadedOnAPreviousInstallation =
            existingFiles.length == 1 && existingFiles[0].collectionID == null;
        if (wasUploadedOnAPreviousInstallation) {
          file.generatedID = existingFiles[0].generatedID;
          await _db.update(file);
        } else {
          bool foundMatchingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID &&
                file.uploadedFileID == existingFile.uploadedFileID) {
              foundMatchingCollection = true;
              file.generatedID = existingFile.generatedID;
              await _db.update(file);
              break;
            }
          }
          if (!foundMatchingCollection) {
            // Added to a new collection
            await _db.insert(file);
          }
        }
      }
      await _setCollectionSyncTime(collectionID, file.updationTime);
    }
  }

  Future<void> deleteFilesOnServer() async {
    return _db.getDeletedFileIDs().then((ids) async {
      for (int id in ids) {
        await _deleteFileOnServer(id);
        await _db.delete(id);
      }
    });
  }

  Future<void> _deleteFileOnServer(int fileID) async {
    return _dio
        .delete(
          Configuration.instance.getHttpEndpoint() +
              "/files/" +
              fileID.toString(),
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .catchError((e) => _logger.severe(e));
  }
}
