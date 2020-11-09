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
    final futures = List<Future>();
    for (int i = 0; i < filesToBeUploaded.length; i++) {
      if (_syncStopRequested) {
        _syncStopRequested = false;
        Bus.instance.fire(PhotoUploadEvent(wasStopped: true));
        return;
      }
      File file = filesToBeUploaded[i];
      if (kDebugMode) {
        if (file.fileType == FileType.video) {
          continue;
        }
      }
      try {
        file.collectionID = (await CollectionsService.instance
                .getOrCreateForPath(file.deviceFolder))
            .id;
        final currentFile = await _db.getFile(file.generatedID);
        if (currentFile == null) {
          // File was deleted locally while being uploaded
          await _deleteFileOnServer(file.uploadedFileID);
          continue;
        }
        Future<void> future;
        if (currentFile.uploadedFileID != null) {
          // The file was uploaded outside this loop
          // Eg: Addition to an album or favorites
          future = CollectionsService.instance
              .addToCollection(file.collectionID, [currentFile]);
        } else {
          if (_uploader.getCurrentUploadStatus(file) != null) {
            // The file is currently being uploaded outside this loop
            // Eg: Addition to an album or favorites
            future = _uploader
                .getCurrentUploadStatus(file)
                .then((uploadedFile) async {
              await CollectionsService.instance
                  .addToCollection(file.collectionID, [uploadedFile]);
            });
          } else {
            future = _uploader.addToQueue(file).then((uploadedFile) async {
              await _db.update(uploadedFile);
            });
          }
        }
        futures.add(future.then((value) {
          Bus.instance
              .fire(CollectionUpdatedEvent(collectionID: file.collectionID));
          Bus.instance.fire(PhotoUploadEvent(
              completed: i + 1, total: filesToBeUploaded.length));
        }));
      } catch (e) {
        Bus.instance.fire(PhotoUploadEvent(hasError: true));
        throw e;
      }
    }
    await Future.wait(futures);
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
        bool wasUploadedOnAPreviousInstallation =
            existingFiles.length == 1 && existingFiles[0].collectionID == null;
        file.localID = existingFiles[0]
            .localID; // File should ideally have the same localID
        if (wasUploadedOnAPreviousInstallation) {
          file.generatedID = existingFiles[0].generatedID;
          await _db.update(file);
        } else {
          bool wasUpdatedInExistingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID) {
              file.generatedID = existingFile.generatedID;
              wasUpdatedInExistingCollection = true;
              break;
            }
          }
          if (wasUpdatedInExistingCollection) {
            await _db.update(file);
          } else {
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
