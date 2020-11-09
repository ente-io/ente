import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';

class FileUploader {
  final _logger = Logger("FileUploader");
  final _dio = Dio();
  final _queue = LinkedHashMap<int, FileUploadItem>();
  final _maximumConcurrentUploads = 4;
  int _currentlyUploading = 0;
  final _uploadURLs = Queue<UploadURL>();

  FileUploader._privateConstructor();
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
      return _encryptAndUploadFileToCollection(file, collectionID,
          forcedUpload: true);
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

  void _pollQueue() {
    if (_queue.length > 0 && _currentlyUploading < _maximumConcurrentUploads) {
      final firstPendingEntry = _queue.entries
          .firstWhere((entry) => entry.value.status == UploadStatus.not_started)
          .value;
      firstPendingEntry.status = UploadStatus.in_progress;
      _encryptAndUploadFileToCollection(
          firstPendingEntry.file, firstPendingEntry.collectionID);
    }
  }

  Future<File> _encryptAndUploadFileToCollection(File file, int collectionID,
      {bool forcedUpload = false}) async {
    _logger.info("Uploading " + file.toString());
    if (!forcedUpload) {
      _currentlyUploading++;
    }
    try {
      final uploadedFile = await _tryToUpload(file, collectionID, forcedUpload);
      await FilesDB.instance.update(uploadedFile);
      if (!forcedUpload) {
        _queue.remove(file.generatedID).completer.complete(uploadedFile);
      }
    } catch (e, s) {
      _logger.severe(
          "File upload failed for file ID " + file.generatedID.toString(),
          e,
          s);
      if (!forcedUpload) {
        _queue.remove(file.generatedID).completer.completeError(e);
      }
    } finally {
      if (!forcedUpload) {
        _currentlyUploading--;
        _pollQueue();
      }
    }
    return null;
  }

  Future<File> _tryToUpload(
      File file, int collectionID, bool forcedUpload) async {
    final encryptedFileName = file.generatedID.toString() + ".encrypted";
    final tempDirectory = Configuration.instance.getTempDirectory();
    final encryptedFilePath = tempDirectory + encryptedFileName;

    final sourceFile = (await (await file.getAsset()).originFile);
    final encryptedFile = io.File(encryptedFilePath);
    final fileAttributes =
        await CryptoUtil.encryptFile(sourceFile.path, encryptedFilePath);

    final fileUploadURL = await _getUploadURL();
    String fileObjectKey = await _putFile(fileUploadURL, encryptedFile);

    final thumbnailData = (await (await file.getAsset()).thumbDataWithSize(
      THUMBNAIL_LARGE_SIZE,
      THUMBNAIL_LARGE_SIZE,
      quality: 50,
    ));
    final encryptedThumbnailName =
        file.generatedID.toString() + "_thumbnail.encrypted";
    final encryptedThumbnailPath = tempDirectory + encryptedThumbnailName;
    final encryptedThumbnailData =
        CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key);
    final encryptedThumbnail = io.File(encryptedThumbnailPath);
    encryptedThumbnail.writeAsBytesSync(encryptedThumbnailData.encryptedData);

    final thumbnailUploadURL = await _getUploadURL();
    String thumbnailObjectKey =
        await _putFile(thumbnailUploadURL, encryptedThumbnail);

    // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
    if (file.location.latitude == 0 && file.location.longitude == 0) {
      final latLong = await (await file.getAsset()).latlngAsync();
      file.location = Location(latLong.latitude, latLong.longitude);
    }

    final encryptedMetadataData = CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(file.getMetadata())), fileAttributes.key);

    final encryptedFileKeyData = CryptoUtil.encryptSync(
      fileAttributes.key,
      CollectionsService.instance.getCollectionKey(collectionID),
    );

    final encryptedKey = Sodium.bin2base64(encryptedFileKeyData.encryptedData);
    final keyDecryptionNonce = Sodium.bin2base64(encryptedFileKeyData.nonce);
    final fileDecryptionHeader = Sodium.bin2base64(fileAttributes.header);
    final thumbnailDecryptionHeader =
        Sodium.bin2base64(encryptedThumbnailData.header);
    final encryptedMetadata =
        Sodium.bin2base64(encryptedMetadataData.encryptedData);
    final metadataDecryptionHeader =
        Sodium.bin2base64(encryptedMetadataData.header);

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
    final response = await _dio.post(
      Configuration.instance.getHttpEndpoint() + "/files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: request,
    );
    encryptedFile.deleteSync();
    encryptedThumbnail.deleteSync();
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
  }

  Future<UploadURL> _getUploadURL() async {
    if (_uploadURLs.isEmpty) {
      await _fetchUploadURLs();
    }
    return _uploadURLs.removeFirst();
  }

  Future<void> _uploadURLFetchInProgress;

  Future<void> _fetchUploadURLs() {
    if (_uploadURLFetchInProgress == null) {
      _uploadURLFetchInProgress = Dio()
          .get(
        Configuration.instance.getHttpEndpoint() + "/files/upload-urls",
        queryParameters: {
          "count": 42, // m4gic number
        },
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      )
          .then((response) {
        _uploadURLFetchInProgress = null;
        final urls = (response.data["urls"] as List)
            .map((e) => UploadURL.fromMap(e))
            .toList();
        _uploadURLs.addAll(urls);
      });
    }
    return _uploadURLFetchInProgress;
  }

  Future<String> _putFile(UploadURL uploadURL, io.File file) async {
    final fileSize = file.lengthSync().toString();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    _logger.info("Putting file of size " + fileSize + " to " + uploadURL.url);
    return Dio()
        .put(uploadURL.url,
            data: file.openRead(),
            options: Options(headers: {
              Headers.contentLengthHeader: await file.length(),
            }))
        .catchError((e) {
      _logger.severe(e);
      throw e;
    }).then((value) {
      _logger.info("Upload speed : " +
          (file.lengthSync() /
                  (DateTime.now().millisecondsSinceEpoch - startTime))
              .toString() +
          " kilo bytes per second");
      return uploadURL.objectKey;
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
  completed,
}
