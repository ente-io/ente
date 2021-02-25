import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/thumbnail_cache_manager.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/diff_fetcher.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/utils/file_sync_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:photos/models/file.dart';

import 'package:photos/core/configuration.dart';

class SyncService {
  final _logger = Logger("SyncService");
  final _dio = Network.instance.getDio();
  final _db = FilesDB.instance;
  final _uploader = FileUploader.instance;
  final _collectionsService = CollectionsService.instance;
  final _diffFetcher = DiffFetcher();
  bool _isSyncInProgress = false;
  bool _syncStopRequested = false;
  Future<void> _existingSync;
  SharedPreferences _prefs;
  SyncStatusUpdate _lastSyncStatusEvent;

  static final _dbUpdationTimeKey = "db_updation_time";
  static final _diffLimit = 200;

  SyncService._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploader.clearQueue();
      sync();
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _logger.info("Connectivity change detected " + result.toString());
      if (Configuration.instance.hasConfiguredAccount() &&
          BillingService.instance.getSubscription() != null) {
        sync(isAppInBackground: true);
      }
    });

    Bus.instance.on<SyncStatusUpdate>().listen((event) {
      _lastSyncStatusEvent = event;
    });
  }

  static final SyncService instance = SyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (Platform.isIOS) {
      _logger.info("Clearing file cache");
      await PhotoManager.clearFileCache();
      _logger.info("Cleared file cache");
    }
  }

  Future<void> sync({bool isAppInBackground = false}) async {
    _syncStopRequested = false;
    if (_isSyncInProgress) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync;
    }
    _isSyncInProgress = true;
    _existingSync = Future<void>(() async {
      _logger.info("Syncing...");
      try {
        await _doSync(isAppInBackground: isAppInBackground);
        if (_lastSyncStatusEvent != null &&
            _lastSyncStatusEvent.status != SyncStatus.applying_local_diff) {
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completed));
        }
      } on WiFiUnavailableError {
        _logger.warning("Not uploading over mobile data");
        Bus.instance.fire(
            SyncStatusUpdate(SyncStatus.paused, reason: "Waiting for WiFi..."));
      } on SyncStopRequestedError {
        _syncStopRequested = false;
        Bus.instance
            .fire(SyncStatusUpdate(SyncStatus.completed, wasStopped: true));
      } on NoActiveSubscriptionError {
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.error,
            error: NoActiveSubscriptionError()));
      } on StorageLimitExceededError {
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.error,
            error: StorageLimitExceededError()));
      } catch (e, s) {
        _logger.severe(e, s);
        if (e is InvalidFileError) {
          // Do n0thing, encountered a corrupt file
        } else {
          Bus.instance.fire(
              SyncStatusUpdate(SyncStatus.error, reason: "backup failed"));
        }
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

  bool isSyncInProgress() {
    return _isSyncInProgress;
  }

  SyncStatusUpdate getLastSyncStatusEvent() {
    return _lastSyncStatusEvent;
  }

  Future<void> _doSync({bool isAppInBackground = false}) async {
    _logger.info("Doing sync", Error(), StackTrace.current);
    final existingLocalFileIDs = await _db.getExistingLocalFileIDs();
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    if (isAppInBackground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    } else {
      final result = await PhotoManager.requestPermission();
      if (!result) {
        _logger.severe("Did not get permission");
        await _prefs.setInt(_dbUpdationTimeKey, syncStartTime);
        await FileRepository.instance.reloadFiles();
        return await syncWithRemote();
      }
    }
    final lastDBUpdationTime = _prefs.getInt(_dbUpdationTimeKey) ?? 0;
    if (lastDBUpdationTime != 0) {
      await _loadAndStorePhotos(
          lastDBUpdationTime, syncStartTime, existingLocalFileIDs);
    } else {
      // Load from 0 - 01.01.2010
      var startTime = 0;
      var toYear = 2010;
      var toTime = DateTime(toYear).microsecondsSinceEpoch;
      while (toTime < syncStartTime) {
        await _loadAndStorePhotos(startTime, toTime, existingLocalFileIDs);
        startTime = toTime;
        toYear++;
        toTime = DateTime(toYear).microsecondsSinceEpoch;
      }
      await _loadAndStorePhotos(startTime, syncStartTime, existingLocalFileIDs);
    }
    await syncWithRemote();
  }

  Future<void> _loadAndStorePhotos(
      int fromTime, int toTime, Set<String> existingLocalFileIDs) async {
    _logger.info("Loading photos from " +
        DateTime.fromMicrosecondsSinceEpoch(fromTime).toString() +
        " to " +
        DateTime.fromMicrosecondsSinceEpoch(toTime).toString());
    final files = await getDeviceFiles(fromTime, toTime);
    if (files.isNotEmpty) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applying_local_diff));
      _logger.info("Fetched " + files.length.toString() + " files.");
      final updatedFiles =
          files.where((file) => existingLocalFileIDs.contains(file.localID));
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
      files.removeWhere((file) => existingLocalFileIDs.contains(file.localID));
      await _db.insertMultiple(files);
      _logger.info("Inserted " + files.length.toString() + " files.");
      await FileRepository.instance.reloadFiles();
    }
    await _prefs.setInt(_dbUpdationTimeKey, toTime);
  }

  Future<void> syncWithRemote({bool silently = false}) async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      return Future.error("Account not configured yet");
    }
    await _collectionsService.sync();
    final updatedCollections =
        await _collectionsService.getCollectionsToBeSynced();

    if (updatedCollections.isNotEmpty && !silently) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applying_remote_diff));
    }
    for (final c in updatedCollections) {
      await _syncCollectionDiff(c.id);
      _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
    await deleteFilesOnServer();
    bool hasUploadedFiles = await _uploadDiff();
    if (hasUploadedFiles) {
      syncWithRemote(silently: true);
    }
  }

  Future<void> _syncCollectionDiff(int collectionID) async {
    final diff = await _diffFetcher.getEncryptedFilesDiff(
      collectionID,
      _collectionsService.getCollectionSyncTime(collectionID),
      _diffLimit,
    );
    if (diff.updatedFiles.isNotEmpty) {
      await _storeDiff(diff.updatedFiles, collectionID);
      _logger.info("Updated " +
          diff.updatedFiles.length.toString() +
          " files in collection " +
          collectionID.toString());
      FileRepository.instance.reloadFiles();
      Bus.instance.fire(CollectionUpdatedEvent(collectionID: collectionID));
      if (diff.fetchCount == _diffLimit) {
        return await _syncCollectionDiff(collectionID);
      }
    }
  }

  Future<bool> _uploadDiff() async {
    if (!BillingService.instance.hasActiveSubscription()) {
      await BillingService.instance.fetchSubscription();
      if (!BillingService.instance.hasActiveSubscription()) {
        throw NoActiveSubscriptionError();
      }
    }
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    final filesToBeUploaded =
        await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    if (kDebugMode) {
      filesToBeUploaded
          .removeWhere((element) => element.fileType == FileType.video);
    }
    _logger.info(
        filesToBeUploaded.length.toString() + " new files to be uploaded.");

    final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated();
    _logger.info(updatedFileIDs.length.toString() + " files updated.");

    int uploadCounter = 0;
    final totalUploads = filesToBeUploaded.length + updatedFileIDs.length;

    if (totalUploads > 0) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.preparing_for_upload));
    }

    final futures = List<Future>();
    for (final uploadedFileID in updatedFileIDs) {
      final file = await _db.getUploadedFileInAnyCollection(uploadedFileID);
      final future = _uploader.upload(file, file.collectionID).then((value) {
        uploadCounter++;
        Bus.instance
            .fire(CollectionUpdatedEvent(collectionID: file.collectionID));
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.in_progress,
            completed: uploadCounter, total: totalUploads));
      });
      futures.add(future);
    }

    for (final file in filesToBeUploaded) {
      final collectionID = (await CollectionsService.instance
              .getOrCreateForPath(file.deviceFolder))
          .id;
      final future = _uploader.upload(file, collectionID).then((value) {
        uploadCounter++;
        Bus.instance
            .fire(CollectionUpdatedEvent(collectionID: file.collectionID));
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.in_progress,
            completed: uploadCounter, total: totalUploads));
      });
      futures.add(future);
    }
    try {
      await Future.wait(futures, eagerError: true);
    } on InvalidFileError {
      // Do nothing
    } catch (e, s) {
      _logger.severe("Error in syncing files", e, s);
      throw e;
    }
    return uploadCounter > 0;
  }

  Future _storeDiff(List<File> diff, int collectionID) async {
    for (File file in diff) {
      final existingFiles = await _db.getMatchingFiles(
          file.title, file.deviceFolder, file.creationTime);
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
          if (file.modificationTime != existingFiles[0].modificationTime) {
            // File was updated since the app was uninstalled
            _logger.info("Updated since last installation: " +
                file.uploadedFileID.toString());
            file.updationTime = null;
          }
          await _db.update(file);
        } else {
          bool foundMatchingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID &&
                file.uploadedFileID == existingFile.uploadedFileID) {
              foundMatchingCollection = true;
              file.generatedID = existingFile.generatedID;
              await _db.update(file);
              if (file.fileType == FileType.video) {
                VideoCacheManager().removeFile(file.getDownloadUrl());
              } else {
                DefaultCacheManager().removeFile(file.getDownloadUrl());
              }
              ThumbnailCacheManager().removeFile(file.getDownloadUrl());
              break;
            }
          }
          if (!foundMatchingCollection) {
            // Added to a new collection
            await _db.insert(file);
          }
        }
      }
      await _collectionsService.setCollectionSyncTime(
          collectionID, file.updationTime);
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
