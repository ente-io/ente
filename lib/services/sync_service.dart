import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/first_import_succeeded_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/permission_granted_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/events/trigger_logout_event.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/diff_fetcher.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/utils/file_sync_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_util.dart';
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
  bool _syncStopRequested = false;
  bool _isBackground = false;
  Completer<bool> _existingSync;
  SharedPreferences _prefs;
  SyncStatusUpdate _lastSyncStatusEvent;
  int _completedUploads = 0;

  static const kDbUpdationTimeKey = "db_updation_time";
  static const kHasGrantedPermissionsKey = "has_granted_permissions";
  static const kLastBackgroundUploadDetectedTime =
      "last_background_upload_detected_time";
  static const kDiffLimit = 2500;
  static const kBackgroundUploadPollFrequency = Duration(seconds: 1);

  SyncService._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploader.clearQueue(SilentlyCancelUploadsError());
      sync();
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _logger.info("Connectivity change detected " + result.toString());
      if (Configuration.instance.hasConfiguredAccount() &&
          BillingService.instance.getSubscription() != null) {
        sync();
      }
    });

    Bus.instance.on<SyncStatusUpdate>().listen((event) {
      _logger.info("Sync status received " + event.toString());
      _lastSyncStatusEvent = event;
    });
  }

  static final SyncService instance = SyncService._privateConstructor();

  Future<void> init(bool isBackground) async {
    _isBackground = isBackground;
    _prefs = await SharedPreferences.getInstance();
    if (Platform.isIOS) {
      _logger.info("Clearing file cache");
      await PhotoManager.clearFileCache();
      _logger.info("Cleared file cache");
    }
  }

  Future<bool> existingSync() async {
    return _existingSync.future;
  }

  Future<bool> sync() async {
    _syncStopRequested = false;
    if (_existingSync != null) {
      _logger.warning("Sync already in progress, skipping.");
      return _existingSync.future;
    }
    _existingSync = Completer<bool>();
    bool successful = false;
    try {
      await _doSync();
      if (_lastSyncStatusEvent != null &&
          _lastSyncStatusEvent.status !=
              SyncStatus.completed_first_gallery_import &&
          _lastSyncStatusEvent.status != SyncStatus.completed_backup) {
        Bus.instance.fire(SyncStatusUpdate(SyncStatus.completed_backup));
      }
      successful = true;
    } on WiFiUnavailableError {
      _logger.warning("Not uploading over mobile data");
      Bus.instance.fire(
          SyncStatusUpdate(SyncStatus.paused, reason: "waiting for WiFi..."));
    } on SyncStopRequestedError {
      _syncStopRequested = false;
      Bus.instance.fire(
          SyncStatusUpdate(SyncStatus.completed_backup, wasStopped: true));
    } on NoActiveSubscriptionError {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.error,
          error: NoActiveSubscriptionError()));
    } on StorageLimitExceededError {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.error,
          error: StorageLimitExceededError()));
    } on UnauthorizedError {
      _logger.info("Logging user out");
      Bus.instance.fire(TriggerLogoutEvent());
    } catch (e, s) {
      if (e is DioError &&
          e.type == DioErrorType.DEFAULT &&
          e.error.osError != null) {
        final errorCode = e.error.osError?.errorCode;
        if (errorCode == 111 || errorCode == 101 || errorCode == 7) {
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.paused,
              reason: "waiting for network..."));
          return false;
        }
      } else {
        _logger.severe("backup failed", e, s);
        Bus.instance
            .fire(SyncStatusUpdate(SyncStatus.error, reason: "backup failed"));
        throw e;
      }
    } finally {
      _existingSync.complete(successful);
      _existingSync = null;
      _lastSyncStatusEvent = null;
      _logger.info("Syncing completed");
    }
    return successful;
  }

  void stopSync() {
    _logger.info("Sync stop requested");
    _syncStopRequested = true;
  }

  bool shouldStopSync() {
    return _syncStopRequested;
  }

  bool hasScannedDisk() {
    return _prefs.containsKey(kDbUpdationTimeKey);
  }

  bool isSyncInProgress() {
    return _existingSync != null;
  }

  SyncStatusUpdate getLastSyncStatusEvent() {
    return _lastSyncStatusEvent;
  }

  bool hasGrantedPermissions() {
    return _prefs.containsKey(kHasGrantedPermissionsKey) &&
        _prefs.getBool(kHasGrantedPermissionsKey);
  }

  Future<void> onPermissionGranted() async {
    await _prefs.setBool(kHasGrantedPermissionsKey, true);
    Bus.instance.fire(PermissionGrantedEvent());
    _doSync();
  }

  Future<void> onFoldersAdded(List<String> paths) async {
    if (_existingSync != null) {
      await _existingSync.future;
    }
    return sync();
  }

  void onFoldersRemoved(List<String> paths) {
    _uploader.removeFromQueueWhere((file) {
      return paths.contains(file.deviceFolder);
    }, UserCancelledUploadError());
  }

  Future<void> _doSync() async {
    await _syncWithDevice();
    await syncWithRemote();
  }

  Future<void> _syncWithDevice() async {
    if (!_prefs.containsKey(kHasGrantedPermissionsKey)) {
      _logger.info("Skipping local sync since permission has not been granted");
      return;
    }
    final existingLocalFileIDs = await _db.getExistingLocalFileIDs();
    final syncStartTime = DateTime.now().microsecondsSinceEpoch;
    if (_isBackground) {
      await PhotoManager.setIgnorePermissionCheck(true);
    } else {
      final result = await PhotoManager.requestPermission();
      if (!result) {
        _logger.severe("Did not get permission");
        await _prefs.setInt(kDbUpdationTimeKey, syncStartTime);
        Bus.instance.fire(LocalPhotosUpdatedEvent(List<File>.empty()));
        return await syncWithRemote();
      }
    }
    final lastDBUpdationTime = _prefs.getInt(kDbUpdationTimeKey) ?? 0;
    if (lastDBUpdationTime != 0) {
      await _loadAndStorePhotos(
          lastDBUpdationTime, syncStartTime, existingLocalFileIDs);
    } else {
      // Load from 0 - 01.01.2010
      Bus.instance
          .fire(SyncStatusUpdate(SyncStatus.started_first_gallery_import));
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
      Bus.instance
          .fire(SyncStatusUpdate(SyncStatus.completed_first_gallery_import));
    }
  }

  Future<void> _loadAndStorePhotos(
      int fromTime, int toTime, Set<String> existingLocalFileIDs) async {
    _logger.info("Loading photos from " +
        DateTime.fromMicrosecondsSinceEpoch(fromTime).toString() +
        " to " +
        DateTime.fromMicrosecondsSinceEpoch(toTime).toString());
    final files = await getDeviceFiles(fromTime, toTime);
    if (files.isNotEmpty) {
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
      final List<File> allFiles = [];
      allFiles.addAll(files);
      files.removeWhere((file) => existingLocalFileIDs.contains(file.localID));
      await _db.insertMultiple(files);
      _logger.info("Inserted " + files.length.toString() + " files.");
      Bus.instance.fire(LocalPhotosUpdatedEvent(allFiles));
    }
    bool isFirstImport = !_prefs.containsKey(kDbUpdationTimeKey);
    await _prefs.setInt(kDbUpdationTimeKey, toTime);
    if (isFirstImport) {
      Bus.instance.fire(FirstImportSucceededEvent());
    }
  }

  Future<void> syncWithRemote({bool silently = false}) async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      _logger.info("Skipping remote sync since account is not configured");
      return;
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
    bool hasUploadedFiles = await _uploadDiff();
    if (hasUploadedFiles) {
      syncWithRemote(silently: true);
    }
  }

  Future<void> _syncCollectionDiff(int collectionID) async {
    final diff = await _diffFetcher.getEncryptedFilesDiff(
      collectionID,
      _collectionsService.getCollectionSyncTime(collectionID),
      kDiffLimit,
    );
    if (diff.updatedFiles.isNotEmpty) {
      await _storeDiff(diff.updatedFiles, collectionID);
      _logger.info("Updated " +
          diff.updatedFiles.length.toString() +
          " files in collection " +
          collectionID.toString());
      Bus.instance.fire(LocalPhotosUpdatedEvent(diff.updatedFiles));
      Bus.instance
          .fire(CollectionUpdatedEvent(collectionID, diff.updatedFiles));
      if (diff.fetchCount == kDiffLimit) {
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
    var filesToBeUploaded =
        await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    if (kDebugMode) {
      filesToBeUploaded
          .removeWhere((element) => element.fileType == FileType.video);
    }
    _logger.info(
        filesToBeUploaded.length.toString() + " new files to be uploaded.");

    final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated();
    _logger.info(updatedFileIDs.length.toString() + " files updated.");

    _completedUploads = 0;
    int toBeUploaded = filesToBeUploaded.length + updatedFileIDs.length;

    if (toBeUploaded > 0) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.preparing_for_upload));
    }
    final alreadyUploaded = await FilesDB.instance.getNumberOfUploadedFiles();
    final futures = List<Future>();
    for (final uploadedFileID in updatedFileIDs) {
      final file = await _db.getUploadedFileInAnyCollection(uploadedFileID);
      final future = _uploader.upload(file, file.collectionID).then(
          (uploadedFile) async => await _onFileUploaded(
              uploadedFile, alreadyUploaded, toBeUploaded));
      futures.add(future);
    }

    for (final file in filesToBeUploaded) {
      final collectionID = (await CollectionsService.instance
              .getOrCreateForPath(file.deviceFolder))
          .id;
      final future = _uploader.upload(file, collectionID).then(
          (uploadedFile) async => await _onFileUploaded(
              uploadedFile, alreadyUploaded, toBeUploaded));
      futures.add(future);
    }
    try {
      await Future.wait(futures);
    } on InvalidFileError {
      // Do nothing
    } on FileSystemException {
      // Do nothing since it's caused mostly due to concurrency issues
      // when the foreground app deletes temporary files, interrupting a background
      // upload
    } on LockAlreadyAcquiredError {
      // Do nothing
    } on SilentlyCancelUploadsError {
      // Do nothing
    } on UserCancelledUploadError {
      // Do nothing
    } catch (e) {
      throw e;
    }
    return _completedUploads > 0;
  }

  Future<void> _onFileUploaded(
      File file, int alreadyUploaded, int toBeUploadedInThisSession) async {
    Bus.instance.fire(CollectionUpdatedEvent(file.collectionID, [file]));
    _completedUploads++;
    final completed =
        await FilesDB.instance.getNumberOfUploadedFiles() - alreadyUploaded;
    if (completed == toBeUploadedInThisSession) {
      return;
    }
    Bus.instance.fire(SyncStatusUpdate(SyncStatus.in_progress,
        completed: completed, total: toBeUploadedInThisSession));
  }

  Future _storeDiff(List<File> diff, int collectionID) async {
    List<File> toBeInserted = [];
    for (File file in diff) {
      final existingFiles = await _db.getMatchingFiles(
          file.title, file.deviceFolder, file.creationTime);
      if (existingFiles == null) {
        // File uploaded from a different device
        file.localID = null;
        toBeInserted.add(file);
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
          toBeInserted.add(file);
        } else {
          bool foundMatchingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID &&
                file.uploadedFileID == existingFile.uploadedFileID) {
              foundMatchingCollection = true;
              file.generatedID = existingFile.generatedID;
              toBeInserted.add(file);
              clearCache(file);
              break;
            }
          }
          if (!foundMatchingCollection) {
            // Added to a new collection
            toBeInserted.add(file);
          }
        }
      }
    }
    await _db.insertMultiple(toBeInserted);
    if (toBeInserted.length > 0) {
      await _collectionsService.setCollectionSyncTime(
          collectionID, toBeInserted[toBeInserted.length - 1].updationTime);
    }
  }

  Future<void> deleteFilesOnServer(List<int> fileIDs) async {
    return await _dio
        .post(Configuration.instance.getHttpEndpoint() + "/files/delete",
            options: Options(
              headers: {
                "X-Auth-Token": Configuration.instance.getToken(),
              },
            ),
            data: {
          "fileIDs": fileIDs,
        });
  }
}
