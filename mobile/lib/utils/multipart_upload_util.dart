// ignore_for_file: implementation_imports

import "dart:io";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/network/network.dart";
import "package:photos/db/upload_locks_db.dart";
import "package:photos/utils/xml_parser_util.dart";

final _enteDio = NetworkClient.instance.enteDio;
final _dio = NetworkClient.instance.getDio();

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

  MultipartUploadURLs({
    required this.objectKey,
    required this.partsURLs,
    required this.completeURL,
    this.partUploadStatus,
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
  final partCount = (fileSize / multipartPartSize).ceil();
  return partCount;
}

Future<MultipartUploadURLs> getMultipartUploadURLs(int count) async {
  try {
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
) async {
  await UploadLocksDB.instance.createTrackUploadsEntry(
    localId,
    fileHash,
    urls,
    encryptedFilePath,
    fileSize,
  );
}

Future<String> putExistingMultipartFile(
  File encryptedFile,
  String localId,
  String fileHash,
) async {
  final urls = await UploadLocksDB.instance.getCachedLinks(localId, fileHash);

  // upload individual parts and get their etags
  final etags = await uploadParts(urls, encryptedFile);

  // complete the multipart upload
  await completeMultipartUpload(urls.objectKey, etags, urls.completeURL);

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
  final etags = <int, String>{};

  for (int i = 0; i < partsLength; i++) {
    if (partUploadStatus?[i] ?? false) {
      continue;
    }
    final partURL = partsURLs[i];
    final isLastPart = i == partsLength - 1;
    final fileSize = isLastPart
        ? encryptedFile.lengthSync() % multipartPartSize
        : multipartPartSize;

    final response = await _dio.put(
      partURL,
      data: encryptedFile.openRead(
        i * multipartPartSize,
        isLastPart ? null : multipartPartSize,
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

    await UploadLocksDB.instance.updatePartStatus(url.objectKey, i);
  }

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
    await UploadLocksDB.instance.updateCompletionStatus(objectKey);
  } catch (e) {
    Logger("MultipartUpload").severe(e);
    rethrow;
  }
}
