// RemotePullService is a service that pulls the latest changes from the sever.
import "dart:convert";
import "dart:math";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_uploader_util.dart";

class RemoteDiffService {
  final Logger _logger = Logger('RemoteDiffService');
  final Dio _enteDio;
  final CollectionsService _collectionsService;
  RemoteDiffService(this._enteDio, this._collectionsService);

  bool _isExistingSyncSilent = false;

  Future<void> syncFromRemote() async {
    _logger.info("Pulling remote diff");
    final isFirstSync = !_collectionsService.hasSyncedCollections();
    if (isFirstSync && !_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    await _collectionsService.sync();

    final idsToRemoteUpdationTimeMap =
        await _collectionsService.getCollectionIDsToBeSynced();
    await _syncCollectionsFiles(idsToRemoteUpdationTimeMap);
    _isExistingSyncSilent = false;
    // unawaited(_localFileUpdateService.markUpdatedFilesForReUpload());
    // unawaited(_notifyNewFiles
    //
    // (idsToRemoteUpdationTimeMap.keys.toList()));
  }

  Future<void> _syncCollectionsFiles(
    final Map<int, int> idsToRemoteUpdationTimeMap,
  ) async {
    for (final cid in idsToRemoteUpdationTimeMap.keys) {
      await _syncCollectionFiles(
        cid,
        _collectionsService.getCollectionSyncTime(cid, syncV2: true),
      );
      // update syncTime for the collection in sharedPrefs. Note: the
      // syncTime can change on remote but we might not get a diff for the
      // collection if there are not changes in the file, but the collection
      // metadata (name, archive status, sharing etc) has changed.
      final remoteUpdateTime = idsToRemoteUpdationTimeMap[cid];
      await _collectionsService.setCollectionSyncTime(cid, remoteUpdateTime);
    }
    _logger.info("All updated collections synced");
    Bus.instance.fire(DiffSyncCompleteEvent());
  }

  Future<void> _syncCollectionFiles(int collectionID, int sinceTime) async {
    if (!_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    final diff = await getCollectionItemsDiff(collectionID, sinceTime);
    await remoteDB.deleteCollectionFilesDiff(diff.deletedItems);
    await remoteDB.insertCollectionFilesDiff(diff.updatedItems);
    await _collectionsService.setCollectionSyncTime(
      collectionID,
      max(diff.maxUpdatedAtTime, sinceTime),
    );
    if (diff.hasMore) {
      _logger.info("[Collection-$collectionID] syncing more files");
      return await _syncCollectionFiles(
        collectionID,
        _collectionsService.getCollectionSyncTime(collectionID),
      );
    }
    _logger.info("[Collection-$collectionID] synced completely");
  }

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

        final encodedMetadata = CryptoUtil.decryptChaChaSync(
          CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
          fileKey,
          CryptoUtil.base642bin(item["metadata"]["decryptionHeader"]),
        );
        final Map<String, dynamic> defaultMeta =
            jsonDecode(utf8.decode(encodedMetadata));
        if (!defaultMeta.containsKey('version')) {
          defaultMeta['version'] = 0;
        }
        if (defaultMeta['hash'] == null &&
            defaultMeta.containsKey('imageHash') &&
            defaultMeta.containsKey('videoHash')) {
          // old web version was putting live photo hash in different fields
          defaultMeta['hash'] =
              '${defaultMeta['imageHash']}$kLivePhotoHashSeparator${defaultMeta['videoHash']}';
        }
        Metadata? pubMagicMetadata;
        Metadata? privateMagicMetadata;

        if (item['magicMetadata'] != null) {
          final utfEncodedMmd = CryptoUtil.decryptChaChaSync(
            CryptoUtil.base642bin(item['magicMetadata']['data']),
            fileKey,
            CryptoUtil.base642bin(item['magicMetadata']['decryptionHeader']),
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
            metadata: Metadata(data: defaultMeta, version: 0),
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
