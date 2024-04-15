// ignore_for_file: implementation_imports

import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/services/feature_flag_service.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/xml_parser_util.dart";

final _enteDio = NetworkClient.instance.enteDio;
final _dio = NetworkClient.instance.getDio();
final _uploadLocksDb = UploadLocksDB.instance;

class PartETag extends XmlParsableObject {
  final int partNumber;
  final String eTag;

  PartETag(this.partNumber, this.eTag);

  @override
  String get elementName => "Part";

  @override
  Map<String, dynamic> toMap() {
    return {
      "PartNumber": partNumber,
      "ETag": eTag,
    };
  }
}

class MultipartUploadURLs {
  final String objectKey;
  final List<String> partsURLs;
  final String completeURL;
  final List<bool>? partUploadStatus;
  final Map<int, String>? partETags;

  MultipartUploadURLs({
    required this.objectKey,
    required this.partsURLs,
    required this.completeURL,
    this.partUploadStatus,
    this.partETags,
  });

  factory MultipartUploadURLs.fromMap(Map<String, dynamic> map) {
    return MultipartUploadURLs(
      objectKey: map["urls"]["objectKey"],
      partsURLs: (map["urls"]["partURLs"] as List).cast<String>(),
      completeURL: map["urls"]["completeURL"],
    );
  }
}

Future<int> calculatePartCount(int fileSize) async {
  final partCount = (fileSize / multipartPartSizeForUpload).ceil();
  return partCount;
}

Future<MultipartUploadURLs> getMultipartUploadURLs(int count) async {
  try {
    assert(
      FeatureFlagService.instance.isInternalUserOrDebugBuild(),
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
    Logger("MultipartUploadURL").severe(e);
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
  await _uploadLocksDb.createTrackUploadsEntry(
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
  final (urls, status) = await _uploadLocksDb.getCachedLinks(localId, fileHash);

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

    final response = await _dio.put(
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

    await _uploadLocksDb.updatePartStatus(url.objectKey, i, eTag);
  }
  await _uploadLocksDb.updateTrackUploadStatus(
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
    await _dio.post(
      completeURL,
      data: body,
      options: Options(
        contentType: "text/xml",
      ),
    );
    await _uploadLocksDb.updateTrackUploadStatus(
      objectKey,
      UploadLocksDB.trackStatus.completed,
    );
  } catch (e) {
    Logger("MultipartUpload").severe(e);
    rethrow;
  }
}
