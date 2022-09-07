import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/local_file_update_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/trash_sync_service.dart';
import 'package:photos/utils/diff_fetcher.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteSyncService {
  final _logger = Logger("RemoteSyncService");
  final _db = FilesDB.instance;
  final _uploader = FileUploader.instance;
  final _collectionsService = CollectionsService.instance;
  final _diffFetcher = DiffFetcher();
  final LocalFileUpdateService _localFileUpdateService =
      LocalFileUpdateService.instance;
  int _completedUploads = 0;
  SharedPreferences _prefs;
  Completer<void> _existingSync;
  bool _existingSyncSilent = false;

  static const kHasSyncedArchiveKey = "has_synced_archive";

  // 28 Sept, 2021 9:03:20 AM IST
  static const kArchiveFeatureReleaseTime = 1632800000000000;
  static const kHasSyncedEditTime = "has_synced_edit_time";

  // 29 October, 2021 3:56:40 AM IST
  static const kEditTimeFeatureReleaseTime = 1635460000000000;

  static const kMaximumPermissibleUploadsInThrottledMode = 4;

  static final RemoteSyncService instance =
      RemoteSyncService._privateConstructor();

  RemoteSyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) async {
      if (event.type == EventType.addedOrUpdated) {
        if (_existingSync == null) {
          sync();
        }
      }
    });
  }

  Future<void> sync({bool silently = false}) async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      _logger.info("Skipping remote sync since account is not configured");
      return;
    }
    if (_existingSync != null) {
      _logger.info("Remote sync already in progress, skipping");
      // if current sync is silent but request sync is non-silent (demands UI
      // updates), update the syncSilently flag
      if (_existingSyncSilent == true && silently == false) {
        _existingSyncSilent = false;
      }
      return _existingSync.future;
    }
    _existingSync = Completer<void>();
    _existingSyncSilent = silently;

    try {
      await _pullDiff();
      // sync trash but consume error during initial launch.
      // this is to ensure that we don't pause upload due to any error during
      // the trash sync. Impact: We may end up re-uploading a file which was
      // recently trashed.
      await TrashSyncService.instance
          .syncTrash()
          .onError((e, s) => _logger.severe('trash sync failed', e, s));
      await _syncDeviceCollectionFilesForUpload();
      final filesToBeUploaded = await _getFilesToBeUploaded();
      if (kDebugMode) {
        debugPrint("Skip upload for testing");
        filesToBeUploaded.clear();
      }
      final hasUploadedFiles = await _uploadFiles(filesToBeUploaded);
      if (hasUploadedFiles) {
        await _pullDiff();
        _existingSync.complete();
        _existingSync = null;
        final hasMoreFilesToBackup = (await _getFilesToBeUploaded()).isNotEmpty;
        if (hasMoreFilesToBackup && !_shouldThrottleSync()) {
          // Skipping a resync to ensure that files that were ignored in this
          // session are not processed now
          sync();
        } else {
          Bus.instance.fire(SyncStatusUpdate(SyncStatus.completedBackup));
        }
      } else {
        _existingSync.complete();
        _existingSync = null;
      }
    } catch (e, s) {
      _existingSync.complete();
      _existingSync = null;
      // rethrow whitelisted error so that UI status can be updated correctly.
      if (e is UnauthorizedError ||
          e is NoActiveSubscriptionError ||
          e is WiFiUnavailableError ||
          e is StorageLimitExceededError ||
          e is SyncStopRequestedError) {
        _logger.warning("Error executing remote sync", e);
        rethrow;
      } else {
        _logger.severe("Error executing remote sync ", e, s);
      }
    } finally {
      _existingSyncSilent = false;
    }
  }

  Future<void> _pullDiff() async {
    final isFirstSync = !_collectionsService.hasSyncedCollections();
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

    await _syncUpdatedCollections();
    unawaited(_localFileUpdateService.markUpdatedFilesForReUpload());
  }

  Future<void> _syncUpdatedCollections() async {
    final updatedCollections =
        await _collectionsService.getCollectionsToBeSynced();
    for (final c in updatedCollections) {
      await _syncCollectionDiff(
        c.id,
        _collectionsService.getCollectionSyncTime(c.id),
      );
      await _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
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
    if (!_existingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    final diff =
        await _diffFetcher.getEncryptedFilesDiff(collectionID, sinceTime);
    if (diff.deletedFiles.isNotEmpty) {
      final fileIDs = diff.deletedFiles.map((f) => f.uploadedFileID).toList();
      final deletedFiles =
          (await FilesDB.instance.getFilesFromIDs(fileIDs)).values.toList();
      await FilesDB.instance.deleteFilesFromCollection(collectionID, fileIDs);
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collectionID,
          deletedFiles,
          type: EventType.deletedFromRemote,
        ),
      );
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          deletedFiles,
          type: EventType.deletedFromRemote,
        ),
      );
    }
    if (diff.updatedFiles.isNotEmpty) {
      await _storeDiff(diff.updatedFiles, collectionID);
      _logger.info(
        "Updated " +
            diff.updatedFiles.length.toString() +
            " files in collection " +
            collectionID.toString(),
      );
      Bus.instance.fire(LocalPhotosUpdatedEvent(diff.updatedFiles));
      Bus.instance
          .fire(CollectionUpdatedEvent(collectionID, diff.updatedFiles));
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
  }

  Future<void> _syncDeviceCollectionFilesForUpload() async {
    final deviceCollections = await FilesDB.instance.getDeviceCollections();
    deviceCollections.removeWhere((element) => !element.shouldBackup);
    await _createCollectionsForDevicePath(deviceCollections);
  }

  Future<void> _createCollectionsForDevicePath(
    List<DeviceCollection> deviceCollections,
  ) async {
    for (var deviceCollection in deviceCollections) {
      int deviceCollectionID = deviceCollection.collectionID;
      if (deviceCollectionID != -1) {
        final collectionByID =
            CollectionsService.instance.getCollectionByID(deviceCollectionID);
        if (collectionByID == null || collectionByID.isDeleted) {
          _logger.info(
            "Collection $deviceCollectionID either deleted or missing "
            "for path ${deviceCollection.name}",
          );
          deviceCollectionID = -1;
        }
      }
      if (deviceCollectionID == -1) {
        final collection = await CollectionsService.instance
            .getOrCreateForPath(deviceCollection.name);
        await FilesDB.instance
            .updateDeviceCollection(deviceCollection.id, collection.id);
        deviceCollection.collectionID = collection.id;
      }
    }
  }

  Future<List<File>> _getFilesToBeUploaded() async {
    final deviceCollections = await FilesDB.instance.getDeviceCollections();
    deviceCollections.removeWhere((element) => !element.shouldBackup);
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    List<File> filesToBeUploaded;
    if (LocalSyncService.instance.hasGrantedLimitedPermissions() &&
        foldersToBackUp.isEmpty) {
      filesToBeUploaded = await _db.getUnUploadedLocalFiles();
    } else {
      filesToBeUploaded =
          await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    }
    if (!Configuration.instance.shouldBackupVideos() || _shouldThrottleSync()) {
      filesToBeUploaded
          .removeWhere((element) => element.fileType == FileType.video);
    }
    if (filesToBeUploaded.isNotEmpty) {
      final int prevCount = filesToBeUploaded.length;
      final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
      filesToBeUploaded.removeWhere(
        (file) =>
            IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, file),
      );
      if (prevCount != filesToBeUploaded.length) {
        _logger.info(
          (prevCount - filesToBeUploaded.length).toString() +
              " files were ignored for upload",
        );
      }
    }
    if (filesToBeUploaded.isEmpty) {
      // look for files which user manually tried to back up but they are not
      // uploaded yet. These files should ignore video backup & ignored files filter
      filesToBeUploaded = await _db.getPendingManualUploads();
    }
    _sortByTimeAndType(filesToBeUploaded);
    _logger.info(
      filesToBeUploaded.length.toString() + " new files to be uploaded.",
    );
    return filesToBeUploaded;
  }

  Future<bool> _uploadFiles(List<File> filesToBeUploaded) async {
    final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated();
    _logger.info(updatedFileIDs.length.toString() + " files updated.");

    final editedFiles = await _db.getEditedRemoteFiles();
    _logger.info(editedFiles.length.toString() + " files edited.");

    _completedUploads = 0;
    final int toBeUploaded =
        filesToBeUploaded.length + updatedFileIDs.length + editedFiles.length;

    if (toBeUploaded > 0) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.preparingForUpload));
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
      final file = await _db.getUploadedFileInAnyCollection(uploadedFileID);
      _uploadFile(file, file.collectionID, futures);
    }

    for (final file in filesToBeUploaded) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger.info("Skipping some new files as we are throttling uploads");
        break;
      }
      // prefer existing collection ID for manually uploaded files.
      // See https://github.com/ente-io/frame/pull/187
      final collectionID = file.collectionID ??
          (await CollectionsService.instance
                  .getOrCreateForPath(file.deviceFolder))
              .id;
      _uploadFile(file, collectionID, futures);
    }

    for (final file in editedFiles) {
      if (_shouldThrottleSync() &&
          futures.length >= kMaximumPermissibleUploadsInThrottledMode) {
        _logger.info("Skipping some edited files as we are throttling uploads");
        break;
      }
      _uploadFile(file, file.collectionID, futures);
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

  void _uploadFile(File file, int collectionID, List<Future> futures) {
    final future = _uploader
        .upload(file, collectionID)
        .then((uploadedFile) => _onFileUploaded(uploadedFile));
    futures.add(future);
  }

  Future<void> _onFileUploaded(File file) async {
    Bus.instance.fire(CollectionUpdatedEvent(file.collectionID, [file]));
    _completedUploads++;
    final toBeUploadedInThisSession =
        FileUploader.instance.getCurrentSessionUploadCount();
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

  /* _storeDiff maps each remoteDiff file to existing
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
  Future _storeDiff(List<File> diff, int collectionID) async {
    int sharedFileNew = 0,
        sharedFileUpdated = 0,
        localUploadedFromDevice = 0,
        localButUpdatedOnDevice = 0,
        remoteNewFile = 0;
    final int userID = Configuration.instance.getUserID();
    bool needsGalleryReload = false;
    // this is required when same file is uploaded twice in the same
    // collection. Without this check, if both remote files are part of same
    // diff response, then we end up inserting one entry instead of two
    // as we update the generatedID for remoteDiff to local file's genID
    final Set<int> alreadyClaimedLocalFilesGenID = {};

    final List<File> toBeInserted = [];
    for (File remoteDiff in diff) {
      // existingFile will be either set to existing collectionID+localID or
      // to the unclaimed aka not already linked to any uploaded file.
      File existingFile;
      if (remoteDiff.generatedID != null) {
        // Case [1] Check and clear local cache when uploadedFile already exist
        existingFile = await _db.getFile(remoteDiff.generatedID);
        if (_shouldClearCache(remoteDiff, existingFile)) {
          await clearCache(remoteDiff);
        }
      }

      /* If file is not owned by the user, no further processing is required
      as Case [2,3,4] are only relevant to files owned by user
       */
      if (userID != remoteDiff.ownerID) {
        if (existingFile == null) {
          sharedFileNew++;
          remoteDiff.localID = null;
        } else {
          sharedFileUpdated++;
          // if user has downloaded the file on the device, avoid removing the
          // localID reference.
          // [Todo-fix: Excluded shared file's localIDs during syncALL]
          remoteDiff.localID = existingFile.localID;
        }
        toBeInserted.add(remoteDiff);
        // end processing for file here, move to next file now
        continue;
      }

      // If remoteDiff is not already synced (i.e. existingFile is null), check
      // if the remoteFile was uploaded from this device.
      // Note: DeviceFolder is ignored for iOS during matching
      if (existingFile == null && remoteDiff.localID != null) {
        final localFileEntries = await _db.getUnlinkedLocalMatchesForRemoteFile(
          userID,
          remoteDiff.localID,
          remoteDiff.fileType,
          title: remoteDiff.title,
          deviceFolder: remoteDiff.deviceFolder,
        );
        if (localFileEntries.isEmpty) {
          // set remote file's localID as null because corresponding local file
          // does not exist [Case 2, do not retain localID of the remote file]
          remoteDiff.localID = null;
        } else {
          // case 4: Check and schedule the file for update
          final int maxModificationTime = localFileEntries
              .map(
                (e) => e.modificationTime ?? 0,
              )
              .reduce(max);
          if (maxModificationTime > remoteDiff.modificationTime) {
            localButUpdatedOnDevice++;
            await FileUpdationDB.instance.insertMultiple(
              [remoteDiff.localID],
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
            alreadyClaimedLocalFilesGenID.add(existingFile.generatedID);
            remoteDiff.generatedID = existingFile.generatedID;
          }
        }
      }
      if (existingFile != null &&
          _shouldReloadHomeGallery(remoteDiff, existingFile)) {
        needsGalleryReload = true;
      } else {
        remoteNewFile++;
      }
      toBeInserted.add(remoteDiff);
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
      Bus.instance.fire(ForceReloadHomeGalleryEvent());
    }
  }

  bool _shouldClearCache(File remoteFile, File existingFile) {
    if (remoteFile.hash != null && existingFile.hash != null) {
      return remoteFile.hash != existingFile.hash;
    }
    return remoteFile.updationTime != (existingFile.updationTime ?? 0);
  }

  bool _shouldReloadHomeGallery(File remoteFile, File existingFile) {
    int remoteCreationTime = remoteFile.creationTime;
    if (remoteFile.pubMmdVersion > 0 &&
        (remoteFile.pubMagicMetadata.editedTime ?? 0) != 0) {
      remoteCreationTime = remoteFile.pubMagicMetadata.editedTime;
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
  void _sortByTimeAndType(List<File> file) {
    file.sort((first, second) {
      if (first.fileType == second.fileType) {
        return second.creationTime.compareTo(first.creationTime);
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
}
