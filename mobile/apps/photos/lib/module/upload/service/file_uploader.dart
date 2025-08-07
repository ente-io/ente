import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import "package:path/path.dart";
import "package:permission_handler/permission_handler.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/db/local/table/upload_queue_table.dart";
import 'package:photos/db/upload_locks_db.dart';
import "package:photos/events/backup_updated_event.dart";
import "package:photos/events/file_uploaded_event.dart";
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/main.dart';
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/metadata.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/models/local/asset_upload_queue.dart";
import "package:photos/module/upload/model/item.dart";
import "package:photos/module/upload/model/media.dart";
import "package:photos/module/upload/model/update_response.dart";
import 'package:photos/module/upload/model/upload_url.dart';
import 'package:photos/module/upload/service/file_upload_metadata.dart';
import "package:photos/module/upload/service/media.dart";
import "package:photos/module/upload/service/multipart.dart";
import "package:photos/module/upload/service/pre_upload_check.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/local/shared_assert.service.dart";
import 'package:photos/services/sync/sync_service.dart';
import "package:photos/utils/file_key.dart";
import "package:photos/utils/network_util.dart";
import 'package:photos/utils/standalone/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:uuid/uuid.dart";

class FileUploader {
  static const kMaximumConcurrentUploads = 4;
  static const kMaximumConcurrentVideoUploads = 2;
  static const kMaximumThumbnailCompressionAttempts = 2;
  static const kMaximumUploadAttempts = 4;

  static const kBlockedUploadsPollFrequency = Duration(seconds: 2);
  static const kFileUploadTimeout = Duration(minutes: 50);

  static const _lastStaleFileCleanupTime = "lastStaleFileCleanupTime";

  final _logger = Logger("FileUploader");
  final _dio = NetworkClient.instance.getDio();
  final _enteDio = NetworkClient.instance.enteDio;
  final LinkedHashMap<String, FileUploadItem> _queue =
      LinkedHashMap<String, FileUploadItem>();
  final LinkedHashMap<String, BackupItem> _allBackups =
      LinkedHashMap<String, BackupItem>();
  final _uploadLocks = UploadLocksDB.instance;
  final kSafeBufferForLockExpiry = const Duration(hours: 4).inMicroseconds;
  final kBGTaskDeathTimeout = const Duration(seconds: 5).inMicroseconds;
  final _uploadURLs = Queue<UploadURL>();

  LinkedHashMap<String, BackupItem> get allBackups => _allBackups;

  // Maintains the count of files in the current upload session.
  // Upload session is the period between the first entry into the _queue and last entry out of the _queue
  int _totalCountInUploadSession = 0;

  // _uploadCounter indicates number of uploads which are currently in progress
  int _uploadCounter = 0;
  int _videoUploadCounter = 0;
  late ProcessType _processType;
  late SharedPreferences _prefs;

  // _hasInitiatedForceUpload is used to track if user attempted force upload
  // where files are uploaded directly (without adding them to DB). In such
  // cases, we don't want to clear the stale upload files. See #removeStaleFiles
  // as it can result in clearing files which are still being force uploaded.
  final bool _hasInitiatedForceUpload = false;
  late MultiPartUploader _multiPartUploader;

