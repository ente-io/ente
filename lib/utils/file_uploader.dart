import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/encryption_result.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/models/upload_url.dart';
import "package:photos/models/user_details.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/file_magic_service.dart";
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import "package:photos/services/user_service.dart";
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:photos/utils/file_uploader_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import "package:uuid/uuid.dart";

class FileUploader {
  static const kMaximumConcurrentUploads = 4;
  static const kMaximumConcurrentVideoUploads = 2;
  static const kMaximumThumbnailCompressionAttempts = 2;
  static const kMaximumUploadAttempts = 4;
  static const kBlockedUploadsPollFrequency = Duration(seconds: 2);
  static const kFileUploadTimeout = Duration(minutes: 50);
  static const k20MBStorageBuffer = 20 * 1024 * 1024;

  final _logger = Logger("FileUploader");
  final _dio = NetworkClient.instance.getDio();
  final _enteDio = NetworkClient.instance.enteDio;
  final LinkedHashMap _queue = LinkedHashMap<String, FileUploadItem>();
  final _uploadLocks = UploadLocksDB.instance;
  final kSafeBufferForLockExpiry = const Duration(days: 1).inMicroseconds;
  final kBGTaskDeathTimeout = const Duration(seconds: 5).inMicroseconds;
  final _uploadURLs = Queue<UploadURL>();

  // Maintains the count of files in the current upload session.
  // Upload session is the period between the first entry into the _queue and last entry out of the _queue
  int _totalCountInUploadSession = 0;

  // _uploadCounter indicates number of uploads which are currently in progress
  int _uploadCounter = 0;
  int _videoUploadCounter = 0;
  late ProcessType _processType;
  late bool _isBackground;
  late SharedPreferences _prefs;

