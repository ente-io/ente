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
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/local_sync_service.dart';
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
  int _completedUploads = 0;
  SharedPreferences _prefs;

  static const kDiffLimit = 2500;
  static const kHasSyncedArchiveKey = "has_synced_archive";
  // 28 Sept, 2021 9:03:20 AM IST
  static const kArchiveFeatureReleaseTime = 1632800000000000;

  static final RemoteSyncService instance =
      RemoteSyncService._privateConstructor();

  RemoteSyncService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> sync({bool silently = false}) async {
    if (!Configuration.instance.hasConfiguredAccount()) {
      _logger.info("Skipping remote sync since account is not configured");
      return;
    }

    bool isFirstSync = !_collectionsService.hasSyncedCollections();
    await _collectionsService.sync();

    if (isFirstSync || _hasSyncedArchive()) {
      await _syncUpdatedCollections(silently);
    } else {
      await _resyncAllCollectionsSinceTime(kArchiveFeatureReleaseTime);
    }
    if (!_hasSyncedArchive()) {
      await _markArchiveAsSynced();
    }

    bool hasUploadedFiles = await _uploadDiff();
    if (hasUploadedFiles) {
      sync(silently: true);
    }
  }

  Future<void> _syncUpdatedCollections(bool silently) async {
    final updatedCollections =
        await _collectionsService.getCollectionsToBeSynced();

    if (updatedCollections.isNotEmpty && !silently) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applying_remote_diff));
    }
    for (final c in updatedCollections) {
      await _syncCollectionDiff(
          c.id, _collectionsService.getCollectionSyncTime(c.id));
      await _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
  }

  Future<void> _resyncAllCollectionsSinceTime(int sinceTime) async {
    final collections = _collectionsService.getCollections();
    for (final c in collections) {
      await _syncCollectionDiff(c.id,
          min(_collectionsService.getCollectionSyncTime(c.id), sinceTime));
      await _collectionsService.setCollectionSyncTime(c.id, c.updationTime);
    }
  }

  Future<void> _syncCollectionDiff(int collectionID, int sinceTime) async {
    final diff = await _diffFetcher.getEncryptedFilesDiff(
        collectionID, sinceTime, kDiffLimit);
    if (diff.deletedFiles.isNotEmpty) {
      final fileIDs = diff.deletedFiles.map((f) => f.uploadedFileID).toList();
      final deletedFiles =
          (await FilesDB.instance.getFilesFromIDs(fileIDs)).values.toList();
      await FilesDB.instance.deleteFilesFromCollection(collectionID, fileIDs);
      Bus.instance.fire(CollectionUpdatedEvent(collectionID, deletedFiles,
          type: EventType.deleted));
      Bus.instance
          .fire(LocalPhotosUpdatedEvent(deletedFiles, type: EventType.deleted));
    }
    if (diff.updatedFiles.isNotEmpty) {
      await _storeDiff(diff.updatedFiles, collectionID);
      _logger.info("Updated " +
          diff.updatedFiles.length.toString() +
          " files in collection " +
          collectionID.toString());
      Bus.instance.fire(LocalPhotosUpdatedEvent(diff.updatedFiles));
      Bus.instance
          .fire(CollectionUpdatedEvent(collectionID, diff.updatedFiles));
    }
    if (diff.fetchCount == kDiffLimit) {
      return await _syncCollectionDiff(collectionID,
          _collectionsService.getCollectionSyncTime(collectionID));
    }
  }

  Future<bool> _uploadDiff() async {
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    List<File> filesToBeUploaded;
    if (LocalSyncService.instance.hasGrantedLimitedPermissions() &&
        foldersToBackUp.isEmpty) {
      filesToBeUploaded = await _db.getAllLocalFiles();
    } else {
      filesToBeUploaded =
          await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    }
    if (!Configuration.instance.shouldBackupVideos()) {
      filesToBeUploaded
          .removeWhere((element) => element.fileType == FileType.video);
    }
    _logger.info(
        filesToBeUploaded.length.toString() + " new files to be uploaded.");

    final updatedFileIDs = await _db.getUploadedFileIDsToBeUpdated();
    _logger.info(updatedFileIDs.length.toString() + " files updated.");

    final editedFiles = await _db.getEditedRemoteFiles();
    _logger.info(editedFiles.length.toString() + " files edited.");

    _completedUploads = 0;
    int toBeUploaded =
        filesToBeUploaded.length + updatedFileIDs.length + editedFiles.length;

    if (toBeUploaded > 0) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.preparing_for_upload));
    }
    final List<Future> futures = [];
    for (final uploadedFileID in updatedFileIDs) {
      final file = await _db.getUploadedFileInAnyCollection(uploadedFileID);
      final future = _uploader
          .upload(file, file.collectionID)
          .then((uploadedFile) => _onFileUploaded(uploadedFile));
      futures.add(future);
    }

    for (final file in filesToBeUploaded) {
      final collectionID = (await CollectionsService.instance
              .getOrCreateForPath(file.deviceFolder))
          .id;
      final future = _uploader
          .upload(file, collectionID)
          .then((uploadedFile) => _onFileUploaded(uploadedFile));
      futures.add(future);
    }

    for (final file in editedFiles) {
      final future = _uploader
          .upload(file, file.collectionID)
          .then((uploadedFile) => _onFileUploaded(uploadedFile));
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
      rethrow;
    }
    return _completedUploads > 0;
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
      _logger.severe(
          "Incorrect sync status",
          InvalidSyncStatusError("Tried to report " +
              _completedUploads.toString() +
              " as uploaded out of " +
              toBeUploadedInThisSession.toString()));
      return;
    }
    Bus.instance.fire(SyncStatusUpdate(SyncStatus.in_progress,
        completed: _completedUploads, total: toBeUploadedInThisSession));
  }

  Future _storeDiff(List<File> diff, int collectionID) async {
    int existing = 0,
        updated = 0,
        remote = 0,
        localButUpdatedOnRemote = 0,
        localButAddedToNewCollectionOnRemote = 0;
    List<File> toBeInserted = [];
    for (File file in diff) {
      final existingFiles = file.deviceFolder == null
          ? null
          : await _db.getMatchingFiles(file.title, file.deviceFolder);
      if (existingFiles == null || existingFiles.isEmpty) {
        // File uploaded from a different device.
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

        final fileWithLocalID = existingFiles
            .firstWhere((e) => e.localID != null, orElse: () => null);
        if (fileWithLocalID != null) {
          // File should ideally have the same localID
          if (file.localID != null && file.localID != fileWithLocalID.localID) {
            _logger.severe(
                "unexpected mismatch in localIDs remote: ${file.toString()} and existing: ${fileWithLocalID.toString()}");
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
            _logger.info("Updated since last installation: " +
                file.uploadedFileID.toString());
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
    if (toBeInserted.isNotEmpty) {
      await _collectionsService.setCollectionSyncTime(
          collectionID, toBeInserted[toBeInserted.length - 1].updationTime);
    }
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
  }

  bool _hasSyncedArchive() {
    return _prefs.containsKey(kHasSyncedArchiveKey);
  }

  Future<bool> _markArchiveAsSynced() {
    return _prefs.setBool(kHasSyncedArchiveKey, true);
  }
}
