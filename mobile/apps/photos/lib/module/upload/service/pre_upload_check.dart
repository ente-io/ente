// Helper class that checks if the file that is being uploaded already exists

import "dart:io";

import "package:collection/collection.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/errors.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/remote/table/collection_files.dart";
import "package:photos/db/remote/table/files_table.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/models/file/remote/rl_mapping.dart";
import "package:photos/models/user_details.dart";
import "package:photos/module/upload/model/media.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/collections_service.dart";

class PreUploadCheck {
  static const k20MBStorageBuffer = 20 * 1024 * 1024;
  static const kMaxFileSize10Gib = 10737418240;
  static final _logger = Logger('PreUploadCheck');

  /*
  _mapToExistingUpload links the fileToUpload with the existing uploaded
  files. if the link is successful, it returns true otherwise false.
  When false, we should go ahead and re-upload or update the file.
  It performs following checks:
    a) Target file with same localID and destination collection exists. Delete the
     fileToUpload entry. If target file is sandbox file, then we skip localID match
     check.
    b) Uploaded file in any collection but with missing localID.
     Update the localID for uploadedFile and delete the fileToUpload entry
    c) A uploaded file exist with same localID but in a different collection.
    Add a symlink in the destination collection and update the fileToUpload.
    If target file is sandbox file, then we skip localID match
     check.
    d) File already exists but different localID. Re-upload
    In case the existing files already have local identifier, which is
    different from the {fileToUpload}, then most probably device has
    duplicate files.
  */
  static Future<EnteFile?> mapToExistingUploadWithSameHash(
    UploadMedia uploadMedia,
    EnteFile fileToUpload,
    int dstCollection,
  ) async {
    if (fileToUpload.rAsset != null) {
      throw AssertionError(
        "File to upload should not have remote asset, "
        "it should be a local file",
      );
    }
    final int userID = Configuration.instance.getUserID()!;
    final bool isSandBoxFile = fileToUpload.isSharedMediaToAppSandbox;
    final remoteIDs = await remoteDB.idsWithSameHashAndType(
      uploadMedia.hash,
      userID,
    );
    if (remoteIDs.isEmpty) {
      return null;
    }

    final List<CollectionFile> collectionFiles =
        await remoteDB.getAllCFForFileIDs(remoteIDs.toList());
    final Map<int, String> fileToLocalID =
        await remoteDB.getFileIDToLocalIDMapping(remoteIDs.toList());

    // case a, check if the file already exists in the destination collection
    // and the remoteID is already linked to the localID of fileToUpload or the file to
    // upload is a shared media to app sandbox file.
    for (final cf in collectionFiles) {
      if (cf.collectionID != dstCollection) {
        continue;
      }
      final Collection? c =
          CollectionsService.instance.getCollectionByID(cf.collectionID);
      if (c == null || c.isDeleted || !c.isOwner(userID)) {
        continue;
      }
      if (fileToLocalID[cf.fileID] == fileToUpload.localID || isSandBoxFile) {
        _logger.info(
          "Found same localID in collection: ${cf.collectionID} "
          "for file: ${fileToUpload.tag} with localID: ${fileToLocalID[cf.fileID]}",
        );
        final existingFile =
            await remoteCache.getCollectionFile(cf.collectionID, cf.fileID);
        if (existingFile == null) {
          throw AssertionError(
            "CollectionFile not found for collectionID: ${cf.collectionID} "
            "and fileID: ${cf.fileID}",
          );
        }
        existingFile.lAsset = fileToUpload.lAsset;
        Bus.instance.fire(
          LocalPhotosUpdatedEvent(
            [existingFile],
            type: EventType.deletedFromEverywhere,
            source: "sameLocalSameCollection", //
          ),
        );
        return existingFile;
      }
    }
    // case 2, check if the file already exists in the destination collection,
    // the remoteID is not linked to any other localID.
    for (final cf in collectionFiles) {
      if (cf.collectionID != dstCollection) {
        continue;
      }
      final Collection? c =
          CollectionsService.instance.getCollectionByID(cf.collectionID);
      if (c == null || c.isDeleted || !c.isOwner(userID)) {
        continue;
      }
      if (fileToLocalID[cf.fileID] == null) {
        final existingFile =
            await remoteCache.getCollectionFile(cf.collectionID, cf.fileID);
        if (existingFile == null) {
          throw AssertionError(
            "CollectionFile not found for collectionID: ${cf.collectionID} "
            "and fileID: ${cf.fileID}",
          );
        }
        _logger.info(
          "fileMissingLocal: \n toUpload  ${fileToUpload.tag} "
          "\n existing: ${existingFile.tag}",
        );
        existingFile.lAsset = fileToUpload.lAsset;
        if (fileToUpload.lAsset != null) {
          await remoteDB.insertMappings([
            RLMapping(
              remoteUploadID: cf.fileID,
              localID: fileToUpload.localID!,
              localCloudID: null,
              mappingType: MatchType.deviceUpload,
            ),
          ]);
        }
        Bus.instance.fire(
          LocalPhotosUpdatedEvent(
            [fileToUpload],
            source: "fileMissingLocal",
            type: EventType.deletedFromEverywhere, //
          ),
        );
        return existingFile;
      }
    }

    // case c unmappied remoteID ExistsButDifferentCollection
    for (final cf in collectionFiles) {
      final Collection? c =
          CollectionsService.instance.getCollectionByID(cf.collectionID);
      if (c == null || c.isDeleted || !c.isOwner(userID)) {
        continue;
      }
      if (fileToLocalID[cf.fileID] == fileToUpload.localID ||
          fileToLocalID[cf.fileID] == null ||
          isSandBoxFile) {
        final existingFile =
            await remoteCache.getCollectionFile(cf.collectionID, cf.fileID);
        if (existingFile == null) {
          throw AssertionError(
            "CollectionFile not found for collectionID: ${cf.collectionID} "
            "and fileID: ${cf.fileID}",
          );
        }
        final linkedFile = await CollectionsService.instance
            .linkLocalFileToExistingUploadedFileInAnotherCollection(
          dstCollection,
          localFileToUpload: fileToUpload,
          existingUploadedFile: existingFile,
        );
        if (fileToLocalID[cf.fileID] == null && !isSandBoxFile) {
          // if the fileToLocalID is null, then we need to insert the mapping
          await remoteDB.insertMappings([
            RLMapping(
              remoteUploadID: cf.fileID,
              localID: fileToUpload.localID!,
              localCloudID: null,
              mappingType: MatchType.deviceUpload,
            ),
          ]);
        }
        return linkedFile;
      }
    }
    // case d, file already exists but different localID.
    _logger.info(
      "Found hash match but probably with diff localIDs "
      "${fileToLocalID.toString()} for file: ${fileToUpload.tag}",
    );
    return null;
  }

