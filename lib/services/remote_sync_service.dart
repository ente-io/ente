import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/services/file_migration_service.dart';
import 'package:photos/services/ignored_files_service.dart';
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
  final FileMigrationService _fileMigrationService =
      FileMigrationService.instance;
  int _completedUploads = 0;
  SharedPreferences _prefs;
  Completer<void> _existingSync;

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
      return _existingSync.future;
    }
    _existingSync = Completer<void>();

    try {
      await _pullDiff(silently);
      // sync trash but consume error during initial launch.
      // this is to ensure that we don't pause upload due to any error during
      // the trash sync. Impact: We may end up re-uploading a file which was
      // recently trashed.
      await TrashSyncService.instance
          .syncTrash()
          .onError((e, s) => _logger.severe('trash sync failed', e, s));
      final filesToBeUploaded = await _getFilesToBeUploaded();
      final hasUploadedFiles = await _uploadFiles(filesToBeUploaded);
      if (hasUploadedFiles) {
        await _pullDiff(true);
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
    }
  }

  Future<void> _pullDiff(bool silently) async {
    final isFirstSync = !_collectionsService.hasSyncedCollections();
    await _collectionsService.sync();

    if (isFirstSync || _hasReSynced()) {
      await _syncUpdatedCollections(silently);
    } else {
      final syncSinceTime = _getSinceTimeForReSync();
      await _resyncAllCollectionsSinceTime(syncSinceTime);
    }
    if (!_hasReSynced()) {
      await _markReSyncAsDone();
    }
    if (FeatureFlagService.instance.enableMissingLocationMigration()) {
      _fileMigrationService.runMigration();
    }
  }

  Future<void> _syncUpdatedCollections(bool silently) async {
    final updatedCollections =
        await _collectionsService.getCollectionsToBeSynced();

    if (updatedCollections.isNotEmpty && !silently) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    for (final c in updatedCollections) {
      await _syncCollectionDiff(
        c.id,
        _collectionsService.getCollectionSyncTime(c.id),
      );
      await _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
  }

  Future<void> _resyncAllCollectionsSinceTime(int sinceTime) async {
    _logger.info('re-sync collections sinceTime: $sinceTime');
    final collections = _collectionsService.getActiveCollections();
    for (final c in collections) {
      await _syncCollectionDiff(
        c.id,
        min(_collectionsService.getCollectionSyncTime(c.id), sinceTime),
      );
      await _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
  }

  Future<void> _syncCollectionDiff(int collectionID, int sinceTime) async {
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

  Future<List<File>> _getFilesToBeUploaded() async {
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    List<File> filesToBeUploaded;
    if (LocalSyncService.instance.hasGrantedLimitedPermissions() &&
        foldersToBackUp.isEmpty) {
      filesToBeUploaded = await _db.getAllLocalFiles();
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
    int toBeUploaded =
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

  Future _storeDiff(List<File> diff, int collectionID) async {
    int existing = 0,
        updated = 0,
        remote = 0,
        localButUpdatedOnRemote = 0,
        localButAddedToNewCollectionOnRemote = 0;
    bool hasAnyCreationTimeChanged = false;
    List<File> toBeInserted = [];
    int userID = Configuration.instance.getUserID();
    for (File file in diff) {
      final existingFiles = file.deviceFolder == null
          ? null
          : await _db.getMatchingFiles(file.title, file.deviceFolder);
      if (existingFiles == null ||
          existingFiles.isEmpty ||
          userID != file.ownerID) {
        // File uploaded from a different device or uploaded by different user
        // Other rare possibilities : The local file is present on
        // device but it's not imported in local db due to missing permission
        // after reinstall (iOS selected file permissions or user revoking
        // permissions, or issue/delay in importing devices files.
        file.localID = null;
        toBeInserted.add(file);
        remote++;
      } else {
        // File exists in ente db with same title & device folder
        // Note: The file.generatedID might be already set inside
        // [DiffFetcher.getEncryptedFilesDiff]
        // Try to find existing file with same localID as remote file with a fallback
        // to finding any existing file with localID. This is needed to handle
        // case when localID for a file changes and the file is uploaded again in
        // the same collection
        final fileWithLocalID = existingFiles.firstWhere(
          (e) =>
              file.localID != null &&
              e.localID != null &&
              e.localID == file.localID,
          orElse: () => existingFiles.firstWhere(
            (e) => e.localID != null,
            orElse: () => null,
          ),
        );
        if (fileWithLocalID != null) {
          // File should ideally have the same localID
          if (file.localID != null && file.localID != fileWithLocalID.localID) {
            _logger.severe(
              "unexpected mismatch in localIDs remote: ${file.toString()} and existing: ${fileWithLocalID.toString()}",
            );
          }
          file.localID = fileWithLocalID.localID;
        } else {
          file.localID = null;
        }
        bool wasUploadedOnAPreviousInstallation =
            existingFiles.length == 1 && existingFiles[0].collectionID == null;
        if (wasUploadedOnAPreviousInstallation) {
          file.generatedID = existingFiles[0].generatedID;
          if (file.modificationTime != existingFiles[0].modificationTime) {
            // File was updated since the app was uninstalled
            // mark it for re-upload
            _logger.info(
              "re-upload because file was updated since last installation: "
              "remoteFile:  ${file.toString()}, localFile: ${existingFiles[0].toString()}",
            );
            file.modificationTime = existingFiles[0].modificationTime;
            file.updationTime = null;
            updated++;
          } else {
            existing++;
          }
          toBeInserted.add(file);
        } else {
          bool foundMatchingCollection = false;
          for (final existingFile in existingFiles) {
            if (file.collectionID == existingFile.collectionID &&
                file.uploadedFileID == existingFile.uploadedFileID) {
              // File was updated on remote
              if (file.creationTime != existingFile.creationTime) {
                hasAnyCreationTimeChanged = true;
              }
              foundMatchingCollection = true;
              file.generatedID = existingFile.generatedID;
              toBeInserted.add(file);
              await clearCache(file);
              localButUpdatedOnRemote++;
              break;
            }
          }
          if (!foundMatchingCollection) {
            // Added to a new collection
            toBeInserted.add(file);
            localButAddedToNewCollectionOnRemote++;
          }
        }
      }
    }
    await _db.insertMultiple(toBeInserted);
    _logger.info(
      "Diff to be deduplicated was: " +
          diff.length.toString() +
          " out of which \n" +
          existing.toString() +
          " was uploaded from device, \n" +
          updated.toString() +
          " was uploaded from device, but has been updated since and should be reuploaded, \n" +
          remote.toString() +
          " was uploaded from remote, \n" +
          localButUpdatedOnRemote.toString() +
          " was uploaded from device but updated on remote, and \n" +
          localButAddedToNewCollectionOnRemote.toString() +
          " was uploaded from device but added to a new collection on remote.",
    );
    if (hasAnyCreationTimeChanged) {
      Bus.instance.fire(ForceReloadHomeGalleryEvent());
    }
  }

  // return true if the client needs to re-sync the collections from previous
  // version
  bool _hasReSynced() {
    return _prefs.containsKey(kHasSyncedEditTime) &&
        _prefs.containsKey(kHasSyncedArchiveKey);
  }

  Future<void> _markReSyncAsDone() async {
    await _prefs.setBool(kHasSyncedArchiveKey, true);
    await _prefs.setBool(kHasSyncedEditTime, true);
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
