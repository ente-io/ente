import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_network/network.dart';
import 'package:flutter/foundation.dart';
import 'package:locker/core/constants.dart';
import 'package:locker/core/errors.dart';
import 'package:locker/events/backup_updated_event.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/services/files/sync/metadata_updater_service.dart";
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/files/sync/models/file_magic.dart';
import 'package:locker/services/files/upload/models/backup_item.dart';
import 'package:locker/services/files/upload/models/backup_item_status.dart';
import 'package:locker/services/files/upload/models/upload_url.dart';
import "package:locker/utils/crypto_helper.dart";
import 'package:locker/utils/data_util.dart';
import 'package:logging/logging.dart';
import "package:path/path.dart";
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _lastStaleFileCleanupTime = "lastStaleFileCleanupTime";

  final _logger = Logger("FileUploader");
  final _dio = Network.instance.getDio();
  final _enteDio = Network.instance.enteDio;
  final LinkedHashMap<String, FileUploadItem> _queue =
      LinkedHashMap<String, FileUploadItem>();
  final LinkedHashMap<String, BackupItem> _allBackups =
      LinkedHashMap<String, BackupItem>();
  final kSafeBufferForLockExpiry = const Duration(hours: 4).inMicroseconds;
  final kBGTaskDeathTimeout = const Duration(seconds: 5).inMicroseconds;
  final _uploadURLs = Queue<UploadURL>();

  LinkedHashMap<String, BackupItem> get allBackups => _allBackups;

  // Maintains the count of files in the current upload session.
  // Upload session is the period between the first entry into the _queue and last entry out of the _queue
  int _totalCountInUploadSession = 0;

  // _uploadCounter indicates number of uploads which are currently in progress
  int _uploadCounter = 0;
  late SharedPreferences _prefs;

  // _hasInitiatedForceUpload is used to track if user attempted force upload
  // where files are uploaded directly (without adding them to DB). In such
  // cases, we don't want to clear the stale upload files. See #removeStaleFiles
  // as it can result in clearing files which are still being force uploaded.
  final bool _hasInitiatedForceUpload = false;

  FileUploader._privateConstructor();

  static FileUploader instance = FileUploader._privateConstructor();

  Future<void> init(SharedPreferences preferences, bool isBackground) async {
    _prefs = preferences;
    final currentTime = DateTime.now().microsecondsSinceEpoch;
    if (currentTime - (_prefs.getInt(_lastStaleFileCleanupTime) ?? 0) >
        tempDirCleanUpInterval) {
      await removeStaleFiles();
      await _prefs.setInt(_lastStaleFileCleanupTime, currentTime);
    }
  }

  Future<EnteFile> upload(File file, Collection collection) {
    _totalCountInUploadSession++;
    final String path = file.path;
    final completer = Completer<EnteFile>();
    _queue[path] = FileUploadItem(file, collection, completer);
    _allBackups[path] = BackupItem(
      status: BackupItemStatus.inQueue,
      file: file,
      collection: collection,
      completer: completer,
    );
    Bus.instance.fire(BackupUpdatedEvent(_allBackups));
    _pollQueue();
    return completer.future;
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
    final bool Function(File) fn,
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
    if (_queue.isEmpty) {
      // Upload session completed
      _totalCountInUploadSession = 0;
      return;
    }
    if (_uploadCounter < kMaximumConcurrentUploads) {
      final pendingEntry = _queue.entries
          .firstWhereOrNull(
            (entry) => entry.value.status == UploadStatus.notStarted,
          )
          ?.value;
      if (pendingEntry != null) {
        pendingEntry.status = UploadStatus.inProgress;
        _allBackups[pendingEntry.file.path] =
            _allBackups[pendingEntry.file.path]!
                .copyWith(status: BackupItemStatus.uploading);
        Bus.instance.fire(BackupUpdatedEvent(_allBackups));
        _encryptAndUploadFileToCollection(
          pendingEntry.file,
          pendingEntry.collection,
        );
      }
    }
  }

  Future<EnteFile?> _encryptAndUploadFileToCollection(
    File file,
    Collection collection, {
    bool forcedUpload = false,
  }) async {
    _uploadCounter++;
    final path = file.path;
    try {
      final uploadedFile =
          await _tryToUpload(file, collection, forcedUpload).timeout(
        kFileUploadTimeout,
        onTimeout: () {
          final message = "Upload timed out for file $file";
          _logger.warning(message);
          throw TimeoutException(message);
        },
      );
      _queue.remove(path)!.completer.complete(uploadedFile);
      _allBackups[path] =
          _allBackups[path]!.copyWith(status: BackupItemStatus.uploaded);
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
      return uploadedFile;
    } catch (e) {
      _queue.remove(path)!.completer.completeError(e);
      _allBackups[path] =
          _allBackups[path]!.copyWith(status: BackupItemStatus.retry, error: e);
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
      return null;
    } finally {
      _uploadCounter--;
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
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e, s) {
      _logger.severe("Failed to remove stale files", e, s);
    }
  }

  Future<EnteFile> _tryToUpload(
    File file,
    Collection collection,
    bool forcedUpload,
  ) async {
    if (_allBackups[file.path] != null &&
        _allBackups[file.path]!.status != BackupItemStatus.uploading) {
      _allBackups[file.path] = _allBackups[file.path]!.copyWith(
        status: BackupItemStatus.uploading,
      );
      Bus.instance.fire(BackupUpdatedEvent(_allBackups));
    }

    final tempDirectory = Configuration.instance.getTempDirectory();
    final String uniqueID =
        '${const Uuid().v4().toString()}_${file.path.split('/').last}';

    final encryptedFilePath =
        '$tempDirectory$uploadTempFilePrefix${uniqueID}_file.encrypted';
    final encryptedThumbnailPath =
        '$tempDirectory$uploadTempFilePrefix${uniqueID}_thumb.encrypted';
    late final int encFileSize;

    var uploadCompleted = false;
    // This flag is used to decide whether to clear the iOS origin file cache
    // or not.
    var uploadHardFailure = false;
    try {
      _logger.info(
        'starting ${forcedUpload ? 'forced' : ''} '
        'upload of ${file.toString()}',
      );

      Uint8List? key;
      final encryptedFileExists = File(encryptedFilePath).existsSync();

      if (encryptedFileExists) {
        // otherwise just delete the file for singlepart upload
        await File(encryptedFilePath).delete();
      }
      await _checkIfWithinStorageLimit(file);
      final encryptedFile = File(encryptedFilePath);

      final fileAttributes = await CryptoUtil.encryptFile(
        file.path,
        encryptedFilePath,
        key: key,
      );
      encFileSize = await encryptedFile.length();

      final thumbnailData = base64Decode(blackThumbnailBase64);
      final encryptedThumbnailData = await CryptoUtil.encryptData(
        thumbnailData,
        fileAttributes.key!,
      );
      if (File(encryptedThumbnailPath).existsSync()) {
        await File(encryptedThumbnailPath).delete();
      }
      final encryptedThumbnailFile = File(encryptedThumbnailPath);
      await encryptedThumbnailFile
          .writeAsBytes(encryptedThumbnailData.encryptedData!);
      final encThumbSize = await encryptedThumbnailFile.length();

      final thumbnailUploadURL = await _getUploadURL();
      final thumbnailObjectKey = await _putFile(
        thumbnailUploadURL,
        encryptedThumbnailFile,
        encThumbSize,
      );

      final fileUploadURL = await _getUploadURL();
      final fileObjectKey =
          await _putFile(fileUploadURL, encryptedFile, encFileSize);

      final enteFile = EnteFile.fromFile(file);

      final encryptedMetadataResult = await CryptoUtil.encryptData(
        utf8.encode(jsonEncode(enteFile.metadata)),
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
      final encryptedFileKeyData = CryptoUtil.encryptSync(
        fileAttributes.key!,
        CryptoHelper.instance.getCollectionKey(collection),
      );
      final encryptedKey =
          CryptoUtil.bin2base64(encryptedFileKeyData.encryptedData!);
      final keyDecryptionNonce =
          CryptoUtil.bin2base64(encryptedFileKeyData.nonce!);
      final Map<String, dynamic> pubMetadata = {};
      pubMetadata["noThumb"] = true;
      MetadataRequest? pubMetadataRequest;
      if (pubMetadata.isNotEmpty) {
        pubMetadataRequest = await getPubMetadataRequest(
          enteFile,
          pubMetadata,
          fileAttributes.key!,
        );
      }
      final remoteFile = await _uploadFile(
        enteFile,
        collection.id,
        encryptedKey,
        keyDecryptionNonce,
        fileObjectKey,
        fileDecryptionHeader,
        encFileSize,
        thumbnailObjectKey,
        thumbnailDecryptionHeader,
        encThumbSize,
        encryptedMetadata,
        metadataDecryptionHeader,
        pubMetadata: pubMetadataRequest,
      );
      _logger.info("File upload complete for $remoteFile");
      uploadCompleted = true;
      return remoteFile;
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError ||
          e is StorageLimitExceededError ||
          e is WiFiUnavailableError ||
          e is SilentlyCancelUploadsError ||
          e is InvalidFileError ||
          e is FileTooLargeForPlanError)) {
        _logger.severe("File upload failed for $file", e, s);
      }
      if (e is InvalidFileError) {
        _logger.severe("File upload ignored for $file", e);
      }
      if ((e is StorageLimitExceededError ||
          e is FileTooLargeForPlanError ||
          e is NoActiveSubscriptionError)) {
        // file upload can not be retried in such cases without user intervention
        uploadHardFailure = true;
      }
      rethrow;
    } finally {
      await _onUploadDone(
        file,
        uploadCompleted,
        uploadHardFailure,
        encryptedFilePath,
        encryptedThumbnailPath,
      );
    }
  }

  Future<MetadataRequest> getPubMetadataRequest(
    EnteFile file,
    Map<String, dynamic> newData,
    Uint8List fileKey,
  ) async {
    final Map<String, dynamic> jsonToUpdate =
        jsonDecode(file.pubMmdEncodedJson ?? '{}');
    newData.forEach((key, value) {
      jsonToUpdate[key] = value;
    });

    // update the local information so that it's reflected on UI
    file.pubMmdEncodedJson = jsonEncode(jsonToUpdate);
    file.pubMagicMetadata = PubMagicMetadata.fromJson(jsonToUpdate);
    final encryptedMMd = await CryptoUtil.encryptData(
      utf8.encode(jsonEncode(jsonToUpdate)),
      fileKey,
    );
    return MetadataRequest(
      version: file.pubMmdVersion == 0 ? 1 : file.pubMmdVersion,
      count: jsonToUpdate.length,
      data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
      header: CryptoUtil.bin2base64(encryptedMMd.header!),
    );
  }

  Future<void> _onUploadDone(
    File sourceFile,
    bool uploadCompleted,
    bool uploadHardFailure,
    String encryptedFilePath,
    String encryptedThumbnailPath,
  ) async {
    // Note: Consider removing source file if upload has completed / failed
    if (File(encryptedFilePath).existsSync()) {
      await File(encryptedFilePath).delete();
    }
    if (File(encryptedThumbnailPath).existsSync()) {
      await File(encryptedThumbnailPath).delete();
    }
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
      final userDetails = UserService.instance.getCachedUserDetails();
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

  Future<EnteFile> _uploadFile(
    EnteFile file,
    int collectionID,
    String encryptedKey,
    String keyDecryptionNonce,
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
      file.thumbnailDecryptionHeader = thumbnailDecryptionHeader;
      file.fileDecryptionHeader = fileDecryptionHeader;
      file.metadataDecryptionHeader = metadataDecryptionHeader;
      return file;
    } on DioException catch (e) {
      final int statusCode = e.response?.statusCode ?? -1;
      if (statusCode == 413) {
        throw FileTooLargeForPlanError();
      } else if (statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts && statusCode == -1) {
        // retry when DioException contains no response/status code
        _logger.info(
          "Upload file (${file.displayName}) failed, will retry in 3 seconds",
        );
        await Future.delayed(const Duration(seconds: 3));
        return _uploadFile(
          file,
          collectionID,
          encryptedKey,
          keyDecryptionNonce,
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
      } else {
        _logger.severe("Failed to upload file ${file.displayName}", e);
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
}

class FileUploadItem {
  final File file;
  final Collection collection;
  final Completer<EnteFile> completer;
  UploadStatus status;

  FileUploadItem(
    this.file,
    this.collection,
    this.completer, {
    this.status = UploadStatus.notStarted,
  });
}

enum UploadStatus { notStarted, inProgress, inBackground, completed }

enum ProcessType {
  background,
  foreground,
}
