import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/encryption_result.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

class FileUploader {
  final _logger = Logger("FileUploader");
  final _dio = Network.instance.getDio();
  final _queue = LinkedHashMap<int, FileUploadItem>();
  final _maximumConcurrentUploads = 4;
  int _currentlyUploading = 0;
  final _uploadURLs = Queue<UploadURL>();

  FileUploader._privateConstructor() {
    Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      _uploadURLFetchInProgress = null;
    });
  }
  static FileUploader instance = FileUploader._privateConstructor();

  Future<File> upload(File file, int collectionID) {
    // If the file hasn't been queued yet, queue it
    if (!_queue.containsKey(file.generatedID)) {
      final completer = Completer<File>();
      _queue[file.generatedID] = FileUploadItem(file, collectionID, completer);
      _pollQueue();
      return completer.future;
    }

    // If the file exists in the queue for a matching collectionID,
    // return the existing future
    final item = _queue[file.generatedID];
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
    // If the file hasn't been queued yet, ez.
    if (!_queue.containsKey(file.generatedID)) {
      final completer = Completer<File>();
      _queue[file.generatedID] = FileUploadItem(
        file,
        collectionID,
        completer,
        status: UploadStatus.in_progress,
      );
      _encryptAndUploadFileToCollection(file, collectionID, forcedUpload: true);
      return completer.future;
    }
    var item = _queue[file.generatedID];
    // If the file is being uploaded right now, wait and proceed
    if (item.status == UploadStatus.in_progress) {
      return item.completer.future.then((uploadedFile) async {
        if (uploadedFile.collectionID == collectionID) {
          // Do nothing
          return uploadedFile;
        } else {
          return CollectionsService.instance
              .addToCollection(collectionID, [uploadedFile]).then((aVoid) {
            return uploadedFile;
          });
        }
      });
    } else {
      // If the file is yet to be processed,
      // 1. Remove it from the queue,
      // 2. Force upload the current file
      // 3. Trigger the callback for the original request
      item = _queue.remove(file.generatedID);
      return _encryptAndUploadFileToCollection(file, collectionID,
              forcedUpload: true)
          .then((uploadedFile) {
        if (item.collectionID == collectionID) {
          item.completer.complete(uploadedFile);
          return uploadedFile;
        } else {
          CollectionsService.instance
              .addToCollection(item.collectionID, [uploadedFile]).then((aVoid) {
            item.completer.complete(uploadedFile);
          });
          return uploadedFile;
        }
      });
    }
  }

  void clearQueue() {
    final uploadsToBeRemoved = List<int>();
    _queue.entries
        .where((entry) => entry.value.status == UploadStatus.not_started)
        .forEach((pendingUpload) {
      uploadsToBeRemoved.add(pendingUpload.key);
    });
    for (final id in uploadsToBeRemoved) {
      _queue.remove(id).completer.completeError(SyncStopRequestedError());
    }
  }

  void _pollQueue() {
    if (SyncService.instance.shouldStopSync()) {
      clearQueue();
    }
    if (_queue.length > 0 && _currentlyUploading < _maximumConcurrentUploads) {
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
      _queue.remove(file.generatedID).completer.complete(uploadedFile);
    } catch (e) {
      _queue.remove(file.generatedID).completer.completeError(e);
    } finally {
      _currentlyUploading--;
      _pollQueue();
    }
    return null;
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

    final tempDirectory = Configuration.instance.getTempDirectory();
    final encryptedFilePath =
        tempDirectory + file.generatedID.toString() + ".encrypted";
    final encryptedThumbnailPath =
        tempDirectory + file.generatedID.toString() + "_thumbnail.encrypted";
    var sourceFile;

    try {
      // Placing this in the try-catch block to safe guard against: https://github.com/CaiJingLong/flutter_photo_manager/issues/405
      sourceFile = (await (await file.getAsset()).originFile);
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

      var thumbnailData = (await (await file.getAsset()).thumbDataWithSize(
        THUMBNAIL_LARGE_SIZE,
        THUMBNAIL_LARGE_SIZE,
        quality: 50,
      ));
      if (thumbnailData == null) {
        _logger.severe("Could not generate thumbnail for " + file.toString());
        await FilesDB.instance.deleteLocalFile(file.localID);
        throw InvalidFileError();
      }
      final thumbnailSize = thumbnailData.length;
      if (thumbnailSize > THUMBNAIL_DATA_LIMIT) {
        thumbnailData = await compressThumbnail(thumbnailData);
        _logger.info("Thumbnail size " + thumbnailSize.toString());
        _logger.info(
            "Compressed thumbnail size " + thumbnailData.length.toString());
      }

      final encryptedThumbnailData =
          CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key);
      if (io.File(encryptedThumbnailPath).existsSync()) {
        io.File(encryptedThumbnailPath).deleteSync();
      }
      final encryptedThumbnailFile = io.File(encryptedThumbnailPath);
      encryptedThumbnailFile
          .writeAsBytesSync(encryptedThumbnailData.encryptedData);

      final fileUploadURL = await _getUploadURL();
      String fileObjectKey = await _putFile(fileUploadURL, encryptedFile);

      final thumbnailUploadURL = await _getUploadURL();
      String thumbnailObjectKey =
          await _putFile(thumbnailUploadURL, encryptedThumbnailFile);

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
      if (isAlreadyUploadedFile) {
        final updatedFile = await _updateFile(
          file,
          fileObjectKey,
          fileDecryptionHeader,
          thumbnailObjectKey,
          thumbnailDecryptionHeader,
          encryptedMetadata,
          metadataDecryptionHeader,
        );
        // Update across all collections
        await FilesDB.instance.updateUploadedFileAcrossCollections(updatedFile);
        return updatedFile;
      } else {
        final uploadedFile = await _uploadFile(
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
        await FilesDB.instance.update(uploadedFile);
        return uploadedFile;
      }
    } catch (e, s) {
      if (!(e is NoActiveSubscriptionError)) {
        _logger.severe(
            "File upload failed for " + file.generatedID.toString(), e, s);
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
    }
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
      if (e.response.statusCode == 426) {
        throw StorageLimitExceededError();
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
      if (e.response.statusCode == 426) {
        throw StorageLimitExceededError();
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
      final completer = Completer<void>();
      _uploadURLFetchInProgress = completer.future;
      try {
        final response = await _dio.get(
          Configuration.instance.getHttpEndpoint() + "/files/upload-urls",
          queryParameters: {
            "count": 42, // m4gic number
          },
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        );
        final urls = (response.data["urls"] as List)
            .map((e) => UploadURL.fromMap(e))
            .toList();
        _uploadURLs.addAll(urls);
      } on DioError catch (e) {
        if (e.response.statusCode == 402) {
          throw NoActiveSubscriptionError();
        }
        throw e;
      }
      _uploadURLFetchInProgress = null;
      completer.complete();
    }
    return _uploadURLFetchInProgress;
  }

  Future<String> _putFile(UploadURL uploadURL, io.File file,
      {int contentLength}) async {
    final fileSize = contentLength ?? file.lengthSync();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    _logger.info(
        "Putting file of size " + fileSize.toString() + " to " + uploadURL.url);
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
          "HttpException: Content size exceeds specified contentLength.")) {
        return _putFile(uploadURL, file,
            contentLength: file.readAsBytesSync().length);
      } else {
        throw e;
      }
    }
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
  completed,
}

class InvalidFileError extends Error {}

class WiFiUnavailableError extends Error {}

class SyncStopRequestedError extends Error {}

class NoActiveSubscriptionError extends Error {}

class StorageLimitExceededError extends Error {}