  FileUploader._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploadURLFetchInProgress = null;
    });
  }

  static FileUploader instance = FileUploader._privateConstructor();

  Future<void> init(SharedPreferences preferences, bool isBackground) async {
    _prefs = preferences;
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
      final lastBGTaskHeartBeatTime =
          _prefs.getInt(kLastBGTaskHeartBeatTime) ?? 0;
      final isBGTaskDead =
          lastBGTaskHeartBeatTime < (currentTime - kBGTaskDeathTimeout);
      if (isBGTaskDead) {
        await _uploadLocks.releaseLocksAcquiredByOwnerBefore(
          ProcessType.background.toString(),
          currentTime,
        );
        _logger.info("BG task was found dead, cleared all locks");
      } else {
        _logger.info(
          "BG task is alive, not clearing locks ${DateTime.fromMicrosecondsSinceEpoch(lastBGTaskHeartBeatTime)}",
        );
      }
      // ignore: unawaited_futures
      _pollBackgroundUploadStatus();
    }
    _multiPartUploader = MultiPartUploader(
      _enteDio,
      _dio,
      UploadLocksDB.instance,
      flagService,
    );
    if (currentTime - (_prefs.getInt(_lastStaleFileCleanupTime) ?? 0) >
        tempDirCleanUpInterval) {
      await removeStaleFiles();
      await _prefs.setInt(_lastStaleFileCleanupTime, currentTime);
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
  Future<EnteFile> upload(
    EnteFile file,
    int uploadCollectionID, {
    AssetUploadQueue? queue,
  }) async {
    if (file.lAsset == null) {
      return Future.error(Exception("file's localID can not be null or empty"));
    }
    // If the file hasn't been queued yet, queue it for upload
    _totalCountInUploadSession++;
    final String uploadKey = file.lAsset!.id;
    if (!_queue.containsKey(uploadKey)) {
      final completer = Completer<EnteFile>();
      _queue[uploadKey] = FileUploadItem(
        file,
        uploadCollectionID,
        completer,
        assetQueue: queue!,
      );
      _allBackups[uploadKey] = BackupItem(
        status: BackupItemStatus.inQueue,
        file: file,
        collectionID: uploadCollectionID,
        completer: completer,
      );
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
      _pollQueue();
      return completer.future;
    }
    // If the file exists in the queue for a matching collectionID,
    // return the existing future
    final FileUploadItem item = _queue[uploadKey]!;
    if (item.collectionID == uploadCollectionID) {
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

      return CollectionsService.instance.addOrCopyToCollection(
        uploadCollectionID,
        [uploadedFile],
      ).then((aVoid) {
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
      _allBackups[id] = _allBackups[id]!.copyWith(
        status: BackupItemStatus.retry,
        error: reason,
      );
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
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
      _allBackups[id] = _allBackups[id]!
          .copyWith(status: BackupItemStatus.retry, error: reason);
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
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
        _allBackups[pendingEntry.file.localID!] =
            _allBackups[pendingEntry.file.localID]!
                .copyWith(status: BackupItemStatus.uploading);
        Bus.instance.fire(BackupUpdatedEvent(_allBackups));
        _encryptAndUploadFileToCollection(
          pendingEntry,
          pendingEntry.collectionID,
        );
      }
    }
  }

  Future<void> _encryptAndUploadFileToCollection(
    FileUploadItem item,
    int collectionID,
  ) async {
    final EnteFile file = item.file;
    _uploadCounter++;
    if (file.fileType == FileType.video) {
      _videoUploadCounter++;
    }
    final uploadLockID = file.lAsset!.id;
    try {
      final uploadedFile = await _tryToUpload(
        file,
        collectionID,
        item.assetQueue?.manual ?? false,
      ).timeout(
        kFileUploadTimeout,
        onTimeout: () {
          final message = "Upload timed out for file " + file.toString();
          _logger.warning(message);
          throw TimeoutException(message);
        },
      );
      if (item.assetQueue != null) {
        await localDB.delete(item.assetQueue!);
      }
      _queue.remove(uploadLockID)!.completer.complete(uploadedFile);
      _allBackups[uploadLockID] = _allBackups[uploadLockID]!
          .copyWith(status: BackupItemStatus.uploaded);
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
    } catch (e) {
      if (e is LockAlreadyAcquiredError) {
        _queue[uploadLockID]!.status = UploadStatus.inBackground;
        _allBackups[uploadLockID] = _allBackups[uploadLockID]!
            .copyWith(status: BackupItemStatus.inBackground);
        Bus.instance.fire(BackupUpdatedEvent(_allBackups));
      } else {
        _queue.remove(uploadLockID)!.completer.completeError(e);
        _allBackups[uploadLockID] = _allBackups[uploadLockID]!
            .copyWith(status: BackupItemStatus.retry, error: e);
        Bus.instance.fire(BackupUpdatedEvent(_allBackups));
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
        return file.path.contains(uploadTempFilePrefix) &&
            file.path.contains(".encrypted");
      });
      if (filesToDelete.isNotEmpty) {
        _logger.info('Deleting ${filesToDelete.length} stale upload files ');
        final fileNameToLastAttempt =
            await _uploadLocks.getFileNameToLastAttemptedAtMap();
        for (final file in filesToDelete) {
          final fileName = file.path.split('/').last;
          final lastAttemptTime = fileNameToLastAttempt[fileName] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  fileNameToLastAttempt[fileName]!,
                )
              : null;
          if (lastAttemptTime == null ||
              DateTime.now().difference(lastAttemptTime).inDays > 1) {
            await file.delete();
          } else {
            _logger.info(
              'Skipping file $fileName as it was attempted recently on $lastAttemptTime',
            );
          }
        }
      }

      if (Platform.isAndroid) {
        await SharedAssetService.cleanUpUntrackedItems();
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
    final canUploadUnderCurrentNetworkConditions = await canUseHighBandwidth();

    if (!canUploadUnderCurrentNetworkConditions) {
      throw WiFiUnavailableError();
    }
  }

  Future<void> verifyMediaLocationAccess() async {
    if (Platform.isAndroid) {
      final bool hasPermission = await Permission.accessMediaLocation.isGranted;
      if (!hasPermission) {
        final permissionStatus = await Permission.accessMediaLocation.request();
        if (!permissionStatus.isGranted) {
          _logger.severe(
            "Media location access denied with permission status: ${permissionStatus.name}",
          );
          throw NoMediaLocationAccessError();
        }
      }
    }
  }

  Future<EnteFile> _tryToUpload(
    EnteFile file,
    int collectionID,
    bool forcedUpload,
  ) async {
    await checkNetworkForUpload(isForceUpload: forcedUpload);
    final String lockKey = file.localID!;
    if (_allBackups[lockKey] != null &&
        _allBackups[lockKey]!.status != BackupItemStatus.uploading) {
      _allBackups[lockKey] = _allBackups[lockKey]!.copyWith(
        status: BackupItemStatus.uploading,
      );
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
    }
    if (!CollectionsService.instance.allowUpload(collectionID)) {
      throw ArgumentError(
        'Upload not allowed for collection $collectionID',
      );
    }
    try {
      await _uploadLocks.acquireLock(
        lockKey,
        _processType.toString(),
        DateTime.now().microsecondsSinceEpoch,
      );
    } catch (e) {
      final lockInfo = await _uploadLocks.getLockData(lockKey);
      _logger.warning("Lock was already taken ($lockInfo) for " + file.tag);
      throw LockAlreadyAcquiredError();
    }

    bool isMultipartUpload = false;
    UploadMedia? uploadMedia;
    try {
      uploadMedia = await getUploadMedia(file);
    } catch (e) {
      // This additional try catch block is added because for resumable upload,
      // we need to compute the hash before the next step. Previously, this
      // was done in during the upload itself.
      if (e is InvalidFileError) {
        _logger.severe("File upload ignored for " + file.toString(), e);
        await _onInvalidFileError(file, e);
      }
      await _uploadLocks.releaseLock(lockKey, _processType.toString());
      rethrow;
    }

    final String? existingMultipartEncFileName =
        await _uploadLocks.getEncryptedFileName(
      lockKey,
      uploadMedia.hash,
      collectionID,
    );

    bool multipartEntryExists = existingMultipartEncFileName != null;
    final tempDirectory = Configuration.instance.getTempDirectory();
    final String uniqueID =
        '${const Uuid().v4().toString()}_${file.generatedID}';

    final encryptedFilePath = multipartEntryExists
        ? '$tempDirectory$existingMultipartEncFileName'
        : '$tempDirectory$uploadTempFilePrefix${uniqueID}_file.encrypted';
    final encryptedThumbnailPath =
        '$tempDirectory$uploadTempFilePrefix${uniqueID}_thumb.encrypted';
    late final int encFileSize;
    late final int encThumbSize;

    var uploadCompleted = false;
    // This flag is used to decide whether to clear the iOS origin file cache
    // or not.
    var uploadHardFailure = false;

    try {
      final bool isUpdatedFile =
          file.rAsset != null && file.cf?.updatedAt == -1;
      _logger.info(
        'starting ${forcedUpload ? 'forced' : ''} '
        '${isUpdatedFile ? 're-upload' : 'upload'} of ${file.toString()}',
      );

      Uint8List? key;
      EncryptionResult? multiPartFileEncResult = multipartEntryExists
          ? await _multiPartUploader.getEncryptionResult(
              lockKey,
              uploadMedia.hash,
              collectionID,
            )
          : null;
      if (isUpdatedFile) {
        key = getFileKey(file);
      } else {
        key = multiPartFileEncResult?.key;
        // check if the file is already uploaded and can be mapped to existing
        // uploaded file. If map is found, it also returns the corresponding
        // mapped or update file entry.
        final matchedFile =
            await PreUploadCheck.mapToExistingUploadWithSameHash(
          uploadMedia,
          file,
          collectionID,
        );
        if (matchedFile != null) {
          _logger.finest(
            "File success mapped to existing uploaded ${file.toString()}",
          );
          return matchedFile;
        }
      }

      final encryptedFileExists = File(encryptedFilePath).existsSync();

      // If the multipart entry exists but the encrypted file doesn't, it means
      // that we'll have to re-upload as the nonce is lost
      if (multipartEntryExists) {
        final bool updateWithDiffKey = isUpdatedFile &&
            multiPartFileEncResult != null &&
            !listEquals(key, multiPartFileEncResult.key);
        if (!encryptedFileExists || updateWithDiffKey) {
          if (updateWithDiffKey) {
            _logger.severe('multiPart update resumed with differentKey');
          } else {
            _logger.warning(
              'multiPart EncryptedFile missing, discard multipart entry',
            );
          }
          await _uploadLocks.deleteMultipartTrack(lockKey);
          multipartEntryExists = false;
          multiPartFileEncResult = null;
        }
      } else if (encryptedFileExists) {
        // otherwise just delete the file for singlepart upload
        await File(encryptedFilePath).delete();
      }
      await PreUploadCheck.checkIfWithinStorageLimit(uploadMedia.uploadFile);
      final encryptedFile = File(encryptedFilePath);

      final EncryptionResult fileEncryptResult = multiPartFileEncResult ??
          await CryptoUtil.encryptFile(
            uploadMedia.uploadFile.path,
            encryptedFilePath,
            key: key,
          );

      late final Uint8List? thumbnailData;
      if (uploadMedia.thumbnail == null && file.fileType == FileType.video) {
        thumbnailData = base64Decode(blackThumbnailBase64);
      } else {
        thumbnailData = uploadMedia.thumbnail;
      }
      encFileSize = await encryptedFile.length();

      final EncryptionResult thumbEncResult = await CryptoUtil.encryptChaCha(
        thumbnailData!,
        fileEncryptResult.key!,
      );
      if (File(encryptedThumbnailPath).existsSync()) {
        await File(encryptedThumbnailPath).delete();
      }
      final encryptedThumbnailFile = File(encryptedThumbnailPath);
      await encryptedThumbnailFile.writeAsBytes(thumbEncResult.encryptedData!);
      encThumbSize = await encryptedThumbnailFile.length();

      // Calculate the number of parts for the file.
      final count = _multiPartUploader.calculatePartCount(encFileSize);

      late String fileObjectKey;
      late String thumbnailObjectKey;

      if (count <= 1) {
        final thumbnailUploadURL = await _getUploadURL();
        thumbnailObjectKey = await _putFile(
          thumbnailUploadURL,
          encryptedThumbnailFile,
          encThumbSize,
        );
        final fileUploadURL = await _getUploadURL();
        fileObjectKey =
            await _putFile(fileUploadURL, encryptedFile, encFileSize);
      } else {
        isMultipartUpload = true;
        _logger.info(
          "Init multipartUpload $multipartEntryExists, isUpdate $isUpdatedFile",
        );
        if (multipartEntryExists) {
          fileObjectKey = await _multiPartUploader.putExistingMultipartFile(
            encryptedFile,
            lockKey,
            uploadMedia.hash,
            collectionID,
          );
        } else {
          final fileUploadURLs =
              await _multiPartUploader.getMultipartUploadURLs(count);
          final encFileName = encryptedFile.path.split('/').last;
          await _multiPartUploader.createTableEntry(
            lockKey,
            uploadMedia.hash,
            collectionID,
            fileUploadURLs,
            encFileName,
            encFileSize,
            fileEncryptResult.key!,
            fileEncryptResult.header!,
          );
          fileObjectKey = await _multiPartUploader.putMultipartFile(
            fileUploadURLs,
            encryptedFile,
            encFileSize,
          );
        }
        // in case of multipart, upload the thumbnail towards the end to avoid
        // re-uploading the thumbnail in case of failure.
        // In regular upload, always upload the thumbnail first to keep existing behaviour
        //
        final thumbnailUploadURL = await _getUploadURL();
        thumbnailObjectKey = await _putFile(
          thumbnailUploadURL,
          encryptedThumbnailFile,
          encThumbSize,
        );
      }
      final uploadMetadata = await getUploadMetadata(uploadMedia, file);
      final Map<String, dynamic> metadata = uploadMetadata.defaultMetadata;
      final Map<String, dynamic> pubMetadata =
          uploadMetadata.publicMetadata ?? <String, dynamic>{};
      final int? pubMetadataVersion =
          uploadMetadata.currentPublicMetadataVersion;

      final encryptedMetadataResult = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(metadata)),
        fileEncryptResult.key!,
      );
      final encryptedMetadata = CryptoUtil.bin2base64(
        encryptedMetadataResult.encryptedData!,
      );
      final metadataDecryptionHeader =
          CryptoUtil.bin2base64(encryptedMetadataResult.header!);

      final MetadataRequest? pubMetadataRequest = await getPubMetadataRequest(
        pubMetadata,
        fileEncryptResult.key!,
        pubMetadataVersion,
      );

      final fileDecryptionHeader =
          CryptoUtil.bin2base64(fileEncryptResult.header!);
      final thumbnailDecryptionHeader =
          CryptoUtil.bin2base64(thumbEncResult.header!);
      if (SyncService.instance.shouldStopSync()) {
        throw SyncStopRequestedError();
      }
      final stillLocked =
          await _uploadLocks.isLocked(lockKey, _processType.toString());
      if (!stillLocked) {
        _logger.warning('file ${file.tag} report paused is missing');
        throw LockFreedError();
      }

      EnteFile remoteFile;
      if (isUpdatedFile) {
        final response = await _updateFile(
          file,
          fileObjectKey: fileObjectKey,
          fileDecryptionHeader: fileDecryptionHeader,
          fileSize: encFileSize,
          thumbnailObjectKey: thumbnailObjectKey,
          thumbnailDecryptionHeader: thumbnailDecryptionHeader,
          thumbnailSize: encThumbSize,
          encryptedMetadata: encryptedMetadata,
          metadataDecryptionHeader: metadataDecryptionHeader,
        );
        if (response.id != file.remoteID) {
          throw Exception(
            "File update response ID does not match the file's remoteID",
          );
        }
        remoteFile = file;
        remoteFile.rAsset = file.rAsset!.copyWith(
          thumbHeader: thumbEncResult.header!,
          fileHeader: fileEncryptResult.header!,
          // metadata: Metadata(data: metadata, version: metadata['version'] ?? 0),
        );
        // Update across all collections
        // todo:neeraj rewrite update during upload
        // await FilesDB.instance.updateUploadedFileAcrossCollections(remoteFile);
      } else {
        final encryptedFileKeyData = CryptoUtil.encryptSync(
          fileEncryptResult.key!,
          CollectionsService.instance.getCollectionKey(collectionID),
        );

        remoteFile = await _createFile(
          file,
          collectionID,
          encryptedKey:
              CryptoUtil.bin2base64(encryptedFileKeyData.encryptedData!),
          keyDecryptionNonce:
              CryptoUtil.bin2base64(encryptedFileKeyData.nonce!),
          fileObjectKey: fileObjectKey,
          fileDecryptionHeader: fileDecryptionHeader,
          fileSize: encFileSize,
          thumbnailObjectKey: thumbnailObjectKey,
          thumbnailDecryptionHeader: thumbnailDecryptionHeader,
          thumbnailSize: encThumbSize,
          encryptedMetadata: encryptedMetadata,
          metadataDecryptionHeader: metadataDecryptionHeader,
          pubMetadata: pubMetadataRequest,
          metadata: metadata,
          pubMagicMetadata: pubMetadata,
        );
        if (uploadMedia.isDeleted) {
          _logger.info("File found to be deleted");
          remoteFile.localID = null;
        }
        // await FilesDB.instance.update(remoteFile);
      }
      await UploadLocksDB.instance.deleteMultipartTrack(lockKey);

      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          [remoteFile],
          source: "uploadCompleted",
        ),
      );
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
        // file upload can not be retried in such cases without user intervention
        uploadHardFailure = true;
      }
      if (isMultipartUpload && isPutOrUpdateFileError(e)) {
        await UploadLocksDB.instance.deleteMultipartTrack(lockKey);
      }
      rethrow;
    } finally {
      await _onUploadDone(
        uploadMedia,
        uploadCompleted,
        uploadHardFailure,
        file,
        encryptedFilePath,
        encryptedThumbnailPath,
        lockKey: lockKey,
        isMultiPartUpload: isMultipartUpload,
      );
    }
  }

  bool isPutOrUpdateFileError(Object e) {
    if (e is DioException) {
      return e.requestOptions.path.contains("/files") ||
          e.requestOptions.path.contains("/files/update");
    }
    return false;
  }

  Future<void> _onUploadDone(
    UploadMedia? uploadMedia,
    bool uploadCompleted,
    bool uploadHardFailure,
    EnteFile file,
    String encryptedFilePath,
    String encryptedThumbnailPath, {
    required String lockKey,
    bool isMultiPartUpload = false,
  }) async {
    if (uploadMedia != null) {
      // delete the file from app's internal cache if it was copied to app
      // for upload. On iOS, only remove the file from photo_manager/app cache
      // when upload is either completed or there's a tempFailure
      // Shared Media should only be cleared when the upload
      // succeeds.
      if ((Platform.isIOS && (uploadCompleted || uploadHardFailure)) ||
          (uploadCompleted && file.isSharedMediaToAppSandbox)) {
        await uploadMedia.delete();
      }
    }
    if (File(encryptedFilePath).existsSync()) {
      if (isMultiPartUpload && !uploadCompleted) {
        _logger.info(
          "skip delete for multipart encrypted file $encryptedFilePath",
        );
      } else {
        await File(encryptedFilePath).delete();
      }
    }
    if (File(encryptedThumbnailPath).existsSync()) {
      await File(encryptedThumbnailPath).delete();
    }
    await _uploadLocks.releaseLock(lockKey, _processType.toString());
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
        await IgnoredFilesService.instance.ignoreUpload(file, e);
      }
    } catch (e, s) {
      _logger.severe("Failed to handle invalid file error", e, s);
    }
  }

  Future<EnteFile> _createFile(
    EnteFile file,
    int collectionID, {
    required String encryptedKey,
    required String keyDecryptionNonce,
    required String fileObjectKey,
    required String fileDecryptionHeader,
    required int fileSize,
    required String thumbnailObjectKey,
    required String thumbnailDecryptionHeader,
    required int thumbnailSize,
    required String encryptedMetadata,
    required String metadataDecryptionHeader,
    required Map<String, dynamic> metadata,
    MetadataRequest? pubMetadata,
    Map<String, dynamic>? pubMagicMetadata,
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
      final int remoteID = data["id"];
      final int ownerID = data["ownerID"];
      final int updatedAt = data["updationTime"];
      file.cf = CollectionFile(
        collectionID: collectionID,
        fileID: remoteID,
        encFileKey: CryptoUtil.base642bin(encryptedKey),
        encFileKeyNonce: CryptoUtil.base642bin(keyDecryptionNonce),
        updatedAt: updatedAt,
        createdAt: updatedAt,
      );
      file.rAsset = RemoteAsset.fromMetadata(
        id: remoteID,
        ownerID: ownerID,
        fileHeader: CryptoUtil.base642bin(fileDecryptionHeader),
        thumbHeader: CryptoUtil.base642bin(thumbnailDecryptionHeader),
        info: Info(fileSize: fileSize, thumbSize: thumbnailSize),
        metadata: Metadata(data: metadata, version: metadata['version']!),
        publicMetadata: pubMetadata != null
            ? Metadata(data: pubMagicMetadata!, version: pubMetadata.version!)
            : null,
        privateMetadata: null,
      );
      return file;
    } on DioException catch (e) {
      final int statusCode = e.response?.statusCode ?? -1;
      if (statusCode == 413) {
        throw FileTooLargeForPlanError();
      } else if (statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts && statusCode == -1) {
        // retry when DioException contains no response/status code
        _logger
            .info("Upload file (${file.tag}) failed, will retry in 3 seconds");
        await Future.delayed(const Duration(seconds: 3));
        return _createFile(
          file,
          collectionID,
          encryptedKey: encryptedKey,
          keyDecryptionNonce: keyDecryptionNonce,
          fileObjectKey: fileObjectKey,
          fileDecryptionHeader: fileDecryptionHeader,
          fileSize: fileSize,
          thumbnailObjectKey: thumbnailObjectKey,
          thumbnailDecryptionHeader: thumbnailDecryptionHeader,
          thumbnailSize: thumbnailSize,
          encryptedMetadata: encryptedMetadata,
          metadataDecryptionHeader: metadataDecryptionHeader,
          pubMetadata: pubMetadata,
          metadata: metadata,
          pubMagicMetadata: pubMagicMetadata,
          attempt: attempt + 1,
        );
      } else {
        _logger.severe("Failed to upload file ${file.tag}", e);
      }
      rethrow;
    }
  }

  Future<FileUpdateResponse> _updateFile(
    EnteFile file, {
    required String fileObjectKey,
    required String fileDecryptionHeader,
    required int fileSize,
    required String thumbnailObjectKey,
    required int thumbnailSize,
    required String encryptedMetadata,
    required String metadataDecryptionHeader,
    required String thumbnailDecryptionHeader,
    int attempt = 1,
  }) async {
    final request = {
      "id": file.remoteID,
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
      return FileUpdateResponse(
        id: data["id"],
        updationTime: data["updationTime"],
      );
    } on DioException catch (e) {
      final int statusCode = e.response?.statusCode ?? -1;
      if (statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts && statusCode == -1) {
        _logger
            .info("Update file (${file.tag}) failed, will retry in 3 seconds");
        await Future.delayed(const Duration(seconds: 3));
        return _updateFile(
          file,
          fileObjectKey: fileObjectKey,
          fileDecryptionHeader: fileDecryptionHeader,
          fileSize: fileSize,
          thumbnailObjectKey: thumbnailObjectKey,
          thumbnailSize: thumbnailSize,
          thumbnailDecryptionHeader: thumbnailDecryptionHeader,
          encryptedMetadata: encryptedMetadata,
          metadataDecryptionHeader: metadataDecryptionHeader,
          attempt: attempt + 1,
        );
      } else {
        _logger.severe("Failed to update file ${file.tag}", e);
      }
      rethrow;
    }
  }

  Future<UploadURL> _getUploadURL() async {
    if (_uploadURLs.isEmpty) {
      // the queue is empty, fetch at least for one file to handle force uploads
      // that are not in the queue. This is to also avoid
      await fetchUploadURLs(math.max(_queue.length, 1));
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
            "count": math.min(42, fileCount * 2), // m4gic number
          },
        );
        final urls = (response.data["urls"] as List)
            .map((e) => UploadURL.fromMap(e))
            .toList();
        _uploadURLs.addAll(urls);
      } on DioException catch (e, s) {
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
            _logger.warning("Could not fetch upload URLs", e, s);
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
    File file,
    int fileSize, {
    int attempt = 1,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final fileName = basename(file.path);
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
        "Uploaded object $fileName of size: ${formatBytes(fileSize)} at speed: ${(fileSize / (DateTime.now().millisecondsSinceEpoch - startTime)).toStringAsFixed(2)} KB/s",
      );

      return uploadURL.objectKey;
    } on DioException catch (e) {
      if (e.message?.startsWith("HttpException: Content size") ?? false) {
        rethrow;
      } else if (attempt < kMaximumUploadAttempts) {
        _logger.info("Upload failed for $fileName, retrying");
        final newUploadURL = await _getUploadURL();
        return _putFile(
          newUploadURL,
          file,
          fileSize,
          attempt: attempt + 1,
        );
      } else {
        _logger.info(
          "Failed to upload file ${basename(file.path)} after $attempt attempts",
          e,
        );
        rethrow;
      }
    }
  }

  // _pollBackgroundUploadStatus polls the background uploads to check if the
  // upload is completed or failed.
  Future<void> _pollBackgroundUploadStatus() async {
    final blockedUploads = _queue.entries
        .where((e) => e.value.status == UploadStatus.inBackground)
        .toList();
    for (final upload in blockedUploads) {
      final String lockKey = upload.value.lockKey;
      final isStillLocked = await _uploadLocks.isLocked(
        lockKey,
        ProcessType.background.toString(),
      );
      if (!isStillLocked && upload.value.assetQueue != null) {
        final completer = _queue.remove(upload.key)?.completer;
        final exists = await localDB.existsQueueEntry(upload.value.assetQueue!);
        if (exists) {
          _logger.info(
            "Background upload success detected ${upload.value.file.tag}",
          );
          // todo:neeraj Instead of cancel, fire event
          completer?.completeError(SilentlyCancelUploadsError());
          _allBackups[upload.key] = _allBackups[upload.key]!
              .copyWith(status: BackupItemStatus.uploaded);
        } else {
          _logger.info(
            "Background upload failure detected ${upload.value.file.tag}",
          );
          // The upload status is marked as in background, but the file is not locked
          // by the background process. Release any lock taken by the foreground process
          // and complete the completer with error.
          await _uploadLocks.releaseLock(
            lockKey,
            ProcessType.foreground.toString(),
          );
          completer?.completeError(SilentlyCancelUploadsError());
          _allBackups[upload.key] = _allBackups[upload.key]!.copyWith(
            status: BackupItemStatus.retry,
            error: SilentlyCancelUploadsError(),
          );
        }

        Bus.instance.fire(BackupUpdatedEvent(_allBackups));
      }
    }
    Future.delayed(kBlockedUploadsPollFrequency, () async {
      await _pollBackgroundUploadStatus();
    });
  }
}
