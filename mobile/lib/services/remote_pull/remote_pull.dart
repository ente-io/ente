import "dart:math";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/remote_pull/collection_files.dart";

class RemoteDiffService {
  final Logger _logger = Logger('RemoteDiffService');
  final CollectionsService _collectionsService;
  final CollectionFilesService collectionFiles;

  RemoteDiffService(
    this._collectionsService,
    this.collectionFiles,
  );

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
  }

  Future<void> _syncCollectionFiles(int collectionID, int sinceTime) async {
    if (!_isExistingSyncSilent) {
      Bus.instance.fire(SyncStatusUpdate(SyncStatus.applyingRemoteDiff));
    }
    final Uint8List collectionKey =
        _collectionsService.getCollectionKey(collectionID);
    int currentSinceTime = sinceTime;
    bool hasMore = true;
    while (hasMore) {
      final diff = await collectionFiles.getCollectionItemsDiff(
        collectionID,
        currentSinceTime,
        collectionKey,
      );
      await remoteDB.deleteCollectionFilesDiff(diff.deletedItems);
      await remoteDB.insertCollectionFilesDiff(diff.updatedItems);
      final int nextSyncFrom = max(diff.maxUpdatedAtTime, currentSinceTime);
      await _collectionsService.setCollectionSyncTime(
        collectionID,
        nextSyncFrom,
      );
      _logger.fine("[Collection-$collectionID] synced $diff");
      hasMore = diff.hasMore;
      if (hasMore) {
        currentSinceTime = nextSyncFrom;
      }
    }
  }
}
