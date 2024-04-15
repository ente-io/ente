import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/module/upload/model/multipart.dart";
import "package:photos/module/upload/model/xml.dart";
import "package:photos/services/feature_flag_service.dart";
import "package:photos/utils/crypto_util.dart";

class MultiPartUploader {
  final Dio _enteDio;
  final Dio _s3Dio;
  final UploadLocksDB _db;
  final FeatureFlagService _featureFlagService;
  late final Logger _logger = Logger("MultiPartUploader");

  MultiPartUploader(
    this._enteDio,
    this._s3Dio,
    this._db,
    this._featureFlagService,
  ) {}

  Future<int> calculatePartCount(int fileSize) async {
    final partCount = (fileSize / multipartPartSizeForUpload).ceil();
    return partCount;
  }

  Future<MultipartUploadURLs> getMultipartUploadURLs(int count) async {
    try {
      assert(
        _featureFlagService.isInternalUserOrDebugBuild(),
        "Multipart upload should not be enabled for external users.",
      );
      final response = await _enteDio.get(
        "/files/multipart-upload-urls",
        queryParameters: {
          "count": count,
        },
      );

      return MultipartUploadURLs.fromMap(response.data);
    } on Exception catch (e) {
      _logger.severe('failed to get multipart url', e);
      rethrow;
    }
  }

  Future<void> createTableEntry(
    String localId,
    String fileHash,
    MultipartUploadURLs urls,
    String encryptedFilePath,
    int fileSize,
    Uint8List fileKey,
  ) async {
    await _db.createTrackUploadsEntry(
      localId,
      fileHash,
      urls,
      encryptedFilePath,
      fileSize,
      CryptoUtil.bin2base64(fileKey),
    );
  }

  Future<String> putExistingMultipartFile(
    File encryptedFile,
    String localId,
    String fileHash,
  ) async {
    final (urls, status) = await _db.getCachedLinks(localId, fileHash);

    Map<int, String> etags = urls.partETags ?? {};

    if (status == UploadLocksDB.trackStatus.pending) {
      // upload individual parts and get their etags
      etags = await uploadParts(urls, encryptedFile);
    }

    if (status != UploadLocksDB.trackStatus.completed) {
      // complete the multipart upload
      await completeMultipartUpload(urls.objectKey, etags, urls.completeURL);
    }

    return urls.objectKey;
  }

  Future<String> putMultipartFile(
    MultipartUploadURLs urls,
    File encryptedFile,
  ) async {
    // upload individual parts and get their etags
    final etags = await uploadParts(urls, encryptedFile);

    // complete the multipart upload
    await completeMultipartUpload(urls.objectKey, etags, urls.completeURL);

    return urls.objectKey;
  }

  Future<Map<int, String>> uploadParts(
    MultipartUploadURLs url,
    File encryptedFile,
  ) async {
    final partsURLs = url.partsURLs;
    final partUploadStatus = url.partUploadStatus;
    final partsLength = partsURLs.length;
    final etags = url.partETags ?? <int, String>{};

    for (int i = 0; i < partsLength; i++) {
      if (i < (partUploadStatus?.length ?? 0) &&
          (partUploadStatus?[i] ?? false)) {
        continue;
      }
      final partURL = partsURLs[i];
      final isLastPart = i == partsLength - 1;
      final fileSize = isLastPart
          ? encryptedFile.lengthSync() % multipartPartSizeForUpload
          : multipartPartSizeForUpload;

      final response = await _s3Dio.put(
        partURL,
        data: encryptedFile.openRead(
          i * multipartPartSizeForUpload,
          isLastPart ? null : (i + 1) * multipartPartSizeForUpload,
        ),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileSize,
          },
        ),
      );

      final eTag = response.headers.value("etag");

      if (eTag?.isEmpty ?? true) {
        throw Exception('ETAG_MISSING');
      }

      etags[i] = eTag!;

      await _db.updatePartStatus(url.objectKey, i, eTag);
    }
    await _db.updateTrackUploadStatus(
      url.objectKey,
      UploadLocksDB.trackStatus.uploaded,
    );

    return etags;
  }

  Future<void> completeMultipartUpload(
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
        UploadLocksDB.trackStatus.completed,
      );
    } catch (e) {
      Logger("MultipartUpload").severe(e);
      rethrow;
    }
  }
}
