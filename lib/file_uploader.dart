import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/upload_url.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_name_util.dart';
import 'package:photos/utils/file_util.dart';

class FileUploadManager {
  final _logger = Logger("FileUploadManager");
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
    final key = CryptoUtil.getSecureRandomBytes(length: 32);
    final base64EncodedKey = base64.encode(key);
    final iv = CryptoUtil.getSecureRandomBytes(length: 16);
    final base64EncodedIV = base64.encode(iv);
    final encryptedKey =
        CryptoUtil.aesEncrypt(key, Configuration.instance.getKey(), iv);
    final base64EncodedEncryptedKey = base64.encode(encryptedKey);

    final encryptedFileName = file.generatedID.toString() + ".aes";
    final tempDirectory = Configuration.instance.getTempDirectory();
    final encryptedFilePath = tempDirectory + encryptedFileName;
    await CryptoUtil.encryptDataToFile(
        await getBytesFromDisk(file), encryptedFilePath, key);

    final fileUploadURL = await getUploadURL();
    String fileObjectKey =
        await putFile(fileUploadURL, io.File(encryptedFilePath));

    final thumbnailData = (await (await file.getAsset())
        .thumbDataWithSize(THUMBNAIL_LARGE_SIZE, THUMBNAIL_LARGE_SIZE));
    final encryptedThumbnailName =
        file.generatedID.toString() + "_thumbnail.aes";
    final encryptedThumbnailPath = tempDirectory + encryptedThumbnailName;
    await CryptoUtil.encryptDataToFile(
        thumbnailData, encryptedThumbnailPath, key);

    final thumbnailUploadURL = await getUploadURL();
    String thumbnailObjectKey =
        await putFile(thumbnailUploadURL, io.File(encryptedThumbnailPath));

    final metadata = jsonEncode(file.getMetadata());
    final encryptedMetadata = await CryptoUtil.encryptDataToData(
        utf8.encode(metadata), key);
    final data = {
      "fileObjectKey": fileObjectKey,
      "thumbnailObjectKey": thumbnailObjectKey,
      "metadata": encryptedMetadata,
      "encryptedKey": base64EncodedEncryptedKey,
      "encryptedKeyIV": base64EncodedIV,
    };
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/encrypted-files",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      data: data,
    )
        .then((response) {
      io.File(encryptedFilePath).deleteSync();
      io.File(encryptedThumbnailPath).deleteSync();
      final data = response.data;
      file.uploadedFileID = data["id"];
      file.updationTime = data["updationTime"];
      file.ownerID = data["ownerID"];
      file.encryptedKey = base64EncodedEncryptedKey;
      file.encryptedKeyIV = base64EncodedIV;
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
