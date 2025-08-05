import "dart:io";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/rl_mapping.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/remote/fetch/files_diff.dart";

class RemoteDiffService {
  final Logger _logger = Logger('RemoteDiffService');
  final CollectionsService _collectionsService;
  final RemoteFileDiffService filesDiffService;
  final Configuration _config;
  // optional async callback that take list of collections ids that were updated
  // remotely and return a future that completes when the callback is done.
  final Future<void> Function(List<int>)? onCollectionSynced;
  RemoteDiffService(
    this._collectionsService,
    this.filesDiffService,
    this._config, {
    this.onCollectionSynced,
  });

  bool _isExistingSyncSilent = false;

  Future<void> syncFromRemote() async {
    final isFirstSync = !_collectionsService.hasSyncedCollections();
    if (isFirstSync && !_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    await _collectionsService.sync();
    final idsToRemoteUpdationTimeMap =
        await _collectionsService.getCollectionIDsToBeSynced();
    await _syncCollectionsFiles(idsToRemoteUpdationTimeMap);
    _logger.info("All updated collections & files synced");
    Bus.instance.fire(DiffSyncCompleteEvent());
    _isExistingSyncSilent = false;
    if (onCollectionSynced != null) {
      await onCollectionSynced!(idsToRemoteUpdationTimeMap.keys.toList());
    }
    // unawaited(_localFileUpdateService.markUpdatedFilesForReUpload());
  }

  Future<void> _syncCollectionsFiles(
    final Map<int, int> idsToRemoteUpdationTimeMap,
  ) async {
    for (final cid in idsToRemoteUpdationTimeMap.keys) {
      await _syncCollectionFiles(
        cid,
        _collectionsService.getCollectionSyncTime(cid),
      );
      // update syncTime for the collection in sharedPrefs. Note: the
      // syncTime can change on remote but we might not get a diff for the
      // collection if there are not changes in the file, but the collection
      // metadata (name, archive status, sharing etc) has changed.
      final remoteUpdateTime = idsToRemoteUpdationTimeMap[cid];
      await _collectionsService.setCollectionSyncTime(cid, remoteUpdateTime);
    }
  }

  Future<void> _syncCollectionFiles(int collectionID, int sinceTime) async {
    if (!_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    final Uint8List collectionKey =
        _collectionsService.getCollectionKey(collectionID);
    int currentSinceTime = sinceTime;
    bool hasMore = true;
    bool hasItems = false;
    while (hasMore) {
      final diff = await filesDiffService.getCollectionItemsDiff(
        collectionID,
        currentSinceTime,
        collectionKey,
      );
      hasItems = hasItems ||
          diff.deletedItems.isNotEmpty ||
          diff.updatedItems.isNotEmpty;
      if (diff.deletedItems.isNotEmpty) {
        await remoteDB.deleteFilesDiff(diff.deletedItems);
      }
      if (diff.updatedItems.isNotEmpty) {
        await remoteCache.insertDiffItems(diff.updatedItems);
        await _mapRemoteToLocalItems(diff);
      }
      // todo:(rewrite) neeraj add logic to refresh home gallery when time or visibility changes
      if (diff.maxUpdatedAtTime > currentSinceTime) {
        await _collectionsService.setCollectionSyncTime(
          collectionID,
          diff.maxUpdatedAtTime,
        );
        currentSinceTime = diff.maxUpdatedAtTime;
      }
      _logger.fine("[Collection-$collectionID] synced $diff");
      hasMore = diff.hasMore;
    }
    if (!hasItems) {
      return;
    }
    Bus.instance.fire(
      CollectionUpdatedEvent(
        collectionID,
        [],
        "diff",
      ),
    );
  }

  Future<void> _mapRemoteToLocalItems(DiffResult diff) async {
    final Map<int, (String, ApiFileItem)> fileIDtoLocalID = {};
    final Map<int, String> unmappedFileIDtoLocalID = {};
    for (final item in diff.updatedItems) {
      if (item.fileItem.localID != null &&
          item.fileItem.ownerID == _config.getUserID()!) {
        fileIDtoLocalID[item.fileItem.fileID] =
            (item.fileItem.localID!, item.fileItem);
      }
    }
    if (fileIDtoLocalID.isEmpty) {
      _logger.info("No remote files to map to local items");
      return;
    }
    final mappedLocalIDs = await remoteDB.getLocalIDsWithMapping(
      fileIDtoLocalID.values.map((e) => e.$1).toList(),
    );
    final remoteIDsWithMapping =
        await remoteDB.getFilesWithMapping(fileIDtoLocalID.keys.toList());
    // remote already claim mappings from fileIds to localIDs
    int mapRemoteCount = 0;
    int mapLocalCount = 0;
    int bothMappedCount = 0;
    int noLocalIDFoundCount = 0;
    for (MapEntry<int, (String, ApiFileItem)> entry
        in fileIDtoLocalID.entries) {
      final lID = entry.value.$1;
      final rID = entry.key;
      if (mappedLocalIDs.contains(lID) && remoteIDsWithMapping.contains(rID)) {
        bothMappedCount++;
        continue;
      } else if (mappedLocalIDs.contains(lID)) {
        mapLocalCount++;
      } else if (remoteIDsWithMapping.contains(rID)) {
        mapRemoteCount++;
      } else {
        unmappedFileIDtoLocalID[rID] = lID;
      }
    }
    if (unmappedFileIDtoLocalID.isEmpty) {
      _logger.info("No unmapped remote files found");
      return;
    }

    final unclaimedLocalAssets =
        localDB.getLocalAssetsInfo(unmappedFileIDtoLocalID.values.toList());
    final rmMappings = <RLMapping>[];
    for (final entry in unmappedFileIDtoLocalID.entries) {
      final remoteFileID = entry.key;
      final localID = entry.value;
      final localAsset = await unclaimedLocalAssets;
      if (!localAsset.containsKey(localID)) {
        noLocalIDFoundCount++;
        continue;
      }
      final localAssetInfo = localAsset[localID]!;
      final ApiFileItem apiFile = fileIDtoLocalID[remoteFileID]!.$2;
      late bool? isHashMatched;
      late bool hasIdMatched;
      if (localAssetInfo.hash != null && apiFile.hash != null) {
        isHashMatched = localAssetInfo.hash == apiFile.hash;
      } else {
        isHashMatched = null; // hash status unknown
      }
      if (Platform.isAndroid) {
        hasIdMatched = localAssetInfo.id == apiFile.localID &&
            apiFile.deviceFolder == localAssetInfo.relativePath &&
            localAssetInfo.title == apiFile.nonEditedTitle;
      } else if (Platform.isIOS) {
        hasIdMatched = localAssetInfo.id == apiFile.localID;
      } else {
        hasIdMatched = false; // Unsupported platform
      }
      if (!hasIdMatched) {
        continue;
      }
      MatchType? mappingType;
      if (isHashMatched == true) {
        mappingType = MatchType.deviceHashMatched;
      } else if (isHashMatched == null) {
        mappingType = MatchType.localID;
      } else {
        _logger.warning(
          "Remote file ${apiFile.fileID} has localID $localID but hash does not match",
        );
        if (kDebugMode) {
          throw Exception(
            "Remote file ${apiFile.fileID} has localID $localID but hash does not match",
          );
        }
      }
      if (mappingType != null) {
        rmMappings.add(
          RLMapping(
            remoteUploadID: remoteFileID,
            localID: localAssetInfo.id,
            localCloudID: null,
            mappingType: mappingType,
          ),
        );
      }
    }
    if (rmMappings.isNotEmpty) {
      await remoteDB.insertMappings(rmMappings);
    }
    _logger.info(
      "Mapped new ${rmMappings.length} remote files to local assets: "
      "existing remoteID to localID: $mapRemoteCount, "
      "existing localID to remoteID: $mapLocalCount, "
      "existing both mapped: $bothMappedCount, "
      "no localID found: $noLocalIDFoundCount",
    );
  }

  // todo: rewrite this inside collection_file diff service
  bool _shouldClearCache(EnteFile remoteFile, EnteFile existingFile) {
    return false;
    // if (remoteFile.hash != null && existingFile.hash != null) {
    //   return remoteFile.hash != existingFile.hash;
    // }
    // return remoteFile.updationTime != (existingFile.updationTime ?? 0);
  }

  bool _shouldReloadHomeGallery(EnteFile remoteFile, EnteFile existingFile) {
    // int remoteCreationTime = remoteFile.creationTime!;
    // if (remoteFile.pubMmdVersion > 0 &&
    //     (remoteFile.pubMagicMetadata?.editedTime ?? 0) != 0) {
    //   remoteCreationTime = remoteFile.pubMagicMetadata!.editedTime!;
    // }
    // if (remoteCreationTime != existingFile.creationTime) {
    //   return true;
    // }
    // if (existingFile.mMdVersion > 0 &&
    //     remoteFile.mMdVersion != existingFile.mMdVersion &&
    //     remoteFile.magicMetadata.visibility !=
    //         existingFile.magicMetadata.visibility) {
    //   return false;
    // }
    return false;
  }
}
