import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:photos/utils/file_util.dart';

class FileUploader {
  final _logger = Logger("FileUploader");
  final _dio = Dio();
  final _currentlyUploading = Map<int, Future<File>>();

  FileUploader._privateConstructor();
  static FileUploader instance = FileUploader._privateConstructor();

  Future<File> getCurrentUploadStatus(int generatedID) {
    return _currentlyUploading[generatedID];
  }

  Future<UploadURL> getUploadURL() {
    return Dio()
        .get(
          Configuration.instance.getHttpEndpoint() + "/files/upload-url",
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .then((response) => UploadURL.fromMap(response.data));
  }

  Future<String> putFile(UploadURL uploadURL, io.File file) async {
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

  Future<File> encryptAndUploadFile(File file) async {
    _currentlyUploading[file.generatedID] = _encryptAndUploadFile(file);
    return _currentlyUploading[file.generatedID];
  }

  Future<File> _encryptAndUploadFile(File file) async {
    _logger.info("Uploading " + file.toString());
    final encryptedFileName = file.generatedID.toString() + ".encrypted";
    final tempDirectory = Configuration.instance.getTempDirectory();
    final encryptedFilePath = tempDirectory + encryptedFileName;

    final sourceFile = (await (await file.getAsset()).originFile);
    final encryptedFile = io.File(encryptedFilePath);
    final fileAttributes =
        await CryptoUtil.encryptFile(sourceFile.path, encryptedFilePath);

    final fileUploadURL = await getUploadURL();
    String fileObjectKey = await putFile(fileUploadURL, encryptedFile);

    final thumbnailData = (await (await file.getAsset()).thumbDataWithSize(
      THUMBNAIL_LARGE_SIZE,
      THUMBNAIL_LARGE_SIZE,
      quality: 50,
    ));
    final encryptedThumbnailName =
        file.generatedID.toString() + "_thumbnail.encrypted";
    final encryptedThumbnailPath = tempDirectory + encryptedThumbnailName;
    final encryptedThumbnail =
        CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key);
    io.File(encryptedThumbnailPath)
        .writeAsBytesSync(encryptedThumbnail.encryptedData);

    final thumbnailUploadURL = await getUploadURL();
    String thumbnailObjectKey =
        await putFile(thumbnailUploadURL, io.File(encryptedThumbnailPath));

    // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
    if (file.location.latitude == 0 && file.location.longitude == 0) {
      final latLong = await (await file.getAsset()).latlngAsync();
      file.location = Location(latLong.latitude, latLong.longitude);
    }

    final encryptedMetadataData = CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(file.getMetadata())), fileAttributes.key);

    final encryptedFileKeyData = CryptoUtil.encryptSync(
      fileAttributes.key,
      CollectionsService.instance.getCollectionKey(file.collectionID),
    );

    final encryptedKey = Sodium.bin2base64(encryptedFileKeyData.encryptedData);
    final keyDecryptionNonce = Sodium.bin2base64(encryptedFileKeyData.nonce);
    final fileDecryptionHeader = Sodium.bin2base64(fileAttributes.header);
    final thumbnailDecryptionHeader =
        Sodium.bin2base64(encryptedThumbnail.header);
    final encryptedMetadata =
        Sodium.bin2base64(encryptedMetadataData.encryptedData);
    final metadataDecryptionHeader =
        Sodium.bin2base64(encryptedMetadataData.header);

    final data = {
      "collectionID": file.collectionID,
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
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: data,
    )
        .then((response) {
      encryptedFile.deleteSync();
      io.File(encryptedThumbnailPath).deleteSync();
      final data = response.data;
      file.uploadedFileID = data["id"];
      file.updationTime = data["updationTime"];
      file.ownerID = data["ownerID"];
      file.encryptedKey = encryptedKey;
      file.keyDecryptionNonce = keyDecryptionNonce;
      file.fileDecryptionHeader = fileDecryptionHeader;
      file.thumbnailDecryptionHeader = thumbnailDecryptionHeader;
      file.metadataDecryptionHeader = metadataDecryptionHeader;
      _currentlyUploading.remove(file.generatedID);
      return file;
    });
  }

  Future<File> uploadFile(File localPhoto) async {
    final title = getJPGFileNameForHEIC(localPhoto);
    final formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(await getBytesFromDisk(localPhoto),
          filename: title),
      "deviceFileID": localPhoto.localID,
      "deviceFolder": localPhoto.deviceFolder,
      "title": title,
      "creationTime": localPhoto.creationTime,
      "modificationTime": localPhoto.modificationTime,
    });
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: formData,
    )
        .then((response) {
      return File.fromJson(response.data);
    });
  }
}
