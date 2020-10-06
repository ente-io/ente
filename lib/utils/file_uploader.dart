import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:photos/utils/file_util.dart';

class FileUploader {
  final _logger = Logger("FileUploader");
  final _dio = Dio();

  Future<UploadURL> getUploadURL() {
    return Dio()
        .get(
          Configuration.instance.getHttpEndpoint() +
              "/encrypted-files/upload-url",
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .then((response) => UploadURL.fromMap(response.data));
  }

  Future<String> putFile(UploadURL uploadURL, io.File file) async {
    _logger.info("Putting file to " + uploadURL.url);
    return Dio()
        .put(uploadURL.url,
            data: file.openRead(),
            options: Options(headers: {
              Headers.contentLengthHeader: await file.length(),
            }))
        .catchError((e) {
      _logger.severe(e);
    }).then((value) {
      return uploadURL.objectKey;
    });
  }

  Future<File> encryptAndUploadFile(File file) async {
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
        CryptoUtil.encryptChaCha(thumbnailData, fileAttributes.key.bytes);
    io.File(encryptedThumbnailPath)
        .writeAsBytesSync(encryptedThumbnail.encryptedData);

    final thumbnailUploadURL = await getUploadURL();
    String thumbnailObjectKey =
        await putFile(thumbnailUploadURL, io.File(encryptedThumbnailPath));

    final encryptedMetadata = CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(file.getMetadata())), fileAttributes.key.bytes);

    final encryptedFileKey = await CryptoUtil.encrypt(
      fileAttributes.key.bytes,
      key: Configuration.instance.getKey(),
    );

    final data = {
      "encryptedKey": encryptedFileKey.encryptedData.base64,
      "keyDecryptionNonce": encryptedFileKey.nonce.base64,
      "file": {
        "objectKey": fileObjectKey,
        "header": fileAttributes.header.base64,
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "header": Sodium.bin2base64(encryptedThumbnail.header),
      },
      "metadata": {
        "encryptedData": Sodium.bin2base64(encryptedMetadata.encryptedData),
        "header": Sodium.bin2base64(encryptedMetadata.header),
      }
    };
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/encrypted-files",
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
      file.encryptedKey = encryptedFileKey.encryptedData.base64;
      file.keyDecryptionNonce = encryptedFileKey.nonce.base64;
      file.fileDecryptionHeader = fileAttributes.header.base64;
      file.thumbnailDecryptionHeader =
          Sodium.bin2base64(encryptedThumbnail.header);
      file.metadataDecryptionHeader =
          Sodium.bin2base64(encryptedMetadata.header);
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
