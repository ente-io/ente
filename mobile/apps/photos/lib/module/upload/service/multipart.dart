import "dart:io";

import "package:dio/dio.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/errors.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/module/upload/model/multipart.dart";
import "package:photos/module/upload/model/xml.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_util.dart";

class MultiPartUploader {
  final Dio _enteDio;
  final Dio _s3Dio;
  final UploadLocksDB _db;
  final FlagService _featureFlagService;
  late final Logger _logger = Logger("MultiPartUploader");

  MultiPartUploader(
    this._enteDio,
    this._s3Dio,
    this._db,
    this._featureFlagService,
  );

  Future<FileEncryptResult> getEncryptionResult(
    String localId,
    String fileHash,
    int collectionID,
    String encFileName,
  ) async {
    final collectionKey =
        CollectionsService.instance.getCollectionKey(collectionID);
    final result = await _db.getFileEncryptionData(
      localId,
      fileHash,
      collectionID,
      encFileName,
    );
    final encryptedFileKey = CryptoUtil.base642bin(result.encryptedFileKey);
    final fileNonce = CryptoUtil.base642bin(result.fileNonce);

    final encryptKeyNonce = CryptoUtil.base642bin(result.keyNonce);

    // Get the full multipart info to access MD5 data
    final multipartInfo = await _db.getCachedLinks(
      localId,
      fileHash,
      collectionID,
      encFileName,
    );

    return FileEncryptResult(
      key: CryptoUtil.decryptSync(
        encryptedFileKey,
        collectionKey,
        encryptKeyNonce,
      ),
      header: fileNonce,
      fileMd5: multipartInfo.fileMd5,
      partMd5s: multipartInfo.partMd5s,
      partSize: multipartInfo.partSize,
    );
  }

  int get multipartPartSizeForUpload {
    return multipartPartSize;
  }

  int calculatePartCount(int fileSize) {
    // If the feature flag is disabled, return 1
    if (!_featureFlagService.enableMobMultiPart) return 1;
    if (!localSettings.userEnabledMultiplePart) return 1;

    final partCount = (fileSize / multipartPartSizeForUpload).ceil();
    return partCount;
  }

  Future<MultipartUploadURLs> getMultipartUploadURLs({
    required int count,
    required int contentLength,
    required int partLength,
    List<String>? partMd5s,
  }) async {
    try {
      if (flagService.internalUser && partMd5s != null && partMd5s.isNotEmpty) {
        final response = await _enteDio.post(
          "/files/multipart-upload-url",
          data: {
            "contentLength": contentLength,
            "partLength": partLength,
            "partMd5s": partMd5s,
          },
        );
        return MultipartUploadURLs.fromMap(
          (response.data as Map).cast<String, dynamic>(),
        );
      }

      final response = await _enteDio.get(
        "/files/multipart-upload-urls",
        queryParameters: {
          "count": count,
        },
      );
      return MultipartUploadURLs.fromMap(
        (response.data as Map).cast<String, dynamic>(),
      );
    } on Exception catch (e) {
      _logger.severe('failed to get multipart url', e);
      rethrow;
    }
  }

  Future<void> createTableEntry(
    String localId,
    String fileHash,
    int collectionID,
    MultipartUploadURLs urls,
    String encryptedFileName,
    int fileSize,
    Uint8List fileKey,
    Uint8List fileNonce, {
    String? fileMd5,
    List<String>? partMd5s,
  }) async {
    final collectionKey =
        CollectionsService.instance.getCollectionKey(collectionID);

    final encryptedResult = CryptoUtil.encryptSync(
      fileKey,
      collectionKey,
    );

    await _db.createTrackUploadsEntry(
      localId,
      fileHash,
      collectionID,
      urls,
      encryptedFileName,
      fileSize,
      CryptoUtil.bin2base64(encryptedResult.encryptedData!),
      CryptoUtil.bin2base64(fileNonce),
      CryptoUtil.bin2base64(encryptedResult.nonce!),
      partSize: multipartPartSizeForUpload,
      fileMd5: fileMd5,
      partMd5s: partMd5s,
    );
  }

  Future<String> putExistingMultipartFile(
    File encryptedFile,
    String localId,
    String fileHash,
    int collectionID,
    String encryptedFileName,
  ) async {
    final multipartInfo = await _db.getCachedLinks(
      localId,
      fileHash,
      collectionID,
      encryptedFileName,
    );
    await _db.updateLastAttempted(localId, fileHash, collectionID);

    Map<int, String> etags = multipartInfo.partETags ?? {};

    if (multipartInfo.status == MultipartStatus.pending) {
      // upload individual parts and get their etags
      try {
        etags = await _uploadParts(multipartInfo, encryptedFile);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          _logger.severe(
            "Multipart upload not found for key ${multipartInfo.urls.objectKey}",
          );
          await _db.deleteMultipartTrack(localId);
        }
        if (e.response?.statusCode == 401) {
          _logger.severe(
            "Multipart upload not authorized ${multipartInfo.urls.objectKey}",
          );
          await _db.deleteMultipartTrack(localId);
        }
        rethrow;
      }
    }

