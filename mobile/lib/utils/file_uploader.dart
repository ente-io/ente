import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import "package:permission_handler/permission_handler.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import "package:photos/events/file_uploaded_event.dart";
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/encryption_result.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
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
import "package:photos/utils/file_util.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import "package:uuid/uuid.dart";

class FileUploader {
  static const kMaximumConcurrentUploads = 4;
  static const kMaximumConcurrentVideoUploads = 2;
  static const kMaximumThumbnailCompressionAttempts = 2;
  static const kMaximumUploadAttempts = 4;
  static const kMaxFileSize5Gib = 5368709120;
  static const kBlockedUploadsPollFrequency = Duration(seconds: 2);
  static const kFileUploadTimeout = Duration(minutes: 50);
  static const k20MBStorageBuffer = 20 * 1024 * 1024;
  static const kUploadTempPrefix = "upload_file_";

  final _logger = Logger("FileUploader");
  final _dio = NetworkClient.instance.getDio();
  final _enteDio = NetworkClient.instance.enteDio;
  final LinkedHashMap<String, FileUploadItem> _queue =
      LinkedHashMap<String, FileUploadItem>();
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

  // _hasInitiatedForceUpload is used to track if user attempted force upload
  // where files are uploaded directly (without adding them to DB). In such
  // cases, we don't want to clear the stale upload files. See #removeStaleFiles
  // as it can result in clearing files which are still being force uploaded.
  bool _hasInitiatedForceUpload = false;

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
      // ignore: unawaited_futures
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
          InvalidFileError(
            "File already deleted",
            InvalidReason.assetDeletedEvent,
          ),
        );
      }
    });
  }

  // upload future will return null as File when the file entry is deleted
  // locally because it's already present in the destination collection.
  Future<EnteFile> upload(EnteFile file, int collectionID) {
    if (file.localID == null || file.localID!.isEmpty) {
      return Future.error(Exception("file's localID can not be null or empty"));
    }
    // If the file hasn't been queued yet, queue it for upload
    _totalCountInUploadSession++;
    final String localID = file.localID!;
    if (!_queue.containsKey(localID)) {
      final completer = Completer<EnteFile>();
      _queue[localID] = FileUploadItem(file, collectionID, completer);
      _pollQueue();
      return completer.future;
    }
    // If the file exists in the queue for a matching collectionID,
    // return the existing future
    final FileUploadItem item = _queue[localID]!;
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

      return CollectionsService.instance
          .addToCollection(collectionID, [uploadedFile]).then((aVoid) {
        return uploadedFile;
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
      _queue.remove(id)?.completer.completeError(reason);
    }
    _totalCountInUploadSession = 0;
  }

  void clearCachedUploadURLs() {
    _uploadURLs.clear();
  }

  void removeFromQueueWhere(
    final bool Function(EnteFile) fn,
    final Error reason,
  ) {
    final List<String> uploadsToBeRemoved = [];
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.notStarted)
        .forEach((pendingUpload) {
      if (fn(pendingUpload.value.file)) {
        uploadsToBeRemoved.add(pendingUpload.key);
      }
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id)?.completer.completeError(reason);
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

  Future<EnteFile?> _encryptAndUploadFileToCollection(
    EnteFile file,
    int collectionID, {
    bool forcedUpload = false,
  }) async {
    _uploadCounter++;
    if (file.fileType == FileType.video) {
      _videoUploadCounter++;
    }
    final localID = file.localID!;
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
      _queue.remove(localID)!.completer.complete(uploadedFile);
      return uploadedFile;
    } catch (e) {
      if (e is LockAlreadyAcquiredError) {
        _queue[localID]!.status = UploadStatus.inBackground;
        return _queue[localID]!.completer.future;
      } else {
        _queue.remove(localID)!.completer.completeError(e);
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

  Future<void> removeStaleFiles() async {
    if (_hasInitiatedForceUpload) {
      _logger.info(
        "Force upload was initiated, skipping stale file cleanup",
      );
      return;
    }
    try {
      final String dir = Configuration.instance.getTempDirectory();
      // delete all files in the temp directory that start with upload_ and
      // ends with .encrypted. Fetch files in async manner
      final files = await Directory(dir).list().toList();
      final filesToDelete = files.where((file) {
        return file.path.contains(kUploadTempPrefix) &&
            file.path.contains(".encrypted");
      });
      if (filesToDelete.isNotEmpty) {
        _logger.info('cleaning up state files ${filesToDelete.length}');
        for (final file in filesToDelete) {
          await file.delete();
        }
      }

      if (Platform.isAndroid) {
        final sharedMediaDir =
            Configuration.instance.getSharedMediaDirectory() + "/";
        final sharedFiles = await Directory(sharedMediaDir).list().toList();
        if (sharedFiles.isNotEmpty) {
          _logger.info('Shared media directory cleanup ${sharedFiles.length}');
          final int ownerID = Configuration.instance.getUserID()!;
          final existingLocalFileIDs =
              await FilesDB.instance.getExistingLocalFileIDs(ownerID);
          final Set<String> trackedSharedFilePaths = {};
          for (String localID in existingLocalFileIDs) {
            if (localID.contains(sharedMediaIdentifier)) {
              trackedSharedFilePaths
                  .add(getSharedMediaPathFromLocalID(localID));
            }
          }
          for (final file in sharedFiles) {
            if (!trackedSharedFilePaths.contains(file.path)) {
              _logger.info('Deleting stale shared media file ${file.path}');
              await file.delete();
            }
          }
        }
      }
    } catch (e, s) {
      _logger.severe("Failed to remove stale files", e, s);
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

  Future<void> verifyMediaLocationAccess() async {
    if (Platform.isAndroid) {
      final bool hasPermission = await Permission.accessMediaLocation.isGranted;
      if (!hasPermission) {
        throw NoMediaLocationAccessError();
      }
    }
  }

  Future<EnteFile> forceUpload(EnteFile file, int collectionID) async {
    _hasInitiatedForceUpload = true;
    return _tryToUpload(file, collectionID, true);
  }

  Future<EnteFile> _tryToUpload(
    EnteFile file,
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
    final encryptedFilePath =
        '$tempDirectory$kUploadTempPrefix${uniqueID}_file.encrypted';
    final encryptedThumbnailPath =
        '$tempDirectory$kUploadTempPrefix${uniqueID}_thumb.encrypted';
    MediaUploadData? mediaUploadData;
    var uploadCompleted = false;
    // This flag is used to decide whether to clear the iOS origin file cache
    // or not.
    var uploadHardFailure = false;

    try {
      final bool isUpdatedFile =
          file.uploadedFileID != null && file.updationTime == -1;
      _logger.info(
        'starting ${forcedUpload ? 'forced' : ''} '
        '${isUpdatedFile ? 're-upload' : 'upload'} of ${file.toString()}',
      );

      mediaUploadData = await getUploadDataFromEnteFile(file);

      Uint8List? key;
      if (isUpdatedFile) {
        key = getFileKey(file);
      } else {
        key = null;
        // check if the file is already uploaded and can be mapped to existing
        // uploaded file. If map is found, it also returns the corresponding
        // mapped or update file entry.
        final result = await _mapToExistingUploadWithSameHash(
          mediaUploadData,
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

      if (File(encryptedFilePath).existsSync()) {
        await File(encryptedFilePath).delete();
      }
      await _checkIfWithinStorageLimit(mediaUploadData.sourceFile!);
      final encryptedFile = File(encryptedFilePath);
      final EncryptionResult fileAttributes = await CryptoUtil.encryptFile(
        mediaUploadData.sourceFile!.path,
        encryptedFilePath,
        key: key,
      );
      late final Uint8List? thumbnailData;
      if (mediaUploadData.thumbnail == null &&
          file.fileType == FileType.video) {
        thumbnailData = base64Decode(blackThumbnailBase64);
      } else {
        thumbnailData = mediaUploadData.thumbnail;
      }

      final EncryptionResult encryptedThumbnailData =
          await CryptoUtil.encryptChaCha(
        thumbnailData!,
        fileAttributes.key!,
      );
      if (File(encryptedThumbnailPath).existsSync()) {
        await File(encryptedThumbnailPath).delete();
      }
      final encryptedThumbnailFile = File(encryptedThumbnailPath);
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
      EnteFile remoteFile;
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
        final Map<String, dynamic> pubMetadata = {};
        MetadataRequest? pubMetadataRequest;
        if ((mediaUploadData.height ?? 0) != 0 &&
            (mediaUploadData.width ?? 0) != 0) {
          pubMetadata[heightKey] = mediaUploadData.height;
          pubMetadata[widthKey] = mediaUploadData.width;
        }
        if (mediaUploadData.motionPhotoStartIndex != null) {
          pubMetadata[motionVideoIndexKey] =
              mediaUploadData.motionPhotoStartIndex;
        }
        if (mediaUploadData.thumbnail == null) {
          pubMetadata[noThumbKey] = true;
        }
        if (pubMetadata.isNotEmpty) {
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
      Bus.instance.fire(FileUploadedEvent(remoteFile));
      return remoteFile;
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError ||
          e is StorageLimitExceededError ||
          e is WiFiUnavailableError ||
          e is SilentlyCancelUploadsError ||
          e is InvalidFileError ||
          e is FileTooLargeForPlanError)) {
        _logger.severe("File upload failed for " + file.toString(), e, s);
      }
      if (e is InvalidFileError) {
        _logger.severe("File upload ignored for " + file.toString(), e);
        await _onInvalidFileError(file, e);
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
  Future<Tuple2<bool, EnteFile>> _mapToExistingUploadWithSameHash(
    MediaUploadData mediaUploadData,
    EnteFile fileToUpload,
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

    final List<EnteFile> existingUploadedFiles =
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
    final EnteFile? sameLocalSameCollection =
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
    final EnteFile? fileMissingLocal = existingUploadedFiles.firstWhereOrNull(
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
    final EnteFile? fileExistsButDifferentCollection =
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
    EnteFile file,
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
      if ((Platform.isIOS && (uploadCompleted || uploadHardFailure)) ||
          (uploadCompleted && file.isSharedMediaToAppSandbox)) {
        await mediaUploadData.sourceFile?.delete();
      }
    }
    if (File(encryptedFilePath).existsSync()) {
      await File(encryptedFilePath).delete();
    }
    if (File(encryptedThumbnailPath).existsSync()) {
      await File(encryptedThumbnailPath).delete();
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
  Future<void> _checkIfWithinStorageLimit(File fileToBeUploaded) async {
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
      if (fileSize > kMaxFileSize5Gib) {
        _logger.warning('File size exceeds 5GiB fileSize $fileSize');
        throw InvalidFileError(
          'file size above 5GiB',
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

  Future _onInvalidFileError(EnteFile file, InvalidFileError e) async {
    try {
      final bool canIgnoreFile = file.localID != null &&
          file.deviceFolder != null &&
          file.title != null &&
          !file.isSharedMediaToAppSandbox;
      // If the file is not uploaded yet and either it can not be ignored or the
      // err is related to live photo media, delete the local entry
      final bool deleteEntry =
          !file.isUploaded && (!canIgnoreFile || e.reason.isLivePhotoErr);

      if (e.reason != InvalidReason.thumbnailMissing || !canIgnoreFile) {
        _logger.severe(
          "Invalid file, localDelete: $deleteEntry, ignored: $canIgnoreFile",
          e,
        );
      }
      if (deleteEntry) {
        await FilesDB.instance.deleteLocalFile(file);
      }
      if (canIgnoreFile) {
        await LocalSyncService.instance.ignoreUpload(file, e);
      }
    } catch (e, s) {
      _logger.severe("Failed to handle invalid file error", e, s);
    }
  }

  Future<EnteFile> _uploadFile(
    EnteFile file,
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
      },
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

  Future<EnteFile> _updateFile(
    EnteFile file,
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
      },
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
    File file, {
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
        file.localID!,
        ProcessType.background.toString(),
      );
      if (!isStillLocked) {
        final completer = _queue.remove(upload.key)?.completer;
        final dbFile =
            await FilesDB.instance.getFile(upload.value.file.generatedID!);
        if (dbFile?.uploadedFileID != null) {
          _logger.info("Background upload success detected");
          completer?.complete(dbFile);
        } else {
          _logger.info("Background upload failure detected");
          completer?.completeError(SilentlyCancelUploadsError());
        }
      }
    }
    Future.delayed(kBlockedUploadsPollFrequency, () async {
      await _pollBackgroundUploadStatus();
    });
  }
}

class FileUploadItem {
  final EnteFile file;
  final int collectionID;
  final Completer<EnteFile> completer;
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
