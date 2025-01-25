import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import "package:photos/events/diff_sync_complete_event.dart";
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/device_collection.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/upload_strategy.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/local_file_update_service.dart';
import "package:photos/services/notification_service.dart";
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/diff_fetcher.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSyncService {
  final _logger = Logger("RemoteSyncService");
  final _db = FilesDB.instance;
  final FileUploader _uploader = FileUploader.instance;
  final Configuration _config = Configuration.instance;
  final CollectionsService _collectionsService = CollectionsService.instance;
  final DiffFetcher _diffFetcher = DiffFetcher();
  final LocalFileUpdateService _localFileUpdateService =
      LocalFileUpdateService.instance;
  int _completedUploads = 0;
  int _ignoredUploads = 0;
  late SharedPreferences _prefs;
  Completer<void>? _existingSync;
  bool _isExistingSyncSilent = false;

  static const kHasSyncedArchiveKey = "has_synced_archive";
  /* This setting is used to maintain a list of local IDs for videos that the user has manually
 marked for upload, even if the global video upload setting is currently disabled.
 When the global video upload setting is disabled, we typically ignore all video uploads. However, for videos that have been added to this list, we
 want to still allow them to be uploaded, despite the global setting being disabled.

 This allows users to queue up videos for upload, and have them successfully upload
 even if they later toggle the global video upload setting to disabled.
   */
  static const _ignoreBackUpSettingsForIDs_ = "ignoreBackUpSettingsForIDs";
  final String _isFirstRemoteSyncDone = "isFirstRemoteSyncDone";

  // 28 Sept, 2021 9:03:20 AM IST
  static const kArchiveFeatureReleaseTime = 1632800000000000;
  static const kHasSyncedEditTime = "has_synced_edit_time";

  // 29 October, 2021 3:56:40 AM IST
  static const kEditTimeFeatureReleaseTime = 1635460000000000;

  static const kMaximumPermissibleUploadsInThrottledMode = 4;

  static final RemoteSyncService instance =
      RemoteSyncService._privateConstructor();

  RemoteSyncService._privateConstructor();

  void init(SharedPreferences preferences) {
    _prefs = preferences;

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) async {
      if (event.type == EventType.addedOrUpdated) {
        if (_existingSync == null) {
          // ignore: unawaited_futures
          sync();
        }
      }
    });
  }

  Future<void> sync({bool silently = false}) async {
    if (!_config.hasConfiguredAccount()) {
      _logger.info("Skipping remote sync since account is not configured");
      return;
    }
    if (_existingSync != null) {
      _logger.info("Remote sync already in progress, skipping");
      // if current sync is silent but request sync is non-silent (demands UI
      // updates), update the syncSilently flag
      if (_isExistingSyncSilent && !silently) {
        _isExistingSyncSilent = false;
      }
      return _existingSync?.future;
    }
    _existingSync = Completer<void>();
    _isExistingSyncSilent = silently;
    _logger.info(
      "Starting remote sync " +
          (silently ? "silently" : " with status updates"),
    );

    try {
      // use flag to decide if we should start marking files for upload before
      // remote-sync is done. This is done to avoid adding existing files to
      // the same or different collection when user had already uploaded them
      // before.
      final bool hasSyncedBefore = _prefs.containsKey(_isFirstRemoteSyncDone);
      if (hasSyncedBefore) {
        await syncDeviceCollectionFilesForUpload();
      }
      await _pullDiff();
      await trashSyncService.syncTrash();
      if (!hasSyncedBefore) {
        await _prefs.setBool(_isFirstRemoteSyncDone, true);
        await syncDeviceCollectionFilesForUpload();
      }
      final filesToBeUploaded = await _getFilesToBeUploaded();
      final hasUploadedFiles = await _uploadFiles(filesToBeUploaded);
      if (filesToBeUploaded.isNotEmpty) {
        _logger.info(
            "Files ${filesToBeUploaded.length} queued for upload, completed: "
            "$_completedUploads, ignored $_ignoredUploads");
      } else {
        _logger.info("No files to upload for this session");
      }
      if (hasUploadedFiles) {
        await _pullDiff();
        _existingSync?.complete();
        _existingSync = null;
        await syncDeviceCollectionFilesForUpload();
        final hasMoreFilesToBackup = (await _getFilesToBeUploaded()).isNotEmpty;
        _logger.info("hasMoreFilesToBackup?" + hasMoreFilesToBackup.toString());
        if (hasMoreFilesToBackup && !_shouldThrottleSync()) {
          // Skipping a resync to ensure that files that were ignored in this
          // session are not processed now
          // ignore: unawaited_futures
          sync();
        } else {
          _logger.info("Fire backup completed event");
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
        }
      } else {
        // if filesToBeUploaded is empty, clear any stale files in the temp
        // directory
        if (filesToBeUploaded.isEmpty) {
          await _uploader.removeStaleFiles();
        }
        if (_ignoredUploads > 0) {
          _logger.info("Ignored $_ignoredUploads files for upload, fire "
              "backup done");
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
        }
        _existingSync?.complete();
        _existingSync = null;
      }
    } catch (e, s) {
      _existingSync?.complete();
      _existingSync = null;
      // rethrow whitelisted error so that UI status can be updated correctly.
      if (e is UnauthorizedError ||
          e is NoActiveSubscriptionError ||
          e is WiFiUnavailableError ||
          e is StorageLimitExceededError ||
          e is SyncStopRequestedError ||
          e is NoMediaLocationAccessError) {
        _logger.warning("Error executing remote sync", e, s);
        rethrow;
      } else {
        _logger.severe("Error executing remote sync ", e, s);
        if (flagService.internalUser) {
          rethrow;
        }
      }
    } finally {
      _isExistingSyncSilent = false;
    }
  }

  bool isFirstRemoteSyncDone() {
    return _prefs.containsKey(_isFirstRemoteSyncDone);
  }

  Future<bool> whiteListVideoForUpload(EnteFile file) async {
    if (file.fileType == FileType.video &&
        !_config.shouldBackupVideos() &&
        file.localID != null) {
      final List<String> whitelistedIDs =
          _prefs.getStringList(_ignoreBackUpSettingsForIDs_) ?? <String>[];
      whitelistedIDs.add(file.localID!);
      return _prefs.setStringList(_ignoreBackUpSettingsForIDs_, whitelistedIDs);
    }
    return false;
  }

  Future<void> _pullDiff() async {
    _logger.info("Pulling remote diff");
    final isFirstSync = !_collectionsService.hasSyncedCollections();
    if (isFirstSync && !_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    await _collectionsService.sync();
    // check and reset user's collection syncTime in past for older clients
    if (isFirstSync) {
      // not need reset syncTime, mark all flags as done if firstSync
      await _markResetSyncTimeAsDone();
    } else if (_shouldResetSyncTime()) {
      _logger.warning('Resetting syncTime for for the client');
      await _resetAllCollectionsSyncTime();
      await _markResetSyncTimeAsDone();
    }

    final idsToRemoteUpdationTimeMap =
        await _collectionsService.getCollectionIDsToBeSynced();
    await _syncUpdatedCollections(idsToRemoteUpdationTimeMap);
    unawaited(_localFileUpdateService.markUpdatedFilesForReUpload());
    unawaited(_notifyNewFiles(idsToRemoteUpdationTimeMap.keys.toList()));
  }

  Future<void> _syncUpdatedCollections(
    final Map<int, int> idsToRemoteUpdationTimeMap,
  ) async {
    for (final cid in idsToRemoteUpdationTimeMap.keys) {
      await _syncCollectionDiff(
        cid,
        _collectionsService.getCollectionSyncTime(cid),
      );
      // update syncTime for the collection in sharedPrefs. Note: the
      // syncTime can change on remote but we might not get a diff for the
      // collection if there are not changes in the file, but the collection
      // metadata (name, archive status, sharing etc) has changed.
      final remoteUpdateTime = idsToRemoteUpdationTimeMap[cid];
      await _collectionsService.setCollectionSyncTime(cid, remoteUpdateTime);
    }
    _logger.info("All updated collections synced");
    Bus.instance.fire(DiffSyncCompleteEvent());
  }

  Future<void> _resetAllCollectionsSyncTime() async {
    final resetSyncTime = _getSinceTimeForReSync();
    _logger.info('re-setting all collections syncTime to: $resetSyncTime');
    final collections = _collectionsService.getActiveCollections();
    for (final c in collections) {
      final int newSyncTime =
          min(_collectionsService.getCollectionSyncTime(c.id), resetSyncTime);
      await _collectionsService.setCollectionSyncTime(c.id, newSyncTime);
    }
  }

  Future<void> _syncCollectionDiff(int collectionID, int sinceTime) async {
    _logger.info(
      "[Collection-$collectionID] fetch diff silently: $_isExistingSyncSilent "
      "since: $sinceTime",
    );
    if (!_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    final diff =
        await _diffFetcher.getEncryptedFilesDiff(collectionID, sinceTime);
    if (diff.deletedFiles.isNotEmpty) {
      await _syncCollectionDiffDelete(diff, collectionID);
    }
    if (diff.updatedFiles.isNotEmpty) {
      await _storeDiff(diff.updatedFiles, collectionID);
      _logger.info(
        "[Collection-$collectionID] Updated ${diff.updatedFiles.length} files"
        " from remote",
      );
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          diff.updatedFiles,
          source: "syncUpdateFromRemote",
        ),
      );
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collectionID,
          diff.updatedFiles,
          "syncUpdateFromRemote",
        ),
      );
    }

    if (diff.latestUpdatedAtTime > 0) {
      await _collectionsService.setCollectionSyncTime(
        collectionID,
        diff.latestUpdatedAtTime,
      );
    }
    if (diff.hasMore) {
      return await _syncCollectionDiff(
        collectionID,
        _collectionsService.getCollectionSyncTime(collectionID),
      );
    }
    _logger.info("[Collection-$collectionID] synced");
  }

  Future<void> joinAndSyncCollection(
    BuildContext context,
    int collectionID,
  
  ) async {
    await _collectionsService.joinPublicCollection(context, collectionID);
    await _collectionsService.sync();
    await _syncCollectionDiff(collectionID, 0);
  }

  Future<void> _syncCollectionDiffDelete(Diff diff, int collectionID) async {
    final fileIDs = diff.deletedFiles.map((f) => f.uploadedFileID!).toList();
    final localDeleteCount =
        await _db.deleteFilesFromCollection(collectionID, fileIDs);
    if (localDeleteCount > 0) {
      final collectionFiles =
          (await _db.getFileIDToFileFromIDs(fileIDs)).values.toList();
      collectionFiles.removeWhere((f) => f.collectionID != collectionID);
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collectionID,
          collectionFiles,
          "syncDeleteFromRemote",
          type: EventType.deletedFromRemote,
        ),
      );
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          collectionFiles,
          type: EventType.deletedFromRemote,
          source: "syncDeleteFromRemote",
        ),
      );
    }
  }

  Future<void> syncDeviceCollectionFilesForUpload() async {
    _logger.info("Syncing device collections to be uploaded");
    final int ownerID = _config.getUserID()!;

    final deviceCollections = await _db.getDeviceCollections();
    deviceCollections.removeWhere((element) => !element.shouldBackup);
    // Sort by count to ensure that photos in iOS are first inserted in
    // smallest album marked for backup. This is to ensure that photo is
    // first attempted to upload in a non-recent album.
    deviceCollections.sort((a, b) => a.count.compareTo(b.count));
    final Map<String, Set<String>> pathIdToLocalIDs =
        await _db.getDevicePathIDToLocalIDMap();
    bool moreFilesMarkedForBackup = false;
    for (final deviceCollection in deviceCollections) {
      final Set<String> localIDsToSync =
          pathIdToLocalIDs[deviceCollection.id] ?? {};
      if (deviceCollection.uploadStrategy == UploadStrategy.ifMissing) {
        final Set<String> alreadyClaimedLocalIDs =
            await _db.getLocalIDsMarkedForOrAlreadyUploaded(ownerID);
        localIDsToSync.removeAll(alreadyClaimedLocalIDs);
      }

      if (localIDsToSync.isEmpty) {
        continue;
      }
      final collectionID = await _getCollectionID(deviceCollection);
      if (collectionID == null) {
        _logger.warning('DeviceCollection was either deleted or missing');
        continue;
      }

      moreFilesMarkedForBackup = true;
      await _db.setCollectionIDForUnMappedLocalFiles(
        collectionID,
        localIDsToSync,
      );

      // mark IDs as already synced if corresponding entry is present in
      // the collection. This can happen when a user has marked a folder
      // for sync, then un-synced it and again tries to mark if for sync.
      final Set<String> existingMapping =
          await _db.getLocalFileIDsForCollection(collectionID);
      final Set<String> commonElements =
          localIDsToSync.intersection(existingMapping);
      if (commonElements.isNotEmpty) {
        debugPrint(
          "${commonElements.length} files already existing in "
          "collection $collectionID for ${deviceCollection.name}",
        );
        localIDsToSync.removeAll(commonElements);
      }

      // At this point, the remaining localIDsToSync will need to create
      // new file entries, where we can store mapping for localID and
      // corresponding collection ID
      if (localIDsToSync.isNotEmpty) {
        debugPrint(
          'Adding new entries for ${localIDsToSync.length} files'
          ' for ${deviceCollection.name}',
        );
        final filesWithCollectionID =
            await _db.getLocalFiles(localIDsToSync.toList());
        final List<EnteFile> newFilesToInsert = [];
        final Set<String> fileFoundForLocalIDs = {};
        for (var existingFile in filesWithCollectionID) {
          final String localID = existingFile.localID!;
          if (!fileFoundForLocalIDs.contains(localID)) {
            existingFile.generatedID = null;
            existingFile.collectionID = collectionID;
            existingFile.uploadedFileID = null;
            existingFile.ownerID = null;
            newFilesToInsert.add(existingFile);
            fileFoundForLocalIDs.add(localID);
          }
        }
        await _db.insertMultiple(newFilesToInsert);
        if (fileFoundForLocalIDs.length != localIDsToSync.length) {
          _logger.warning(
            "mismatch in num of filesToSync ${localIDsToSync.length} to "
            "fileSynced ${fileFoundForLocalIDs.length}",
          );
        }
      }
    }
    if (moreFilesMarkedForBackup && !_config.hasSelectedAllFoldersForBackup()) {
      // "force reload due to display new files"
      Bus.instance.fire(ForceReloadHomeGalleryEvent("newFilesDisplay"));
    }
  }

  Future<void> updateDeviceFolderSyncStatus(
    Map<String, bool> syncStatusUpdate,
  ) async {
    final Set<int> oldCollectionIDsForAutoSync =
        await _db.getDeviceSyncCollectionIDs();
    await _db.updateDevicePathSyncStatus(syncStatusUpdate);
    final Set<int> newCollectionIDsForAutoSync =
        await _db.getDeviceSyncCollectionIDs();
    SyncService.instance.onDeviceCollectionSet(newCollectionIDsForAutoSync);
    // remove all collectionIDs which are still marked for backup
    oldCollectionIDsForAutoSync.removeAll(newCollectionIDsForAutoSync);
    await removeFilesQueuedForUpload(oldCollectionIDsForAutoSync.toList());
    if (syncStatusUpdate.values.any((syncStatus) => syncStatus == false)) {
      Configuration.instance.setSelectAllFoldersForBackup(false).ignore();
    }
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(<EnteFile>[], source: "deviceFolderSync"),
    );
    Bus.instance.fire(BackupFoldersUpdatedEvent());
  }

  Future<void> removeFilesQueuedForUpload(List<int> collectionIDs) async {
    /*
      For each collection, perform following action
      1) Get List of all files not uploaded yet
      2) Delete files who localIDs is also present in other collections.
      3) For Remaining files, set the collectionID as -1
     */
    _logger.info("Removing files for collections $collectionIDs");
    for (int collectionID in collectionIDs) {
      final List<EnteFile> pendingUploads =
          await _db.getPendingUploadForCollection(collectionID);
      if (pendingUploads.isEmpty) {
        continue;
      } else {
        _logger.info(
          "RemovingFiles $collectionIDs: pendingUploads "
          "${pendingUploads.length}",
        );
      }
      final Set<String> localIDsInOtherFileEntries =
          await _db.getLocalIDsPresentInEntries(
        pendingUploads,
        collectionID,
      );
      _logger.info(
        "RemovingFiles $collectionIDs: filesInOtherCollection "
        "${localIDsInOtherFileEntries.length}",
      );
      final List<EnteFile> entriesToUpdate = [];
      final List<int> entriesToDelete = [];
      for (EnteFile pendingUpload in pendingUploads) {
        if (localIDsInOtherFileEntries.contains(pendingUpload.localID)) {
          entriesToDelete.add(pendingUpload.generatedID!);
        } else {
          pendingUpload.collectionID = null;
          entriesToUpdate.add(pendingUpload);
        }
      }
      await _db.deleteMultipleByGeneratedIDs(entriesToDelete);
      await _db.insertMultiple(entriesToUpdate);
      _logger.info(
        "RemovingFiles $collectionIDs: deleted "
        "${entriesToDelete.length} and updated ${entriesToUpdate.length}",
      );
    }
  }

  Future<int?> _getCollectionID(DeviceCollection deviceCollection) async {
    if (deviceCollection.hasCollectionID()) {
      final collection =
          _collectionsService.getCollectionByID(deviceCollection.collectionID!);
      if (collection != null && !collection.isDeleted) {
        return collection.id;
      }
      if (collection == null) {
        // ideally, this should never happen because the app keeps a track of
        // all collections and their IDs. But, if somehow the collection is
        // deleted, we should fetch it again
        _logger.severe(
          "Collection ${deviceCollection.collectionID} missing "
          "for pathID ${deviceCollection.id}",
        );
        _collectionsService
            .fetchCollectionByID(deviceCollection.collectionID!)
            .ignore();
        // return, by next run collection should be available.
        // we are not waiting on fetch by choice because device might have wrong
        // mapping which will result in breaking upload for other device path
        return null;
      } else if (collection.isDeleted) {
        _logger.warning("Collection ${deviceCollection.collectionID} deleted "
            "for pathID ${deviceCollection.id}, new collection will be created");
      }
    }
    final collection =
        await _collectionsService.getOrCreateForPath(deviceCollection.name);
    await _db.updateDeviceCollection(deviceCollection.id, collection.id);
    return collection.id;
  }

  Future<List<EnteFile>> _getFilesToBeUploaded() async {
    final List<EnteFile> originalFiles = await _db.getFilesPendingForUpload();
    if (originalFiles.isEmpty) {
      return originalFiles;
    }
    final bool shouldRemoveVideos =
        !_config.shouldBackupVideos() || _shouldThrottleSync();
    final ignoredIDs = await IgnoredFilesService.instance.idToIgnoreReasonMap;
    bool shouldSkipUploadFunc(EnteFile file) {
      return IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, file);
    }

    final List<EnteFile> filesToBeUploaded = [];
    int ignoredForUpload = 0;
    int skippedVideos = 0;
    final whitelistedIDs =
        (_prefs.getStringList(_ignoreBackUpSettingsForIDs_) ?? <String>[])
            .toSet();
    for (var file in originalFiles) {
      if (shouldRemoveVideos &&
          (file.fileType == FileType.video &&
              !whitelistedIDs.contains(file.localID))) {
        skippedVideos++;
        continue;
      }
      if (shouldSkipUploadFunc(file)) {
        ignoredForUpload++;
        continue;
      }
      filesToBeUploaded.add(file);
    }
    if (skippedVideos > 0 || ignoredForUpload > 0) {
      _logger.info("Skipped $skippedVideos videos and $ignoredForUpload "
          "ignored files for upload");
    }
    _sortByTimeAndType(filesToBeUploaded);
    _logger.info("${filesToBeUploaded.length} new files to be uploaded.");
    return filesToBeUploaded;
  }

  Future<bool> _uploadFiles(List<EnteFile> filesToBeUploaded) async {
    final int ownerID = _config.getUserID()!;
    final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated(ownerID);
    if (updatedFileIDs.isNotEmpty) {
      _logger.info("Identified ${updatedFileIDs.length} files for reupload");
    }

    _completedUploads = 0;
    _ignoredUploads = 0;
    final int toBeUploaded = filesToBeUploaded.length + updatedFileIDs.length;
    if (toBeUploaded > 0) {
      Bus.instance.fire(
        SyncStatusUpdate(SyncStatus.preparingForUpload, total: toBeUploaded),
      );
      await _uploader.verifyMediaLocationAccess();
      await _uploader.checkNetworkForUpload();
      // verify if files upload is allowed based on their subscription plan and
      // storage limit. To avoid creating new endpoint, we are using
      // fetchUploadUrls as alternative method.
      await _uploader.fetchUploadURLs(toBeUploaded);
    }
    final List<Future> futures = [];
    for (final uploadedFileID in updatedFileIDs) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger
            .info("Skipping some updated files as we are throttling uploads");
        break;
      }
      final allFiles = await _db.getFilesInAllCollection(
        uploadedFileID,
        ownerID,
      );
      if (allFiles.isEmpty) {
        _logger.warning("No files found for uploadedFileID $uploadedFileID");
        continue;
      }
      EnteFile? fileInCollectionOwnedByUser;
      for (final file in allFiles) {
        if (file.canReUpload(ownerID)) {
          fileInCollectionOwnedByUser = file;
          break;
        }
      }
      if (fileInCollectionOwnedByUser != null) {
        _uploadFile(
          fileInCollectionOwnedByUser,
          fileInCollectionOwnedByUser.collectionID!,
          futures,
        );
      }
    }

    for (final file in filesToBeUploaded) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger.info("Skipping some new files as we are throttling uploads");
        break;
      }
      // prefer existing collection ID for manually uploaded files.
      // See https://github.com/ente-io/photos-app/pull/187
      final collectionID = file.collectionID ??
          (await _collectionsService
                  .getOrCreateForPath(file.deviceFolder ?? 'Unknown Folder'))
              .id;
      _uploadFile(file, collectionID, futures);
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
      rethrow;
    }
    return _completedUploads > 0;
  }

  void _uploadFile(EnteFile file, int collectionID, List<Future> futures) {
    final future = _uploader
        .upload(file, collectionID)
        .then((uploadedFile) => _onFileUploaded(uploadedFile))
        .onError(
          (error, stackTrace) => _onFileUploadError(error, stackTrace, file),
        );
    futures.add(future);
  }

  Future<void> _onFileUploaded(EnteFile file) async {
    Bus.instance.fire(
      CollectionUpdatedEvent(file.collectionID, [file], "fileUpload"),
    );
    _completedUploads++;
    final toBeUploadedInThisSession = _uploader.getCurrentSessionUploadCount();
    if (toBeUploadedInThisSession == 0) {
      return;
    }
    if (_completedUploads > toBeUploadedInThisSession ||
        _completedUploads < 0 ||
        toBeUploadedInThisSession < 0) {
      _logger.info(
        "Incorrect sync status",
        InvalidSyncStatusError(
          "Tried to report $_completedUploads as "
          "uploaded out of $toBeUploadedInThisSession",
        ),
      );
      return;
    }
    Bus.instance.fire(
      SyncStatusUpdate(
        SyncStatus.inProgress,
        completed: _completedUploads,
        total: toBeUploadedInThisSession,
      ),
    );
  }

  void _onFileUploadError(
    Object? error,
    StackTrace stackTrace,
    EnteFile file,
  ) {
    if (error == null) {
      return;
    }
    if (error is InvalidFileError) {
      _ignoredUploads++;
      _logger.warning("Invalid file error", error);
    } else {
      throw error;
    }
  }

  /* _storeDiff maps each remoteFile to existing
      entries in files table. When match is found, it compares both file to
      perform relevant actions like
      [1] Clear local cache when required (Both Shared and Owned files)
      [2] Retain localID of remote file based on matching logic [Owned files]
      [3] Refresh UI if visibility or creationTime has changed [Owned files]
      [4] Schedule file update if the local file has changed since last time
      [Owned files]
    [Important Note: If given uploadedFileID and collectionID is already present
     in files db, the generateID should already point to existing entry.
     Known Issues:
      [K1] Cached entry will not be cleared when if a file was edited and
      moved to different collection as Vid/Image cache key is uploadedID.
      [Existing]
    ]
   */
  Future<void> _storeDiff(List<EnteFile> diff, int collectionID) async {
    int sharedFileNew = 0,
        sharedFileUpdated = 0,
        localUploadedFromDevice = 0,
        localButUpdatedOnDevice = 0,
        remoteNewFile = 0;
    final int userID = _config.getUserID()!;
    bool needsGalleryReload = false;
    // this is required when same file is uploaded twice in the same
    // collection. Without this check, if both remote files are part of same
    // diff response, then we end up inserting one entry instead of two
    // as we update the generatedID for remoteFile to local file's genID
    final Set<int> alreadyClaimedLocalFilesGenID = {};

    final List<EnteFile> toBeInserted = [];
    for (EnteFile remoteFile in diff) {
      // existingFile will be either set to existing collectionID+localID or
      // to the unclaimed aka not already linked to any uploaded file.
      EnteFile? existingFile;
      if (remoteFile.generatedID != null) {
        // Case [1] Check and clear local cache when uploadedFile already exist
        // Note: Existing file can be null here if it's replaced by the time we
        // reach here
        existingFile = await _db.getUploadedFile(
          remoteFile.uploadedFileID!,
          remoteFile.collectionID!,
        );
        if (existingFile != null &&
            _shouldClearCache(remoteFile, existingFile)) {
          needsGalleryReload = true;
          await clearCache(remoteFile);
        }
      }

      /* If file is not owned by the user, no further processing is required
      as Case [2,3,4] are only relevant to files owned by user
       */
      if (userID != remoteFile.ownerID) {
        if (existingFile == null) {
          sharedFileNew++;
          remoteFile.localID = null;
        } else {
          sharedFileUpdated++;
          // if user has downloaded the file on the device, avoid removing the
          // localID reference.
          // [Todo-fix: Excluded shared file's localIDs during syncALL]
          remoteFile.localID = existingFile.localID;
        }
        toBeInserted.add(remoteFile);
        // end processing for file here, move to next file now
        continue;
      }

      // If remoteFile was synced before, assign the localID of the existing
      // file entry.
      // If remoteFile is not synced before and has localID (i.e. existingFile
      // is null), check if the remoteFile was uploaded from this device.
      // Note: DeviceFolder is ignored for iOS during matching
      if (existingFile != null) {
        remoteFile.localID = existingFile.localID;
      } else if (remoteFile.localID != null && existingFile == null) {
        final localFileEntries = await _db.getUnlinkedLocalMatchesForRemoteFile(
          userID,
          remoteFile.localID!,
          remoteFile.fileType,
          title: remoteFile.title ?? '',
          deviceFolder: remoteFile.deviceFolder ?? '',
        );
        if (localFileEntries.isEmpty) {
          // set remote file's localID as null because corresponding local file
          // does not exist [Case 2, do not retain localID of the remote file]
          remoteFile.localID = null;
        } else {
          // case 4: Check and schedule the file for update
          final int maxModificationTime = localFileEntries
              .map(
                (e) => e.modificationTime ?? 0,
              )
              .reduce(max);

          /* Note: In case of iOS, we will miss any asset modification in
            between of two installation. This is done to avoid fetching assets
            from iCloud when modification time could have changed for number of
            reasons. To fix this, we need to identify a way to store version
            for the adjustments or just if the asset has been modified ever.
            https://stackoverflow.com/a/50093266/546896
            */
          if (maxModificationTime > remoteFile.modificationTime! &&
              Platform.isAndroid) {
            localButUpdatedOnDevice++;
            await FileUpdationDB.instance.insertMultiple(
              [remoteFile.localID!],
              FileUpdationDB.modificationTimeUpdated,
            );
          }

          localFileEntries.removeWhere(
            (e) =>
                e.uploadedFileID != null ||
                alreadyClaimedLocalFilesGenID.contains(e.generatedID),
          );

          if (localFileEntries.isNotEmpty) {
            // file uploaded from same device, replace the local file row by
            // setting the generated ID of remoteFile to localFile generatedID
            existingFile = localFileEntries.first;
            localUploadedFromDevice++;
            alreadyClaimedLocalFilesGenID.add(existingFile.generatedID!);
            remoteFile.generatedID = existingFile.generatedID;
          }
        }
      }
      if (existingFile != null &&
          _shouldReloadHomeGallery(remoteFile, existingFile)) {
        needsGalleryReload = true;
      } else {
        remoteNewFile++;
      }
      toBeInserted.add(remoteFile);
    }
    await _db.insertMultiple(toBeInserted);
    _logger.info(
      "Diff to be deduplicated was: " +
          diff.length.toString() +
          " out of which \n" +
          localUploadedFromDevice.toString() +
          " was uploaded from device, \n" +
          localButUpdatedOnDevice.toString() +
          " was uploaded from device, but has been updated since and should be reuploaded, \n" +
          sharedFileNew.toString() +
          " new sharedFiles, \n" +
          sharedFileUpdated.toString() +
          " updatedSharedFiles, and \n" +
          remoteNewFile.toString() +
          " remoteFiles seen first time",
    );
    if (needsGalleryReload) {
      // 'force reload home gallery'
      Bus.instance.fire(ForceReloadHomeGalleryEvent("remoteSync"));
    }
  }

  bool _shouldClearCache(EnteFile remoteFile, EnteFile existingFile) {
    if (remoteFile.hash != null && existingFile.hash != null) {
      return remoteFile.hash != existingFile.hash;
    }
    return remoteFile.updationTime != (existingFile.updationTime ?? 0);
  }

  bool _shouldReloadHomeGallery(EnteFile remoteFile, EnteFile existingFile) {
    int remoteCreationTime = remoteFile.creationTime!;
    if (remoteFile.pubMmdVersion > 0 &&
        (remoteFile.pubMagicMetadata?.editedTime ?? 0) != 0) {
      remoteCreationTime = remoteFile.pubMagicMetadata!.editedTime!;
    }
    if (remoteCreationTime != existingFile.creationTime) {
      return true;
    }
    if (existingFile.mMdVersion > 0 &&
        remoteFile.mMdVersion != existingFile.mMdVersion &&
        remoteFile.magicMetadata.visibility !=
            existingFile.magicMetadata.visibility) {
      return false;
    }
    return false;
  }

  // return true if the client needs to re-sync the collections from previous
  // version
  bool _shouldResetSyncTime() {
    return !_prefs.containsKey(kHasSyncedEditTime) ||
        !_prefs.containsKey(kHasSyncedArchiveKey);
  }

  Future<void> _markResetSyncTimeAsDone() async {
    await _prefs.setBool(kHasSyncedArchiveKey, true);
    await _prefs.setBool(kHasSyncedEditTime, true);
    // Check to avoid regression because of change or additions of keys
    if (_shouldResetSyncTime()) {
      throw Exception("_shouldResetSyncTime should return false now");
    }
  }

  int _getSinceTimeForReSync() {
    // re-sync from archive feature time if the client still hasn't synced
    // since the feature release.
    if (!_prefs.containsKey(kHasSyncedArchiveKey)) {
      return kArchiveFeatureReleaseTime;
    }
    return kEditTimeFeatureReleaseTime;
  }

  bool _shouldThrottleSync() {
    return Platform.isIOS && !AppLifecycleService.instance.isForeground;
  }

  // _sortByTimeAndType moves videos to end and sort by creation time (desc).
  // This is done to upload most recent photo first.
  void _sortByTimeAndType(List<EnteFile> file) {
    file.sort((first, second) {
      if (first.fileType == second.fileType) {
        return second.creationTime!.compareTo(first.creationTime!);
      } else if (first.fileType == FileType.video) {
        return 1;
      } else {
        return -1;
      }
    });
    // move updated files towards the end
    file.sort((first, second) {
      if (first.updationTime == second.updationTime) {
        return 0;
      }
      if (first.updationTime == -1) {
        return 1;
      } else {
        return -1;
      }
    });
  }

  bool _shouldShowNotification(int collectionID) {
    // TODO: Add option to opt out of notifications for a specific collection
    // Screen: https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?type=design&node-id=7689-52943&t=IyWOfh0Gsb0p7yVC-4
    final isForeground = AppLifecycleService.instance.isForeground;
    final bool showNotification =
        NotificationService.instance.shouldShowNotificationsForSharedPhotos() &&
            isFirstRemoteSyncDone() &&
            !isForeground;
    _logger.info(
      "[Collection-$collectionID] shouldShow notification: $showNotification, "
      "isAppInForeground: $isForeground",
    );
    return showNotification;
  }

  Future<void> _notifyNewFiles(List<int> collectionIDs) async {
    final userID = Configuration.instance.getUserID();
    final appOpenTime = AppLifecycleService.instance.getLastAppOpenTime();
    for (final collectionID in collectionIDs) {
      if (!_shouldShowNotification(collectionID)) {
        continue;
      }
      final files =
          await _db.getNewFilesInCollection(collectionID, appOpenTime);
      final Set<int> sharedFilesIDs = {};
      final Set<int> collectedFilesIDs = {};
      for (final file in files) {
        if (file.isUploaded && file.ownerID != userID) {
          sharedFilesIDs.add(file.uploadedFileID!);
        } else if (file.isUploaded && file.isCollect) {
          collectedFilesIDs.add(file.uploadedFileID!);
        }
      }
      final totalCount = sharedFilesIDs.length + collectedFilesIDs.length;
      if (totalCount > 0) {
        final collection = _collectionsService.getCollectionByID(collectionID);
        _logger.finest(
          'creating notification for ${collection?.displayName} '
          'shared: $sharedFilesIDs, collected: $collectedFilesIDs files',
        );
        // ignore: unawaited_futures
        NotificationService.instance.showNotification(
          collection!.displayName,
          totalCount.toString() + " new 📸",
          channelID: "collection:" + collectionID.toString(),
          channelName: collection.displayName,
          payload: "ente://collection/?collectionID=" + collectionID.toString(),
        );
      }
    }
  }
}
