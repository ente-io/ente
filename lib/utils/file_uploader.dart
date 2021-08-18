import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/encryption_result.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:photos/utils/file_uploader_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileUploader {
  static const kMaximumConcurrentUploads = 4;
  static const kMaximumThumbnailCompressionAttempts = 2;
  static const kMaximumUploadAttempts = 4;
  static const kBlockedUploadsPollFrequency = Duration(seconds: 2);

  final _logger = Logger("FileUploader");
  final _dio = Network.instance.getDio();
  final _queue = LinkedHashMap<String, FileUploadItem>();
  final _uploadLocks = UploadLocksDB.instance;
  final kSafeBufferForLockExpiry = Duration(days: 1).inMicroseconds;
  final kBGTaskDeathTimeout = Duration(seconds: 5).inMicroseconds;
  final _uploadURLs = Queue<UploadURL>();

  // Maintains the count of files in the current upload session.
  // Upload session is the period between the first entry into the _queue and last entry out of the _queue
  int _totalCountInUploadSession = 0;
  int _currentlyUploading = 0;
  ProcessType _processType;
  bool _isBackground;
  SharedPreferences _prefs;

  FileUploader._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploadURLFetchInProgress = null;
    });
  }
  static FileUploader instance = FileUploader._privateConstructor();

  Future<void> init(bool isBackground) async {
    _prefs = await SharedPreferences.getInstance();
    _isBackground = isBackground;
    _processType =
        isBackground ? ProcessType.background : ProcessType.foreground;
    final currentTime = DateTime.now().microsecondsSinceEpoch;
    await _uploadLocks.releaseLocksAcquiredByOwnerBefore(
        _processType.toString(), currentTime);
    await _uploadLocks
        .releaseAllLocksAcquiredBefore(currentTime - kSafeBufferForLockExpiry);
    if (!isBackground) {
      await _prefs.reload();
      final isBGTaskDead = (_prefs.getInt(kLastBGTaskHeartBeatTime) ?? 0) <
          (currentTime - kBGTaskDeathTimeout);
      if (isBGTaskDead) {
        await _uploadLocks.releaseLocksAcquiredByOwnerBefore(
            ProcessType.background.toString(), currentTime);
        _logger.info("BG task was found dead, cleared all locks");
      }
      _pollBackgroundUploadStatus();
    }
  }

  Future<File> upload(File file, int collectionID) {
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

    // Else wait for the existing upload to complete,
    // and add it to the relevant collection
    return item.completer.future.then((uploadedFile) {
      return CollectionsService.instance
          .addToCollection(collectionID, [uploadedFile]).then((aVoid) {
        return uploadedFile;
      });
    });
  }

  Future<File> forceUpload(File file, int collectionID) async {
    _logger.info("Force uploading " +
        file.toString() +
        " into collection " +
        collectionID.toString());
    _totalCountInUploadSession++;
    // If the file hasn't been queued yet, ez.
    if (!_queue.containsKey(file.localID)) {
      final completer = Completer<File>();
      _queue[file.localID] = FileUploadItem(
        file,
        collectionID,
        completer,
        status: UploadStatus.in_progress,
      );
      _encryptAndUploadFileToCollection(file, collectionID, forcedUpload: true);
      return completer.future;
    }
    var item = _queue[file.localID];
    // If the file is being uploaded right now, wait and proceed
    if (item.status == UploadStatus.in_progress ||
        item.status == UploadStatus.in_background) {
      _totalCountInUploadSession--;
      final uploadedFile = await item.completer.future;
      if (uploadedFile.collectionID == collectionID) {
        // Do nothing
      } else {
        await CollectionsService.instance
            .addToCollection(collectionID, [uploadedFile]);
      }
      return uploadedFile;
    } else {
      // If the file is yet to be processed,
      // 1. Set the status to in_progress
      // 2. Force upload the file
      // 3. Add to the relevant collection
      item = _queue[file.localID];
      item.status = UploadStatus.in_progress;
      final uploadedFile = await _encryptAndUploadFileToCollection(
          file, collectionID,
          forcedUpload: true);
      if (item.collectionID == collectionID) {
        return uploadedFile;
      } else {
        await CollectionsService.instance
            .addToCollection(item.collectionID, [uploadedFile]);
        return uploadedFile;
      }
    }
  }

  int getCurrentSessionUploadCount() {
    return _totalCountInUploadSession;
  }

  void clearQueue(final Error reason) {
    final List<String> uploadsToBeRemoved = [];
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.not_started)
        .forEach((pendingUpload) {
      uploadsToBeRemoved.add(pendingUpload.key);
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(reason);
    }
    _totalCountInUploadSession = 0;
  }

  void removeFromQueueWhere(final bool Function(File) fn, final Error reason) {
    List<String> uploadsToBeRemoved = [];
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.not_started)
        .forEach((pendingUpload) {
      if (fn(pendingUpload.value.file)) {
        uploadsToBeRemoved.add(pendingUpload.key);
      }
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(reason);
    }
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
    if (_currentlyUploading < kMaximumConcurrentUploads) {
      final firstPendingEntry = _queue.entries
          .firstWhere((entry) => entry.value.status == UploadStatus.not_started,
              orElse: () => null)
          ?.value;
      if (firstPendingEntry != null) {
        firstPendingEntry.status = UploadStatus.in_progress;
        _encryptAndUploadFileToCollection(
            firstPendingEntry.file, firstPendingEntry.collectionID);
      }
    }
  }

  Future<File> _encryptAndUploadFileToCollection(File file, int collectionID,
      {bool forcedUpload = false}) async {
    _currentlyUploading++;
    final localID = file.localID;
    try {
      final uploadedFile = await _tryToUpload(file, collectionID, forcedUpload);
      _queue.remove(localID).completer.complete(uploadedFile);
      return uploadedFile;
    } catch (e) {
      if (e is LockAlreadyAcquiredError) {
        _queue[localID].status = UploadStatus.in_background;
        return _queue[localID].completer.future;
      } else {
        _queue.remove(localID).completer.completeError(e);
        return null;
      }
    } finally {
      _currentlyUploading--;
      _pollQueue();
    }
  }

  Future<File> _tryToUpload(
      File file, int collectionID, bool forcedUpload) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    var canUploadUnderCurrentNetworkConditions =
        (connectivityResult == ConnectivityResult.wifi ||
            Configuration.instance.shouldBackupOverMobileData());
    if (!canUploadUnderCurrentNetworkConditions && !forcedUpload) {
      throw WiFiUnavailableError();
    }

    try {
      await _uploadLocks.acquireLock(
        file.localID,
        _processType.toString(),
        DateTime.now().microsecondsSinceEpoch,
      );
    } catch (e) {
      _logger.warning("Lock was already taken for " + file.toString());
      throw LockAlreadyAcquiredError();
    }

    final tempDirectory = Configuration.instance.getTempDirectory();
    final encryptedFilePath = tempDirectory +
        file.generatedID.toString() +
        (_isBackground ? "_bg" : "") +
        ".encrypted";
    final encryptedThumbnailPath = tempDirectory +
        file.generatedID.toString() +
        "_thumbnail" +
        (_isBackground ? "_bg" : "") +
        ".encrypted";
    MediaUploadData mediaUploadData;

    try {
      _logger.info("Trying to upload " +
          file.toString() +
          ", isForced: " +
          forcedUpload.toString());
      try {
        mediaUploadData = await getUploadDataFromEnteFile(file);
      } catch (e) {
        if (e is InvalidFileError) {
          _onInvalidFileError(file);
        } else {
          rethrow;
        }
      }
      Uint8List key;
      var isAlreadyUploadedFile = file.uploadedFileID != null;
      if (isAlreadyUploadedFile) {
        key = decryptFileKey(file);
      } else {
        key = null;
      }

      if (io.File(encryptedFilePath).existsSync()) {
        await io.File(encryptedFilePath).delete();
      }
      final encryptedFile = io.File(encryptedFilePath);
      final fileAttributes = await CryptoUtil.encryptFile(
        mediaUploadData.sourceFile.path,
        encryptedFilePath,
        key: key,
      );
      var thumbnailData = mediaUploadData.thumbnail;

      final encryptedThumbnailData =
          await CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key);
      if (io.File(encryptedThumbnailPath).existsSync()) {
        await io.File(encryptedThumbnailPath).delete();
      }
      final encryptedThumbnailFile = io.File(encryptedThumbnailPath);
      await encryptedThumbnailFile
          .writeAsBytes(encryptedThumbnailData.encryptedData);

      final thumbnailUploadURL = await _getUploadURL();
      String thumbnailObjectKey =
          await _putFile(thumbnailUploadURL, encryptedThumbnailFile);

      final fileUploadURL = await _getUploadURL();
      String fileObjectKey = await _putFile(fileUploadURL, encryptedFile);

      file.hash = Sodium.bin2base64(
          await CryptoUtil.getHash(mediaUploadData.sourceFile));

      final metadata = await file.getMetadata();
      final encryptedMetadataData = await CryptoUtil.encryptChaCha(
          utf8.encode(jsonEncode(metadata)), fileAttributes.key);
      final fileDecryptionHeader = Sodium.bin2base64(fileAttributes.header);
      final thumbnailDecryptionHeader =
          Sodium.bin2base64(encryptedThumbnailData.header);
      final encryptedMetadata =
          Sodium.bin2base64(encryptedMetadataData.encryptedData);
      final metadataDecryptionHeader =
          Sodium.bin2base64(encryptedMetadataData.header);
      if (SyncService.instance.shouldStopSync()) {
        throw SyncStopRequestedError();
      }
      File remoteFile;
      if (isAlreadyUploadedFile) {
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
          fileAttributes.key,
          CollectionsService.instance.getCollectionKey(collectionID),
        );
        final encryptedKey =
            Sodium.bin2base64(encryptedFileKeyData.encryptedData);
        final keyDecryptionNonce =
            Sodium.bin2base64(encryptedFileKeyData.nonce);
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
        );
        if (mediaUploadData.isDeleted) {
          _logger.info("File found to be deleted");
          remoteFile.localID = null;
        }
        await FilesDB.instance.update(remoteFile);
      }
      if (!_isBackground) {
        Bus.instance.fire(LocalPhotosUpdatedEvent([remoteFile]));
      }
      _logger.info("File upload complete for " + remoteFile.toString());
      return remoteFile;
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError || e is StorageLimitExceededError)) {
        _logger.severe("File upload failed for " + file.toString(), e, s);
      }
      rethrow;
    } finally {
      if (io.Platform.isIOS &&
          mediaUploadData != null &&
          mediaUploadData.sourceFile != null) {
        await mediaUploadData.sourceFile.delete();
      }
      if (io.File(encryptedFilePath).existsSync()) {
        await io.File(encryptedFilePath).delete();
      }
      if (io.File(encryptedThumbnailPath).existsSync()) {
        await io.File(encryptedThumbnailPath).delete();
      }
      await _uploadLocks.releaseLock(file.localID, _processType.toString());
    }
  }

  Future _onInvalidFileError(File file) async {
    _logger.warning("Invalid file encountered: " + file.toString());
    await FilesDB.instance.deleteLocalFile(file);
    await LocalSyncService.instance.trackInvalidFile(file);
    throw InvalidFileError();
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
    try {
      final response = await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/files",
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        data: request,
      );
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
      if (e.response?.statusCode == 426) {
        _onStorageLimitExceeded();
      } else if (attempt < kMaximumUploadAttempts) {
        _logger.info("Upload file failed, will retry in 3 seconds");
        await Future.delayed(Duration(seconds: 3));
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
      final response = await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/files",
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        data: request,
      );
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
        await Future.delayed(Duration(seconds: 3));
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
      await _fetchUploadURLs();
    }
    return _uploadURLs.removeFirst();
  }

  Future<void> _uploadURLFetchInProgress;

  Future<void> _fetchUploadURLs() async {
    _uploadURLFetchInProgress ??= Future<void>(() async {
      try {
        final response = await _dio.get(
          Configuration.instance.getHttpEndpoint() + "/files/upload-urls",
          queryParameters: {
            "count": min(42, 2 * _queue.length), // m4gic number
          },
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        );
        final urls = (response.data["urls"] as List)
            .map((e) => UploadURL.fromMap(e))
            .toList();
        _uploadURLs.addAll(urls);
        _uploadURLFetchInProgress = null;
      } on DioError catch (e) {
        _uploadURLFetchInProgress = null;
        if (e.response != null) {
          if (e.response.statusCode == 402) {
            final error = NoActiveSubscriptionError();
            clearQueue(error);
            throw error;
          } else if (e.response.statusCode == 426) {
            final error = StorageLimitExceededError();
            clearQueue(error);
            throw error;
          }
        }
        rethrow;
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
    int contentLength,
    int attempt = 1,
  }) async {
    final fileSize = contentLength ?? await file.length();
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
      _logger.info("Upload speed : " +
          (fileSize / (DateTime.now().millisecondsSinceEpoch - startTime))
              .toString() +
          " kilo bytes per second");

      return uploadURL.objectKey;
    } on DioError catch (e) {
      if (e.message.startsWith(
              "HttpException: Content size exceeds specified contentLength.") &&
          attempt == 1) {
        return _putFile(uploadURL, file,
            contentLength: (await file.readAsBytes()).length, attempt: 2);
      } else if (attempt < kMaximumUploadAttempts) {
        final newUploadURL = await _getUploadURL();
        return _putFile(newUploadURL, file,
            contentLength: (await file.readAsBytes()).length,
            attempt: attempt + 1);
      } else {
        _logger.info(
            "Upload failed for file with size " + fileSize.toString(), e);
        rethrow;
      }
    }
  }

  Future<void> _pollBackgroundUploadStatus() async {
    final blockedUploads = _queue.entries
        .where((e) => e.value.status == UploadStatus.in_background)
        .toList();
    for (final upload in blockedUploads) {
      final file = upload.value.file;
      final isStillLocked = await _uploadLocks.isLocked(
          file.localID, ProcessType.background.toString());
      if (!isStillLocked) {
        final completer = _queue.remove(upload.key).completer;
        final dbFile =
            await FilesDB.instance.getFile(upload.value.file.generatedID);
        if (dbFile.uploadedFileID != null) {
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
    this.status = UploadStatus.not_started,
  });
}

enum UploadStatus {
  not_started,
  in_progress,
  in_background,
  completed,
}

enum ProcessType {
  background,
  foreground,
}
