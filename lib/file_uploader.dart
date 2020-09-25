import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/decryption_params.dart';
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
        await CryptoUtil.chachaEncrypt(sourceFile, encryptedFile);

    final fileUploadURL = await getUploadURL();
    String fileObjectKey = await putFile(fileUploadURL, encryptedFile);

    final encryptedFileKey = await CryptoUtil.encrypt(
      fileAttributes.key.bytes,
      key: Configuration.instance.getKey(),
    );
    final fileDecryptionParams = DecryptionParams(
      encryptedKey: encryptedFileKey.encryptedData.base64,
      keyDecryptionNonce: encryptedFileKey.nonce.base64,
      header: fileAttributes.header.base64,
    );

    final thumbnailData = (await (await file.getAsset()).thumbDataWithSize(
      THUMBNAIL_LARGE_SIZE,
      THUMBNAIL_LARGE_SIZE,
      quality: 50,
    ));
    final encryptedThumbnailName =
        file.generatedID.toString() + "_thumbnail.encrypted";
    final encryptedThumbnailPath = tempDirectory + encryptedThumbnailName;
    final encryptedThumbnail = await CryptoUtil.encrypt(thumbnailData);
    io.File(encryptedThumbnailPath)
        .writeAsBytesSync(encryptedThumbnail.encryptedData.bytes);

    final thumbnailUploadURL = await getUploadURL();
    String thumbnailObjectKey =
        await putFile(thumbnailUploadURL, io.File(encryptedThumbnailPath));

    final encryptedThumbnailKey = await CryptoUtil.encrypt(
      encryptedThumbnail.key.bytes,
      key: Configuration.instance.getKey(),
    );
    final thumbnailDecryptionParams = DecryptionParams(
      encryptedKey: encryptedThumbnailKey.encryptedData.base64,
      keyDecryptionNonce: encryptedThumbnailKey.nonce.base64,
      nonce: encryptedThumbnail.nonce.base64,
    );

    final metadata = jsonEncode(file.getMetadata());
    final encryptedMetadata = await CryptoUtil.encrypt(utf8.encode(metadata));
    final encryptedMetadataKey = await CryptoUtil.encrypt(
      encryptedMetadata.key.bytes,
      key: Configuration.instance.getKey(),
    );
    final metadataDecryptionParams = DecryptionParams(
      encryptedKey: encryptedMetadataKey.encryptedData.base64,
      keyDecryptionNonce: encryptedMetadataKey.nonce.base64,
      nonce: encryptedMetadata.nonce.base64,
    );
    final data = {
      "file": {
        "objectKey": fileObjectKey,
        "decryptionParams": fileDecryptionParams.toMap(),
      },
      "thumbnail": {
        "objectKey": thumbnailObjectKey,
        "decryptionParams": thumbnailDecryptionParams.toMap(),
      },
      "metadata": {
        "encryptedData": encryptedMetadata.encryptedData.base64,
        "decryptionParams": metadataDecryptionParams.toMap(),
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
      file.fileDecryptionParams = fileDecryptionParams;
      file.thumbnailDecryptionParams = thumbnailDecryptionParams;
      file.metadataDecryptionParams = metadataDecryptionParams;
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
