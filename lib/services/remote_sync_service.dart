import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/utils/diff_fetcher.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/file_util.dart';

class RemoteSyncService {
  final _logger = Logger("RemoteSyncService");
  final _db = FilesDB.instance;
  final _uploader = FileUploader.instance;
  final _collectionsService = CollectionsService.instance;
  final _diffFetcher = DiffFetcher();
  int _completedUploads = 0;

  static const kDiffLimit = 2500;

  static final RemoteSyncService instance =
      RemoteSyncService._privateConstructor();

  RemoteSyncService._privateConstructor();

  Future<void> init() async {}

  Future<void> sync({bool silently = false}) async {
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
      sync(silently: true);
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
    final foldersToBackUp = Configuration.instance.getPathsToBackUp();
    var filesToBeUploaded;
    if (LocalSyncService.instance.hasGrantedLimitedPermissions() &&
        foldersToBackUp.isEmpty) {
      filesToBeUploaded = await _db.getAllLocalFiles();
    } else {
      filesToBeUploaded =
          await _db.getFilesToBeUploadedWithinFolders(foldersToBackUp);
    }
    if (kDebugMode) {
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
    final alreadyUploaded = await FilesDB.instance.getNumberOfUploadedFiles();
    final List<Future> futures = [];
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

    for (final file in editedFiles) {
      final future = _uploader.upload(file, file.collectionID).then(
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
      if (existingFiles == null) {
        // File uploaded from a different device
        file.localID = null;
        toBeInserted.add(file);
        remote++;
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
              clearCache(file);
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
    if (toBeInserted.length > 0) {
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
}
