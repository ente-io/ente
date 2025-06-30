import "dart:convert";
import "dart:math";

import "package:computer/computer.dart";
import "package:dio/dio.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/log/devlog.dart";
import "package:photos/models/api/diff/diff.dart";

class RemoteFileDiffService {
  final Logger _logger = Logger("RemoteFileDiffService");
  final Dio _enteDio;

  RemoteFileDiffService(this._enteDio);
  Future<DiffResult> getCollectionItemsDiff(
    int collectionID,
    int sinceTime,
    Uint8List collectionKey,
  ) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2/diff",
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
        },
      );
      final List diff = response.data["diff"] as List;
      if (diff.isEmpty) {
        return DiffResult([], [], response.data["hasMore"] as bool, 0);
      }
      final String encodedKey = base64Encode(Uint8List.fromList(collectionKey));
      final startTime = DateTime.now();
      final DiffResult result =
          await Computer.shared().compute<Map<String, dynamic>, DiffResult>(
        _parseDiff,
        param: {
          "collectionKey": encodedKey,
          "diff": diff,
          "hasMore": response.data["hasMore"] as bool,
        },
        taskName: "parseDiff",
      );
      devLog(
        '[Collection-$collectionID] $result in ${DateTime.now().difference(startTime).inMilliseconds} ms',
        name: "CollectionFilesService.getCollectionItemsDiff",
      );
      return result;
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<DiffResult> getPublicCollectionDiff(
    int collectionID,
    int sinceTime,
    Uint8List collectionKey,
    Map<String, String> headers,
  ) async {
    final response = await _enteDio.get(
      "/public-collection/diff",
      options: Options(headers: headers),
      queryParameters: {"sinceTime": sinceTime},
    );
    final List diff = response.data["diff"] as List;
    if (diff.isEmpty) {
      return DiffResult([], [], response.data["hasMore"] as bool, 0);
    }
    final String encodedKey = base64Encode(Uint8List.fromList(collectionKey));
    final startTime = DateTime.now();
    final DiffResult result =
        await Computer.shared().compute<Map<String, dynamic>, DiffResult>(
      _parseDiff,
      param: {
        "collectionKey": encodedKey,
        "diff": diff,
        "hasMore": response.data["hasMore"] as bool,
      },
      taskName: "parseDiff",
    );
    devLog(
      '[Collection-$collectionID] $result in ${DateTime.now().difference(startTime).inMilliseconds} ms',
      name: "CollectionFilesService.getCollectionItemsDiff",
    );
    return result;
  }

  DiffResult _parseDiff(Map<String, dynamic> args) {
    final Uint8List collectionKey = base64Decode(args['collectionKey']);
    final List diff = args['diff'] as List;
    final hasMore = args['hasMore'] as bool;
    int latestUpdatedAtTime = 0;
    final deletedFiles = <DiffItem>[];
    final updatedFiles = <DiffItem>[];
    final int defaultCreatedAt = DateTime.now().millisecondsSinceEpoch;

    for (final item in diff) {
      final int fileID = item["id"] as int;
      final int collectionID = item["collectionID"];
      final int ownerID = item["ownerID"];
      final int collectionUpdationTime = item["updationTime"];
      final bool isCollectionItemDeleted = item["isDeleted"];
      latestUpdatedAtTime = max(latestUpdatedAtTime, collectionUpdationTime);
      if (isCollectionItemDeleted) {
        final deletedItem = DiffItem(
          collectionID: collectionID,
          updatedAt: collectionUpdationTime,
          isDeleted: true,
          createdAt: item["createdAt"] ?? defaultCreatedAt,
          fileItem: ApiFileItem.deleted(fileID, ownerID),
        );
        deletedFiles.add(deletedItem);
        continue;
      }
      final Uint8List encFileKey = CryptoUtil.base642bin(item["encryptedKey"]);
      final Uint8List encFileKeyNonce =
          CryptoUtil.base642bin(item["keyDecryptionNonce"]);
      final ApiFileItem fileItem = constructFileItem(
        item,
        collectionKey,
        encFileKey,
        encFileKeyNonce,
      );
      final DiffItem file = DiffItem(
        collectionID: collectionID,
        updatedAt: collectionUpdationTime,
        encFileKey: encFileKey,
        encFileKeyNonce: encFileKeyNonce,
        isDeleted: false,
        createdAt: item["createdAt"] ?? defaultCreatedAt,
        fileItem: fileItem,
      );
      updatedFiles.add(file);
    }
    return DiffResult(
      updatedFiles,
      deletedFiles,
      hasMore,
      latestUpdatedAtTime,
    );
  }

  static ApiFileItem constructFileItem(
    Map<String, dynamic> item,
    Uint8List collectionKey,
    Uint8List encFileKey,
    Uint8List encFileKeyNonce,
  ) {
    final int fileID = item["id"] as int;
    final int ownerID = item["ownerID"];

    // Decrypt file key
    final fileKey =
        CryptoUtil.decryptSync(encFileKey, collectionKey, encFileKeyNonce);

    // Decrypt and parse metadata
    final encodedMetadata = CryptoUtil.decryptChaChaSync(
      CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
      fileKey,
      CryptoUtil.base642bin(item["metadata"]["decryptionHeader"]),
    );
    final Map<String, dynamic> defaultMeta =
        jsonDecode(utf8.decode(encodedMetadata));

    // Apply metadata defaults and fixes
    if (!defaultMeta.containsKey('version')) {
      defaultMeta['version'] = 0;
    }
    if (defaultMeta['hash'] == null &&
        defaultMeta.containsKey('imageHash') &&
        defaultMeta.containsKey('videoHash')) {
      // old web version was putting live photo hash in different fields
      defaultMeta['hash'] =
          '${defaultMeta['imageHash']}$kHashSeprator${defaultMeta['videoHash']}';
    }

    // Decrypt magic metadata if present
    Metadata? privateMagicMetadata;
    if (item['magicMetadata'] != null) {
      final utfEncodedMmd = CryptoUtil.decryptChaChaSync(
        CryptoUtil.base642bin(item['magicMetadata']['data']),
        fileKey,
        CryptoUtil.base642bin(item['magicMetadata']['header']),
      );
      privateMagicMetadata = Metadata(
        data: jsonDecode(utf8.decode(utfEncodedMmd)),
        version: item['magicMetadata']['version'],
      );
    }

    // Decrypt public magic metadata if present
    Metadata? pubMagicMetadata;
    if (item['pubMagicMetadata'] != null) {
      final utfEncodedMmd = CryptoUtil.decryptChaChaSync(
        CryptoUtil.base642bin(item['pubMagicMetadata']['data']),
        fileKey,
        CryptoUtil.base642bin(item['pubMagicMetadata']['header']),
      );
      pubMagicMetadata = Metadata(
        data: jsonDecode(utf8.decode(utfEncodedMmd)),
        version: item['pubMagicMetadata']['version'],
      );
    }

    // Extract decryption headers and info
    final String fileDecryptionHeader = item["file"]["decryptionHeader"];
    final String thumbnailDecryptionHeader =
        item["thumbnail"]["decryptionHeader"];
    final Info? info = Info.fromJson(item["info"]);

    return ApiFileItem(
      fileID: fileID,
      ownerID: ownerID,
      thumnailDecryptionHeader:
          CryptoUtil.base642bin(thumbnailDecryptionHeader),
      fileDecryptionHeader: CryptoUtil.base642bin(fileDecryptionHeader),
      metadata: Metadata(data: defaultMeta, version: 0),
      privMagicMetadata: privateMagicMetadata,
      pubMagicMetadata: pubMagicMetadata,
      info: info,
    );
  }
}

class DiffResult {
  final List<DiffItem> updatedItems;
  final List<DiffItem> deletedItems;
  final bool hasMore;
  final int maxUpdatedAtTime;
  DiffResult(
    this.updatedItems,
    this.deletedItems,
    this.hasMore,
    this.maxUpdatedAtTime,
  );

  @override
  String toString() {
    return 'Diff{Up: ${updatedItems.length}, Del: ${deletedItems.length}, more?: $hasMore, maxUpdateTime: $maxUpdatedAtTime}';
  }
}
