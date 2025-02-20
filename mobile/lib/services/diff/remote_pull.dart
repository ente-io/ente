// RemotePullService is a service that pulls the latest changes from the sever.
import "dart:convert";
import "dart:math";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:logging/logging.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_uploader_util.dart";

class RemoteDiffService {
  final Logger _logger = Logger('RemoteDiffService');
  final Dio _enteDio;
  RemoteDiffService(this._enteDio);

  Future<DiffResult> getCollectionItemsDiff(
    int collectionID,
    int sinceTime,
  ) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2/diff",
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
        },
      );
      int latestUpdatedAtTime = 0;
      final diff = response.data["diff"] as List;
      final bool hasMore = response.data["hasMore"] as bool;
      final startTime = DateTime.now();
      final deletedFiles = <CollectionFileItem>[];
      final updatedFiles = <CollectionFileItem>[];
      final Uint8List collectionKey =
          CollectionsService.instance.getCollectionKey(collectionID);

      for (final item in diff) {
        final int fileID = item["id"] as int;
        final int collectionID = item["collectionID"];
        final int ownerID = item["ownerID"];
        final int collectionUpdationTime = item["updationTime"];
        final bool isCollectionItemDeleted = item["isDeleted"];
        latestUpdatedAtTime = max(latestUpdatedAtTime, collectionUpdationTime);
        if (isCollectionItemDeleted) {
          final deletedItem = CollectionFileItem(
            collectionID: collectionID,
            updatedAt: collectionUpdationTime,
            isDeleted: true,
            createdAt:
                item["createdAt"] ?? DateTime.now().millisecondsSinceEpoch,
            fileItem: FileItem.deleted(fileID, ownerID),
          );
          deletedFiles.add(deletedItem);
          continue;
        }

        final Uint8List encFileKey =
            CryptoUtil.base642bin(item["encryptedKey"]);
        final Uint8List encFileKeyNonce =
            CryptoUtil.base642bin(item["keyDecryptionNonce"]);
        final fileKey =
            CryptoUtil.decryptSync(encFileKey, collectionKey, encFileKeyNonce);

        final encodedMetadata = CryptoUtil.decryptSync(
          CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
          fileKey,
          CryptoUtil.base642bin(item["metadata"]["decryptionHeader"]),
        );
        final Map<String, dynamic> defaultMetdata =
            jsonDecode(utf8.decode(encodedMetadata));
        if (!defaultMetdata.containsKey('version')) {
          defaultMetdata['version'] = 0;
        }
        if (defaultMetdata['hash'] == null &&
            defaultMetdata.containsKey('imageHash') &&
            defaultMetdata.containsKey('videoHash')) {
          // old web version was putting live photo hash in dfferent fields
          defaultMetdata['hash'] =
              '${defaultMetdata['imageHash']}$kLivePhotoHashSeparator${defaultMetdata['videoHash']}';
        }
        Metadata? pubMagicMetadata;
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
        final String fileDecryptionHeader = item["file"]["decryptionHeader"];
        final String thumbnailDecryptionHeader =
            item["thumbnail"]["decryptionHeader"];
        final Info? info = Info.fromJson(item["info"]);
        final CollectionFileItem file = CollectionFileItem(
          collectionID: collectionID,
          updatedAt: collectionUpdationTime,
          encFileKey: encFileKey,
          encFileKeyNonce: encFileKeyNonce,
          isDeleted: false,
          createdAt: item["createdAt"],
          fileItem: FileItem(
            fileID: fileID,
            ownerID: ownerID,
            thumnailDecryptionHeader:
                CryptoUtil.base642bin(thumbnailDecryptionHeader),
            fileDecryotionHeader: CryptoUtil.base642bin(fileDecryptionHeader),
            metadata: Metadata(data: defaultMetdata, version: 0),
            magicMetadata: privateMagicMetadata,
            pubMagicMetadata: pubMagicMetadata,
            info: info,
          ),
        );
        updatedFiles.add(file);
      }
      _logger.info('[Collection-$collectionID] parsed ${diff.length} '
          'diff items ( ${updatedFiles.length} updated) in ${DateTime.now().difference(startTime).inMilliseconds}ms');
      return DiffResult(
        updatedFiles,
        deletedFiles,
        hasMore,
        latestUpdatedAtTime,
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

class DiffResult {
  final List<CollectionFileItem> updatedItems;
  final List<CollectionFileItem> deletedItems;
  final bool hasMore;
  final int maxUpdatedAtTime;
  DiffResult(
    this.updatedItems,
    this.deletedItems,
    this.hasMore,
    this.maxUpdatedAtTime,
  );
}