  /*
  _checkIfWithinStorageLimit verifies if the file size for encryption and upload
   is within the storage limit. It throws StorageLimitExceededError if the limit
    is exceeded. This check is best effort and may not be completely accurate
    due to UserDetail cache. It prevents infinite loops when clients attempt to
    upload files that exceed the server's storage limit + buffer.
    Note: Local storageBuffer is 20MB, server storageBuffer is 50MB, and an
    additional 30MB is reserved for thumbnails and encryption overhead.
   */
  static Future<void> checkIfWithinStorageLimit(File fileToBeUploaded) async {
    try {
      final UserDetails? userDetails =
          UserService.instance.getCachedUserDetails();
      if (userDetails == null) {
        return;
      }
      // add k20MBStorageBuffer to the free storage
      final num freeStorage = userDetails.getFreeStorage() + k20MBStorageBuffer;
      final num fileSize = await fileToBeUploaded.length();
      if (fileSize > freeStorage) {
        _logger.warning("Storage limit exceeded fileSize $fileSize and "
            'freeStorage $freeStorage');
        throw StorageLimitExceededError();
      }
      if (fileSize > kMaxFileSize10Gib) {
        _logger.warning('File size exceeds 10GiB fileSize $fileSize');
        throw InvalidFileError(
          'file size above 10GiB',
          InvalidReason.tooLargeFile,
        );
      }
    } catch (e) {
      if (e is StorageLimitExceededError || e is InvalidFileError) {
        rethrow;
      } else {
        _logger.severe('Error checking storage limit', e);
      }
    }
  }
}