  FileUploader._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploadURLFetchInProgress = null;
    });
  }

  static FileUploader instance = FileUploader._privateConstructor();

  Future<void> init(SharedPreferences preferences, bool isBackground) async {
    _prefs = preferences;
    _isBackground = isBackground;
    _processType =
        isBackground ? ProcessType.background : ProcessType.foreground;
    final currentTime = DateTime.now().microsecondsSinceEpoch;
    await _uploadLocks.releaseLocksAcquiredByOwnerBefore(
      _processType.toString(),
      currentTime,
    );
    await _uploadLocks
        .releaseAllLocksAcquiredBefore(currentTime - kSafeBufferForLockExpiry);
    if (!isBackground) {
      await _prefs.reload();
      final isBGTaskDead = (_prefs.getInt(kLastBGTaskHeartBeatTime) ?? 0) <
          (currentTime - kBGTaskDeathTimeout);
      if (isBGTaskDead) {
        await _uploadLocks.releaseLocksAcquiredByOwnerBefore(
          ProcessType.background.toString(),
          currentTime,
        );
        _logger.info("BG task was found dead, cleared all locks");
      }
      _pollBackgroundUploadStatus();
    }
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere) {
        removeFromQueueWhere(
          (file) {
            for (final updatedFile in event.updatedFiles) {
              if (file.generatedID == updatedFile.generatedID) {
                return true;
              }
            }
            return false;
          },
          InvalidFileError("File already deleted"),
        );
      }
    });
  }

  // upload future will return null as File when the file entry is deleted
  // locally because it's already present in the destination collection.
  Future<File> upload(File file, int collectionID) {
    if (file.localID == null || file.localID!.isEmpty) {
      return Future.error(Exception("file's localID can not be null or empty"));
    }
    // If the file hasn't been queued yet, queue it
    _totalCountInUploadSession++;
    if (!_queue.containsKey(file.localID)) {
      final completer = Completer<File>();
      _queue[file.localID] = FileUploadItem(file, collectionID, completer);
      _pollQueue();
      return completer.future;
    }

    // If the file exists in the queue for a matching collectionID,
    // return the existing future
    final item = _queue[file.localID];
    if (item.collectionID == collectionID) {
      _totalCountInUploadSession--;
      return item.completer.future;
    }
    debugPrint(
      "Wait on another upload on same local ID to finish before "
      "adding it to new collection",
    );
    // Else wait for the existing upload to complete,
    // and add it to the relevant collection
    return item.completer.future.then((uploadedFile) {
      // If the fileUploader completer returned null,
      _logger.info(
        "original upload completer resolved, try adding the file to another "
        "collection",
      );
      if (uploadedFile == null) {
        /* todo: handle this case, ideally during next sync the localId
          should be uploaded to this collection ID
         */
        _logger.severe('unexpected upload state');
        return null;
      }
      return CollectionsService.instance
          .addToCollection(collectionID, [uploadedFile]).then((aVoid) {
        return uploadedFile as File;
      });
    });
  }

  int getCurrentSessionUploadCount() {
    return _totalCountInUploadSession;
  }

  void clearQueue(final Error reason) {
    final List<String> uploadsToBeRemoved = [];
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.notStarted)
        .forEach((pendingUpload) {
      uploadsToBeRemoved.add(pendingUpload.key);
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(reason);
    }
    _totalCountInUploadSession = 0;
  }

  void clearCachedUploadURLs() {
    _uploadURLs.clear();
  }

  void removeFromQueueWhere(final bool Function(File) fn, final Error reason) {
    final List<String> uploadsToBeRemoved = [];
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.notStarted)
        .forEach((pendingUpload) {
      if (fn(pendingUpload.value.file)) {
        uploadsToBeRemoved.add(pendingUpload.key);
      }
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(reason);
    }
    _logger.info(
      'number of enteries removed from queue ${uploadsToBeRemoved.length}',
    );
    _totalCountInUploadSession -= uploadsToBeRemoved.length;
  }

  void _pollQueue() {
    if (SyncService.instance.shouldStopSync()) {
      clearQueue(SyncStopRequestedError());
    }
    if (_queue.isEmpty) {
      // Upload session completed
      _totalCountInUploadSession = 0;
      return;
    }
    if (_uploadCounter < kMaximumConcurrentUploads) {
      var pendingEntry = _queue.entries
          .firstWhereOrNull(
            (entry) => entry.value.status == UploadStatus.notStarted,
          )
          ?.value;

      if (pendingEntry != null &&
          pendingEntry.file.fileType == FileType.video &&
          _videoUploadCounter >= kMaximumConcurrentVideoUploads) {
        // check if there's any non-video entry which can be queued for upload
        pendingEntry = _queue.entries
            .firstWhereOrNull(
              (entry) =>
                  entry.value.status == UploadStatus.notStarted &&
                  entry.value.file.fileType != FileType.video,
            )
            ?.value;
      }
      if (pendingEntry != null) {
        pendingEntry.status = UploadStatus.inProgress;
        _encryptAndUploadFileToCollection(
          pendingEntry.file,
          pendingEntry.collectionID,
        );
      }
    }
  }

  Future<File?> _encryptAndUploadFileToCollection(
    File file,
    int collectionID, {
    bool forcedUpload = false,
  }) async {
    _uploadCounter++;
    if (file.fileType == FileType.video) {
      _videoUploadCounter++;
    }
    final localID = file.localID;
    try {
      final uploadedFile =
          await _tryToUpload(file, collectionID, forcedUpload).timeout(
        kFileUploadTimeout,
        onTimeout: () {
          final message = "Upload timed out for file " + file.toString();
          _logger.severe(message);
          throw TimeoutException(message);
        },
      );
      _queue.remove(localID).completer.complete(uploadedFile);
      return uploadedFile;
    } catch (e) {
      if (e is LockAlreadyAcquiredError) {
        _queue[localID].status = UploadStatus.inBackground;
        return _queue[localID].completer.future;
      } else {
        _queue.remove(localID).completer.completeError(e);
        return null;
      }
    } finally {
      _uploadCounter--;
      if (file.fileType == FileType.video) {
        _videoUploadCounter--;
      }
      _pollQueue();
    }
  }

  Future<void> checkNetworkForUpload({bool isForceUpload = false}) async {
    // Note: We don't support force uploading currently. During force upload,
    // network check is skipped completely
    if (isForceUpload) {
      return;
    }
    final connectivityResult = await (Connectivity().checkConnectivity());
    bool canUploadUnderCurrentNetworkConditions = true;
    if (connectivityResult == ConnectivityResult.mobile) {
      canUploadUnderCurrentNetworkConditions =
          Configuration.instance.shouldBackupOverMobileData();
    }
    if (!canUploadUnderCurrentNetworkConditions) {
      throw WiFiUnavailableError();
    }
  }

  Future<File> forceUpload(File file, int collectionID) async {
    return _tryToUpload(file, collectionID, true);
  }

  Future<File> _tryToUpload(
    File file,
    int collectionID,
    bool forcedUpload,
  ) async {
    await checkNetworkForUpload(isForceUpload: forcedUpload);
    if (!forcedUpload) {
      final fileOnDisk = await FilesDB.instance.getFile(file.generatedID!);
      final wasAlreadyUploaded = fileOnDisk != null &&
          fileOnDisk.uploadedFileID != null &&
          (fileOnDisk.updationTime ?? -1) != -1 &&
          (fileOnDisk.collectionID ?? -1) == collectionID;
      if (wasAlreadyUploaded) {
        debugPrint("File is already uploaded ${fileOnDisk.tag}");
        return fileOnDisk;
      }
    }
    if ((file.localID ?? '') == '') {
      _logger.severe('Trying to upload file with missing localID');
      return file;
    }

    final String lockKey = file.localID!;

    try {
      await _uploadLocks.acquireLock(
        lockKey,
        _processType.toString(),
        DateTime.now().microsecondsSinceEpoch,
      );
    } catch (e) {
      _logger.warning("Lock was already taken for " + file.toString());
      throw LockAlreadyAcquiredError();
    }

    final tempDirectory = Configuration.instance.getTempDirectory();
    final String uniqueID = const Uuid().v4().toString();
    final encryptedFilePath = '$tempDirectory${uniqueID}_file.encrypted';
    final encryptedThumbnailPath = '$tempDirectory${uniqueID}_thumb.encrypted';
    MediaUploadData? mediaUploadData;
    var uploadCompleted = false;
    // This flag is used to decide whether to clear the iOS origin file cache
    // or not.
    var uploadHardFailure = false;

    try {
      _logger.info(
        "Trying to upload " +
            file.toString() +
            ", isForced: " +
            forcedUpload.toString(),
      );
      try {
        mediaUploadData = await getUploadDataFromEnteFile(file);
      } catch (e) {
        if (e is InvalidFileError) {
          await _onInvalidFileError(file, e);
        } else {
          rethrow;
        }
      }

      Uint8List? key;
      final bool isUpdatedFile =
          file.uploadedFileID != null && file.updationTime == -1;
      if (isUpdatedFile) {
        _logger.info("File was updated " + file.toString());
        key = getFileKey(file);
      } else {
        key = null;
        // check if the file is already uploaded and can be mapped to existing
        // uploaded file. If map is found, it also returns the corresponding
        // mapped or update file entry.
        final result = await _mapToExistingUploadWithSameHash(
          mediaUploadData!,
          file,
          collectionID,
        );
        final isMappedToExistingUpload = result.item1;
        if (isMappedToExistingUpload) {
          debugPrint(
            "File success mapped to existing uploaded ${file.toString()}",
          );
          // return the mapped file
          return result.item2;
        }
      }

      if (io.File(encryptedFilePath).existsSync()) {
        await io.File(encryptedFilePath).delete();
      }
      await _checkIfWithinStorageLimit(mediaUploadData!.sourceFile!);
      final encryptedFile = io.File(encryptedFilePath);
      final EncryptionResult fileAttributes = await CryptoUtil.encryptFile(
        mediaUploadData!.sourceFile!.path,
        encryptedFilePath,
        key: key,
      );
      final thumbnailData = mediaUploadData.thumbnail;

      final EncryptionResult encryptedThumbnailData =
          await CryptoUtil.encryptChaCha(
        thumbnailData!,
        fileAttributes.key!,
      );
      if (io.File(encryptedThumbnailPath).existsSync()) {
        await io.File(encryptedThumbnailPath).delete();
      }
      final encryptedThumbnailFile = io.File(encryptedThumbnailPath);
      await encryptedThumbnailFile
          .writeAsBytes(encryptedThumbnailData.encryptedData!);

      final thumbnailUploadURL = await _getUploadURL();
      final String thumbnailObjectKey =
          await _putFile(thumbnailUploadURL, encryptedThumbnailFile);

      final fileUploadURL = await _getUploadURL();
      final String fileObjectKey = await _putFile(fileUploadURL, encryptedFile);

      final metadata = await file.getMetadataForUpload(mediaUploadData);
      final encryptedMetadataResult = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(metadata)) as Uint8List,
        fileAttributes.key!,
      );
      final fileDecryptionHeader =
          CryptoUtil.bin2base64(fileAttributes.header!);
      final thumbnailDecryptionHeader =
          CryptoUtil.bin2base64(encryptedThumbnailData.header!);
      final encryptedMetadata = CryptoUtil.bin2base64(
        encryptedMetadataResult.encryptedData!,
      );
      final metadataDecryptionHeader =
          CryptoUtil.bin2base64(encryptedMetadataResult.header!);
      if (SyncService.instance.shouldStopSync()) {
        throw SyncStopRequestedError();
      }
      File remoteFile;
      if (isUpdatedFile) {
        remoteFile = await _updateFile(
          file,
          fileObjectKey,
          fileDecryptionHeader,
          await encryptedFile.length(),
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          await encryptedThumbnailFile.length(),
          encryptedMetadata,
          metadataDecryptionHeader,
        );
        // Update across all collections
        await FilesDB.instance.updateUploadedFileAcrossCollections(remoteFile);
      } else {
        final encryptedFileKeyData = CryptoUtil.encryptSync(
          fileAttributes.key!,
          CollectionsService.instance.getCollectionKey(collectionID),
        );
        final encryptedKey =
            CryptoUtil.bin2base64(encryptedFileKeyData.encryptedData!);
        final keyDecryptionNonce =
            CryptoUtil.bin2base64(encryptedFileKeyData.nonce!);
        MetadataRequest? pubMetadataRequest;
        if ((mediaUploadData.height ?? 0) != 0 &&
            (mediaUploadData.width ?? 0) != 0) {
          final pubMetadata = {
            heightKey: mediaUploadData.height,
            widthKey: mediaUploadData.width
          };
          if (mediaUploadData.motionPhotoStartIndex != null) {
            pubMetadata[motionVideoIndexKey] =
                mediaUploadData.motionPhotoStartIndex;
          }
          pubMetadataRequest = await getPubMetadataRequest(
            file,
            pubMetadata,
            fileAttributes.key!,
          );
        }
        remoteFile = await _uploadFile(
          file,
          collectionID,
          encryptedKey,
          keyDecryptionNonce,
          fileAttributes,
          fileObjectKey,
          fileDecryptionHeader,
          await encryptedFile.length(),
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          await encryptedThumbnailFile.length(),
          encryptedMetadata,
          metadataDecryptionHeader,
          pubMetadata: pubMetadataRequest,
        );
        if (mediaUploadData.isDeleted) {
          _logger.info("File found to be deleted");
          remoteFile.localID = null;
        }
        await FilesDB.instance.update(remoteFile);
      }
      if (!_isBackground) {
        Bus.instance.fire(
          LocalPhotosUpdatedEvent(
            [remoteFile],
            source: "downloadComplete",
          ),
        );
      }
      _logger.info("File upload complete for " + remoteFile.toString());
      uploadCompleted = true;
      return remoteFile;
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError ||
          e is StorageLimitExceededError ||
          e is WiFiUnavailableError ||
          e is SilentlyCancelUploadsError ||
          e is FileTooLargeForPlanError)) {
        _logger.severe("File upload failed for " + file.toString(), e, s);
      }
      if ((e is StorageLimitExceededError ||
          e is FileTooLargeForPlanError ||
          e is NoActiveSubscriptionError)) {
        // file upload can be be retried in such cases without user intervention
        uploadHardFailure = false;
      }
      rethrow;
    } finally {
      await _onUploadDone(
        mediaUploadData,
        uploadCompleted,
        uploadHardFailure,
        file,
        encryptedFilePath,
        encryptedThumbnailPath,
        lockKey: lockKey,
      );
    }
  }

  /*
  _mapToExistingUpload links the fileToUpload with the existing uploaded
  files. if the link is successful, it returns true otherwise false.
  When false, we should go ahead and re-upload or update the file.
  It performs following checks:
    a) Uploaded file with same localID and destination collection. Delete the
     fileToUpload entry
    b) Uploaded file in any collection but with missing localID.
     Update the localID for uploadedFile and delete the fileToUpload entry
    c) A uploaded file exist with same localID but in a different collection.
    Add a symlink in the destination collection and update the fileToUpload
    d) File already exists but different localID. Re-upload
    In case the existing files already have local identifier, which is
    different from the {fileToUpload}, then most probably device has
    duplicate files.
  */
  Future<Tuple2<bool, File>> _mapToExistingUploadWithSameHash(
    MediaUploadData mediaUploadData,
    File fileToUpload,
    int toCollectionID,
  ) async {
    if (fileToUpload.uploadedFileID != null) {
      // ideally this should never happen, but because the code below this case
      // can do unexpected mapping, we are adding this additional check
      _logger.severe(
        'Critical: file is already uploaded, skipped mapping',
      );
      return Tuple2(false, fileToUpload);
    }

    final List<File> existingUploadedFiles =
        await FilesDB.instance.getUploadedFilesWithHashes(
      mediaUploadData.hashData!,
      fileToUpload.fileType,
      Configuration.instance.getUserID()!,
    );
    if (existingUploadedFiles.isEmpty) {
      // continueUploading this file
      return Tuple2(false, fileToUpload);
    }

    // case a
    final File? sameLocalSameCollection =
        existingUploadedFiles.firstWhereOrNull(
      (e) =>
          e.collectionID == toCollectionID && e.localID == fileToUpload.localID,
    );
    if (sameLocalSameCollection != null) {
      _logger.fine(
        "sameLocalSameCollection: \n toUpload  ${fileToUpload.tag} "
        "\n existing: ${sameLocalSameCollection.tag}",
      );
      // should delete the fileToUploadEntry
      if (fileToUpload.generatedID != null) {
        await FilesDB.instance.deleteByGeneratedID(fileToUpload.generatedID!);
      }

      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          [fileToUpload],
          type: EventType.deletedFromEverywhere,
          source: "sameLocalSameCollection", //
        ),
      );
      return Tuple2(true, sameLocalSameCollection);
    }

    // case b
    final File? fileMissingLocal = existingUploadedFiles.firstWhereOrNull(
      (e) => e.localID == null,
    );
    if (fileMissingLocal != null) {
      // update the local id of the existing file and delete the fileToUpload
      // entry
      _logger.fine(
        "fileMissingLocal: \n toUpload  ${fileToUpload.tag} "
        "\n existing: ${fileMissingLocal.tag}",
      );
      fileMissingLocal.localID = fileToUpload.localID;
      // set localID for the given uploadedID across collections
      await FilesDB.instance.updateLocalIDForUploaded(
        fileMissingLocal.uploadedFileID!,
        fileToUpload.localID!,
      );
      // For files selected from device, during collaborative upload, we don't
      // insert entries in the FilesDB. So, we don't need to delete the entry
      if (fileToUpload.generatedID != null) {
        await FilesDB.instance.deleteByGeneratedID(fileToUpload.generatedID!);
      }
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          [fileToUpload],
          source: "fileMissingLocal",
          type: EventType.deletedFromEverywhere, //
        ),
      );
      return Tuple2(true, fileMissingLocal);
    }

    // case c
    final File? fileExistsButDifferentCollection =
        existingUploadedFiles.firstWhereOrNull(
      (e) =>
          e.collectionID != toCollectionID && e.localID == fileToUpload.localID,
    );
    if (fileExistsButDifferentCollection != null) {
      _logger.fine(
        "fileExistsButDifferentCollection: \n toUpload  ${fileToUpload.tag} "
        "\n existing: ${fileExistsButDifferentCollection.tag}",
      );
      final linkedFile = await CollectionsService.instance
          .linkLocalFileToExistingUploadedFileInAnotherCollection(
        toCollectionID,
        localFileToUpload: fileToUpload,
        existingUploadedFile: fileExistsButDifferentCollection,
      );
      return Tuple2(true, linkedFile);
    }
    final Set<String> matchLocalIDs = existingUploadedFiles
        .where(
          (e) => e.localID != null,
        )
        .map((e) => e.localID!)
        .toSet();
    _logger.fine(
      "Found hashMatch but probably with diff localIDs "
      "$matchLocalIDs",
    );
    // case d
    return Tuple2(false, fileToUpload);
  }

  Future<void> _onUploadDone(
    MediaUploadData? mediaUploadData,
    bool uploadCompleted,
    bool uploadHardFailure,
    File file,
    String encryptedFilePath,
    String encryptedThumbnailPath, {
    required String lockKey,
  }) async {
    if (mediaUploadData != null && mediaUploadData.sourceFile != null) {
      // delete the file from app's internal cache if it was copied to app
      // for upload. On iOS, only remove the file from photo_manager/app cache
      // when upload is either completed or there's a tempFailure
      // Shared Media should only be cleared when the upload
      // succeeds.
      if ((io.Platform.isIOS && (uploadCompleted || uploadHardFailure)) ||
          (uploadCompleted && file.isSharedMediaToAppSandbox)) {
        await mediaUploadData.sourceFile?.delete();
      }
    }
    if (io.File(encryptedFilePath).existsSync()) {
      await io.File(encryptedFilePath).delete();
    }
    if (io.File(encryptedThumbnailPath).existsSync()) {
      await io.File(encryptedThumbnailPath).delete();
    }
    await _uploadLocks.releaseLock(lockKey, _processType.toString());
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
  Future<void> _checkIfWithinStorageLimit(io.File fileToBeUploaded) async {
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
        _logger.warning('Storage limit exceeded fileSize $fileSize and '
            'freeStorage $freeStorage');
        throw StorageLimitExceededError();
      }
    } catch (e) {
      if (e is StorageLimitExceededError) {
        rethrow;
      } else {
        _logger.severe('Error checking storage limit', e);
      }
    }
  }

  Future _onInvalidFileError(File file, InvalidFileError e) async {
    final String ext = file.title == null ? "no title" : extension(file.title!);
    _logger.severe(
      "Invalid file: (ext: $ext) encountered: " + file.toString(),
      e,
    );
    await FilesDB.instance.deleteLocalFile(file);
    await LocalSyncService.instance.trackInvalidFile(file);
    throw e;
  }

  Future<File> _uploadFile(
    File file,
    int collectionID,
    String encryptedKey,
    String keyDecryptionNonce,
    EncryptionResult fileAttributes,
    String fileObjectKey,
    String fileDecryptionHeader,
    int fileSize,
    String thumbnailObjectKey,
    String thumbnailDecryptionHeader,
    int thumbnailSize,
    String encryptedMetadata,
    String metadataDecryptionHeader, {
    MetadataRequest? pubMetadata,
    int attempt = 1,
  }) async {
    final request = {
      "collectionID": collectionID,
      "encryptedKey": encryptedKey,
      "keyDecryptionNonce": keyDecryptionNonce,
      "file": {
        "objectKey": fileObjectKey,
        "decryptionHeader": fileDecryptionHeader,
        "size": fileSize,
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "decryptionHeader": thumbnailDecryptionHeader,
        "size": thumbnailSize,
      },
      "metadata": {
        "encryptedData": encryptedMetadata,
        "decryptionHeader": metadataDecryptionHeader,
      }
    };
    if (pubMetadata != null) {
      request["pubMagicMetadata"] = pubMetadata;
    }
    try {
      final response = await _enteDio.post("/files", data: request);
      final data = response.data;
      file.uploadedFileID = data["id"];
      file.collectionID = collectionID;
      file.updationTime = data["updationTime"];
      file.ownerID = data["ownerID"];
      file.encryptedKey = encryptedKey;
      file.keyDecryptionNonce = keyDecryptionNonce;
      file.fileDecryptionHeader = fileDecryptionHeader;
      file.thumbnailDecryptionHeader = thumbnailDecryptionHeader;
      file.metadataDecryptionHeader = metadataDecryptionHeader;
      return file;
    } on DioError catch (e) {
      if (e.response?.statusCode == 413) {
        throw FileTooLargeForPlanError();
      } else if (e.response?.statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts) {
        _logger.info("Upload file failed, will retry in 3 seconds");
        await Future.delayed(const Duration(seconds: 3));
        return _uploadFile(
          file,
          collectionID,
          encryptedKey,
          keyDecryptionNonce,
          fileAttributes,
          fileObjectKey,
          fileDecryptionHeader,
          fileSize,
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          thumbnailSize,
          encryptedMetadata,
          metadataDecryptionHeader,
          attempt: attempt + 1,
          pubMetadata: pubMetadata,
        );
      }
      rethrow;
    }
  }

  Future<File> _updateFile(
    File file,
    String fileObjectKey,
    String fileDecryptionHeader,
    int fileSize,
    String thumbnailObjectKey,
    String thumbnailDecryptionHeader,
    int thumbnailSize,
    String encryptedMetadata,
    String metadataDecryptionHeader, {
    int attempt = 1,
  }) async {
    final request = {
      "id": file.uploadedFileID,
      "file": {
        "objectKey": fileObjectKey,
        "decryptionHeader": fileDecryptionHeader,
        "size": fileSize,
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "decryptionHeader": thumbnailDecryptionHeader,
        "size": thumbnailSize,
      },
      "metadata": {
        "encryptedData": encryptedMetadata,
        "decryptionHeader": metadataDecryptionHeader,
      }
    };
    try {
      final response = await _enteDio.put("/files/update", data: request);
      final data = response.data;
      file.uploadedFileID = data["id"];
      file.updationTime = data["updationTime"];
      file.fileDecryptionHeader = fileDecryptionHeader;
      file.thumbnailDecryptionHeader = thumbnailDecryptionHeader;
      file.metadataDecryptionHeader = metadataDecryptionHeader;
      return file;
    } on DioError catch (e) {
      if (e.response?.statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts) {
        _logger.info("Update file failed, will retry in 3 seconds");
        await Future.delayed(const Duration(seconds: 3));
        return _updateFile(
          file,
          fileObjectKey,
          fileDecryptionHeader,
          fileSize,
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          thumbnailSize,
          encryptedMetadata,
          metadataDecryptionHeader,
          attempt: attempt + 1,
        );
      }
      rethrow;
    }
  }

  Future<UploadURL> _getUploadURL() async {
    if (_uploadURLs.isEmpty) {
      // the queue is empty, fetch at least for one file to handle force uploads
      // that are not in the queue. This is to also avoid
      await fetchUploadURLs(max(_queue.length, 1));
    }
    try {
      return _uploadURLs.removeFirst();
    } catch (e) {
      if (e is StateError && e.message == 'No element' && _queue.isEmpty) {
        _logger.warning("Oops, uploadUrls has no element now, fetching again");
        return _getUploadURL();
      } else {
        rethrow;
      }
    }
  }

  Future<void>? _uploadURLFetchInProgress;

  Future<void> fetchUploadURLs(int fileCount) async {
    _uploadURLFetchInProgress ??= Future<void>(() async {
      try {
        final response = await _enteDio.get(
          "/files/upload-urls",
          queryParameters: {
            "count": min(42, fileCount * 2), // m4gic number
          },
        );
        final urls = (response.data["urls"] as List)
            .map((e) => UploadURL.fromMap(e))
            .toList();
        _uploadURLs.addAll(urls);
      } on DioError catch (e, s) {
        if (e.response != null) {
          if (e.response!.statusCode == 402) {
            final error = NoActiveSubscriptionError();
            clearQueue(error);
            throw error;
          } else if (e.response!.statusCode == 426) {
            final error = StorageLimitExceededError();
            clearQueue(error);
            throw error;
          } else {
            _logger.severe("Could not fetch upload URLs", e, s);
          }
        }
        rethrow;
      } finally {
        _uploadURLFetchInProgress = null;
      }
    });
    return _uploadURLFetchInProgress;
  }

  void _onStorageLimitExceeded() {
    clearQueue(StorageLimitExceededError());
    throw StorageLimitExceededError();
  }

  Future<String> _putFile(
    UploadURL uploadURL,
    io.File file, {
    int? contentLength,
    int attempt = 1,
  }) async {
    final fileSize = contentLength ?? await file.length();
    _logger.info(
      "Putting object for " +
          file.toString() +
          " of size: " +
          fileSize.toString(),
    );
    final startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      await _dio.put(
        uploadURL.url,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileSize,
          },
        ),
      );
      _logger.info(
        "Upload speed : " +
            (fileSize / (DateTime.now().millisecondsSinceEpoch - startTime))
                .toString() +
            " kilo bytes per second",
      );

      return uploadURL.objectKey;
    } on DioError catch (e) {
      if (e.message.startsWith(
            "HttpException: Content size exceeds specified contentLength.",
          ) &&
          attempt == 1) {
        return _putFile(
          uploadURL,
          file,
          contentLength: (await file.readAsBytes()).length,
          attempt: 2,
        );
      } else if (attempt < kMaximumUploadAttempts) {
        final newUploadURL = await _getUploadURL();
        return _putFile(
          newUploadURL,
          file,
          contentLength: (await file.readAsBytes()).length,
          attempt: attempt + 1,
        );
      } else {
        _logger.info(
          "Upload failed for file with size " + fileSize.toString(),
          e,
        );
        rethrow;
      }
    }
  }

  Future<void> _pollBackgroundUploadStatus() async {
    final blockedUploads = _queue.entries
        .where((e) => e.value.status == UploadStatus.inBackground)
        .toList();
    for (final upload in blockedUploads) {
      final file = upload.value.file;
      final isStillLocked = await _uploadLocks.isLocked(
        file.localID,
        ProcessType.background.toString(),
      );
      if (!isStillLocked) {
        final completer = _queue.remove(upload.key).completer;
        final dbFile =
            await FilesDB.instance.getFile(upload.value.file.generatedID);
        if (dbFile?.uploadedFileID != null) {
          _logger.info("Background upload success detected");
          completer.complete(dbFile);
        } else {
          _logger.info("Background upload failure detected");
          completer.completeError(SilentlyCancelUploadsError());
        }
      }
    }
    Future.delayed(kBlockedUploadsPollFrequency, () async {
      await _pollBackgroundUploadStatus();
    });
  }
}

class FileUploadItem {
  final File file;
  final int collectionID;
  final Completer<File> completer;
  UploadStatus status;

  FileUploadItem(
    this.file,
    this.collectionID,
    this.completer, {
    this.status = UploadStatus.notStarted,
  });
}

enum UploadStatus {
  notStarted,
  inProgress,
  inBackground,
  completed,
}

enum ProcessType {
  background,
  foreground,
}