    if (multipartInfo.status != MultipartStatus.completed) {
      // complete the multipart upload
      try {
        await _completeMultipartUpload(
          multipartInfo.urls.objectKey,
          etags,
          multipartInfo.urls.completeURL,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          _logger.severe(
            "Multipart upload not found for key ${multipartInfo.urls.objectKey}",
          );
          await _db.deleteMultipartTrack(localId);
        }
        if (e.response?.statusCode == 401) {
          _logger.severe(
            "Multipart upload not authorized ${multipartInfo.urls.objectKey}",
          );
          await _db.deleteMultipartTrack(localId);
        }
        rethrow;
      }
    }

    return multipartInfo.urls.objectKey;
  }

  Future<String> putMultipartFile(
    MultipartUploadURLs urls,
    File encryptedFile,
    int fileSize, {
    String? fileMd5,
    List<String>? partMd5s,
  }) async {
    // upload individual parts and get their etags
    final etags = await _uploadParts(
      MultipartInfo(
        urls: urls,
        encFileSize: fileSize,
        fileMd5: fileMd5,
        partMd5s: partMd5s,
      ),
      encryptedFile,
    );

    // complete the multipart upload
    await _completeMultipartUpload(urls.objectKey, etags, urls.completeURL);

    return urls.objectKey;
  }

  Future<Map<int, String>> _uploadParts(
    MultipartInfo partInfo,
    File encryptedFile,
  ) async {
    final partsURLs = partInfo.urls.partsURLs;
    final partUploadStatus = partInfo.partUploadStatus;
    final partsLength = partsURLs.length;
    final etags = partInfo.partETags ?? <int, String>{};
    final partMd5s = partInfo.partMd5s;

    int i = 0;
    final partSize = partInfo.partSize ?? multipartPartSizeForUpload;

    // Go to the first part that is not uploaded
    while (i < (partUploadStatus?.length ?? 0) &&
        (partUploadStatus?[i] ?? false)) {
      i++;
    }

    final int encFileLength = encryptedFile.lengthSync();
    if (encFileLength != partInfo.encFileSize) {
      throw Exception(
        "File size mismatch. Expected ${partInfo.encFileSize} but got $encFileLength",
      );
    }
    // Start parts upload
    int count = 0;
    while (i < partsLength) {
      count++;
      final partURL = partsURLs[i];
      final isLastPart = i == partsLength - 1;
      final fileSize = isLastPart ? encFileLength % partSize : partSize;
      _logger.info(
        "Uploading part ${i + 1} / $partsLength of size $fileSize bytes (total size $encFileLength).",
      );
      if (kDebugMode && count > 3) {
        throw Exception(
          'Forced exception to test multipart upload retry mechanism.',
        );
      }

      final headers = {
        Headers.contentLengthHeader: fileSize,
        Headers.contentTypeHeader: "application/octet-stream",
      };

      // Add MD5 header if available for this part
      if (partMd5s != null && i < partMd5s.length) {
        headers['Content-MD5'] = partMd5s[i];
      } else if (kDebugMode) {
        AssertionError('Part MD5s not available for part ${i + 1}');
      }

      try {
        final response = await _s3Dio.put(
          partURL,
          data: encryptedFile.openRead(
            i * partSize,
            isLastPart ? null : (i + 1) * partSize,
          ),
          options: Options(
            headers: headers,
          ),
        );

        final eTag = response.headers.value("etag");

        if (eTag?.isEmpty ?? true) {
          throw Exception('ETAG_MISSING');
        }

        etags[i] = eTag!;

        await _db.updatePartStatus(partInfo.urls.objectKey, i, eTag);
        i++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 400 &&
                e.response?.data.toString().contains('BadDigest') == true ||
            e.response?.data.toString().contains('InvalidDigest') == true) {
          final recomputedMD5 = await computeMd5(
            encryptedFile.path,
            start: i * partSize,
            end: isLastPart ? null : (i + 1) * partSize,
          );
          throw BadMD5DigestError(
            "Failed for part ${i + 1} ${e.response?.data}, sent: ${partMd5s?[i]}, computed: $recomputedMD5",
          );
        }
        rethrow;
      }
    }

    await _db.updateTrackUploadStatus(
      partInfo.urls.objectKey,
      MultipartStatus.uploaded,
    );

    return etags;
  }

  Future<void> _completeMultipartUpload(
    String objectKey,
    Map<int, String> partEtags,
    String completeURL,
  ) async {
    final body = convertJs2Xml({
      'CompleteMultipartUpload': partEtags.entries
          .map(
            (e) => PartETag(
              e.key + 1,
              e.value,
            ),
          )
          .toList(),
    }).replaceAll('"', '').replaceAll('&quot;', '');

    try {
      await _s3Dio.post(
        completeURL,
        data: body,
        options: Options(
          contentType: "text/xml",
        ),
      );
      await _db.updateTrackUploadStatus(
        objectKey,
        MultipartStatus.completed,
      );
    } catch (e) {
      Logger("MultipartUpload").severe("upload failed for key $objectKey}", e);
      rethrow;
    }
  }
}
