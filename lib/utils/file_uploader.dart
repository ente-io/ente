import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/upload_locks_db.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/encryption_result.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileUploader {
  static const kMaximumConcurrentUploads = 4;
  static const kMaximumThumbnailCompressionAttempts = 2;
  static const kMaximumUploadAttempts = 4;
  static const kLastBGTaskHeartBeatTime = "bg_task_hb_time";
  static const kBGHeartBeatFrequency = Duration(seconds: 1);
  static const kBlockedUploadsPollFrequency = Duration(seconds: 2);

  final _logger = Logger("FileUploader");
  final _dio = Network.instance.getDio();
  final _queue = LinkedHashMap<String, FileUploadItem>();
  final _uploadLocks = UploadLocksDB.instance;
  final kSafeBufferForLockExpiry = Duration(days: 1).inMicroseconds;
  final kBGTaskDeathTimeout = Duration(seconds: 5).inMicroseconds;
  final _uploadURLs = Queue<UploadURL>();

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
    if (isBackground) {
      _scheduleBGHeartBeat();
    } else {
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

  void clearQueue(final Error reason) {
    final uploadsToBeRemoved = List<String>();
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.not_started)
        .forEach((pendingUpload) {
      uploadsToBeRemoved.add(pendingUpload.key);
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(reason);
    }
  }

  void _pollQueue() {
    if (SyncService.instance.shouldStopSync()) {
      clearQueue(SyncStopRequestedError());
    }
    if (_queue.length > 0 && _currentlyUploading < kMaximumConcurrentUploads) {
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
    try {
      final uploadedFile = await _tryToUpload(file, collectionID, forcedUpload);
      _queue.remove(file.localID).completer.complete(uploadedFile);
      return uploadedFile;
    } catch (e) {
      if (e is LockAlreadyAcquiredError) {
        _queue[file.localID].status = UploadStatus.in_background;
        return _queue[file.localID].completer.future;
      } else {
        _queue.remove(file.localID).completer.completeError(e);
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
    var sourceFile;

    try {
      _logger.info("Trying to upload " +
          file.toString() +
          ", isForced: " +
          forcedUpload.toString());
      final asset = await file.getAsset();
      if (asset == null) {
        await _onInvalidFileError(file);
      }
      sourceFile = (await asset.originFile);
      var key;
      var isAlreadyUploadedFile = file.uploadedFileID != null;
      if (isAlreadyUploadedFile) {
        key = decryptFileKey(file);
      } else {
        key = null;
      }

      if (io.File(encryptedFilePath).existsSync()) {
        io.File(encryptedFilePath).deleteSync();
      }
      final encryptedFile = io.File(encryptedFilePath);

      final fileAttributes = await CryptoUtil.encryptFile(
        sourceFile.path,
        encryptedFilePath,
        key: key,
      );

      var thumbnailData = await asset.thumbDataWithSize(
        THUMBNAIL_LARGE_SIZE,
        THUMBNAIL_LARGE_SIZE,
        quality: 50,
      );
      if (thumbnailData == null) {
        await _onInvalidFileError(file);
      }
      int compressionAttempts = 0;
      while (thumbnailData.length > THUMBNAIL_DATA_LIMIT &&
          compressionAttempts < kMaximumThumbnailCompressionAttempts) {
        _logger.info("Thumbnail size " + thumbnailData.length.toString());
        thumbnailData = await compressThumbnail(thumbnailData);
        _logger.info(
            "Compressed thumbnail size " + thumbnailData.length.toString());
        compressionAttempts++;
      }

      final encryptedThumbnailData =
          CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key);
      if (io.File(encryptedThumbnailPath).existsSync()) {
        io.File(encryptedThumbnailPath).deleteSync();
      }
      final encryptedThumbnailFile = io.File(encryptedThumbnailPath);
      encryptedThumbnailFile
          .writeAsBytesSync(encryptedThumbnailData.encryptedData);

      final thumbnailUploadURL = await _getUploadURL();
      String thumbnailObjectKey =
          await _putFile(thumbnailUploadURL, encryptedThumbnailFile);

      final fileUploadURL = await _getUploadURL();
      String fileObjectKey = await _putFile(fileUploadURL, encryptedFile);

      // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
      if (file.location == null ||
          (file.location.latitude == 0 && file.location.longitude == 0)) {
        final latLong = await (await file.getAsset()).latlngAsync();
        file.location = Location(latLong.latitude, latLong.longitude);
      }

      final encryptedMetadataData = CryptoUtil.encryptChaCha(
          utf8.encode(jsonEncode(file.getMetadata())), fileAttributes.key);
      final fileDecryptionHeader = Sodium.bin2base64(fileAttributes.header);
      final thumbnailDecryptionHeader =
          Sodium.bin2base64(encryptedThumbnailData.header);
      final encryptedMetadata =
          Sodium.bin2base64(encryptedMetadataData.encryptedData);
      final metadataDecryptionHeader =
          Sodium.bin2base64(encryptedMetadataData.header);
      var remoteFile;
      if (isAlreadyUploadedFile) {
        remoteFile = await _updateFile(
          file,
          fileObjectKey,
          fileDecryptionHeader,
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          encryptedMetadata,
          metadataDecryptionHeader,
        );
        // Update across all collections
        await FilesDB.instance.updateUploadedFileAcrossCollections(remoteFile);
      } else {
        remoteFile = await _uploadFile(
          file,
          collectionID,
          fileAttributes,
          fileObjectKey,
          fileDecryptionHeader,
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          encryptedMetadata,
          metadataDecryptionHeader,
        );
        await FilesDB.instance.update(remoteFile);
      }
      if (!_isBackground) {
        FileRepository.instance.reloadFiles();
      }
      _logger.info("File upload complete for " + remoteFile.toString());
      return remoteFile;
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError || e is StorageLimitExceededError)) {
        _logger.severe("File upload failed for " + file.toString(), e, s);
      }
      throw e;
    } finally {
      if (io.Platform.isIOS && sourceFile != null) {
        sourceFile.deleteSync();
      }
      if (io.File(encryptedFilePath).existsSync()) {
        io.File(encryptedFilePath).deleteSync();
      }
      if (io.File(encryptedThumbnailPath).existsSync()) {
        io.File(encryptedThumbnailPath).deleteSync();
      }
      await _uploadLocks.releaseLock(file.localID, _processType.toString());
    }
  }

  Future _onInvalidFileError(File file) async {
    _logger.severe("Invalid file encountered: " + file.toString());
    await FilesDB.instance.deleteLocalFile(file.localID);
    throw InvalidFileError();
  }

  Future<File> _uploadFile(
    File file,
    int collectionID,
    EncryptionResult fileAttributes,
    String fileObjectKey,
    String fileDecryptionHeader,
    String thumbnailObjectKey,
    String thumbnailDecryptionHeader,
    String encryptedMetadata,
    String metadataDecryptionHeader,
  ) async {
    final encryptedFileKeyData = CryptoUtil.encryptSync(
      fileAttributes.key,
      CollectionsService.instance.getCollectionKey(collectionID),
    );
    final encryptedKey = Sodium.bin2base64(encryptedFileKeyData.encryptedData);
    final keyDecryptionNonce = Sodium.bin2base64(encryptedFileKeyData.nonce);
    final request = {
      "collectionID": collectionID,
      "encryptedKey": encryptedKey,
      "keyDecryptionNonce": keyDecryptionNonce,
      "file": {
        "objectKey": fileObjectKey,
        "decryptionHeader": fileDecryptionHeader,
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "decryptionHeader": thumbnailDecryptionHeader,
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
      }
      throw e;
    }
  }

  Future<File> _updateFile(
    File file,
    String fileObjectKey,
    String fileDecryptionHeader,
    String thumbnailObjectKey,
    String thumbnailDecryptionHeader,
    String encryptedMetadata,
    String metadataDecryptionHeader,
  ) async {
    final request = {
      "id": file.uploadedFileID,
      "file": {
        "objectKey": fileObjectKey,
        "decryptionHeader": fileDecryptionHeader,
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "decryptionHeader": thumbnailDecryptionHeader,
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
      }
      throw e;
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
    if (_uploadURLFetchInProgress == null) {
      _uploadURLFetchInProgress = Future<void>(() async {
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
          throw e;
        }
      });
    }
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
    final fileSize = contentLength ?? file.lengthSync();
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
          (file.lengthSync() /
                  (DateTime.now().millisecondsSinceEpoch - startTime))
              .toString() +
          " kilo bytes per second");

      return uploadURL.objectKey;
    } on DioError catch (e) {
      if (e.message.startsWith(
              "HttpException: Content size exceeds specified contentLength.") &&
          attempt == 1) {
        return _putFile(uploadURL, file,
            contentLength: file.readAsBytesSync().length, attempt: 2);
      } else if (attempt < kMaximumUploadAttempts) {
        final newUploadURL = await _getUploadURL();
        return _putFile(newUploadURL, file,
            contentLength: file.readAsBytesSync().length, attempt: attempt++);
      } else {
        _logger.info(
            "Upload failed for file with size " + fileSize.toString(), e);
        throw e;
      }
    }
  }

  Future<void> _scheduleBGHeartBeat() async {
    await _prefs.setInt(
        kLastBGTaskHeartBeatTime, DateTime.now().microsecondsSinceEpoch);
    Future.delayed(kBGHeartBeatFrequency, () async {
      await _scheduleBGHeartBeat();
    });
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
