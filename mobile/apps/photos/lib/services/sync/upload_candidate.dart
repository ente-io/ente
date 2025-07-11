// UploadCandidate coontains the logic to determine what new assets we need to create, and what assets needs updation.
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/local/table/path_config_table.dart";
import "package:photos/db/local/table/upload_queue_table.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import "package:photos/events/backup_folders_updated_event.dart";
import "package:photos/events/force_reload_home_gallery_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/local/asset_upload_queue.dart";
import "package:photos/models/local/path_config.dart";
import "package:photos/models/upload_strategy.dart";
import "package:photos/module/upload/model/candidates.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/sync/sync_service.dart";

class UploadCandidateService {
  final Logger _logger = Logger("UploadCandidateService");
  final Configuration _config = Configuration.instance;
  final CollectionsService _collectionsService = CollectionsService.instance;
  // create singleton instance
  UploadCandidateService._privateConstructor();
  static final UploadCandidateService instance =
      UploadCandidateService._privateConstructor();

  Future<void> updatePathBackUpStatus(
    Map<String, bool> syncStatusUpdate,
  ) async {
    final int ownerID = _config.getUserID()!;
    final Set<int> oldDestCollection =
        await localDB.destCollectionWithBackup(ownerID);
    await localDB.insertOrUpdatePathConfigs(syncStatusUpdate, ownerID);
    final Set<int> newDestCollection =
        await localDB.destCollectionWithBackup(ownerID);
    // Cancel any existing sync if the destination collection has changed
    SyncService.instance.onDeviceCollectionSet(newDestCollection);
    // remove all collectionIDs which are still marked for backup
    oldDestCollection.removeAll(newDestCollection);
    final Set<String> enabledPathIDs = {};
    for (final entry in syncStatusUpdate.entries) {
      if (entry.value) {
        enabledPathIDs.add(entry.key);
      }
    }
    await localDB.clearMappingsWithDiffPath(
      ownerID,
      enabledPathIDs,
    );
    if (syncStatusUpdate.values.any((syncStatus) => syncStatus == false)) {
      Configuration.instance.setSelectAllFoldersForBackup(false).ignore();
    }
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(<EnteFile>[], source: "deviceFolderSync"),
    );
    Bus.instance.fire(BackupFoldersUpdatedEvent());
  }

  Future<void> markLocalAssetForAutoUpload() async {
    _logger.info("Syncing device collections to be uploaded");
    final int ownerID = _config.getUserID()!;

    final devicePathConfigs = await localDB.getPathConfigs(ownerID);
    final assetPaths = await localDB.getAssetPaths();
    final Map<String, AssetPathEntity> pathIDToAssetPath = {};
    for (final assetPath in assetPaths) {
      pathIDToAssetPath[assetPath.id] = assetPath;
    }
    devicePathConfigs.removeWhere((element) => !element.shouldBackup);

    final pathIdToLocalIDs = await localDB.pathToAssetIDs();
    devicePathConfigs.sort(
      (a, b) => (pathIdToLocalIDs[a.pathID]?.length ?? 0)
          .compareTo((pathIdToLocalIDs[b.pathID]?.length ?? 0)),
    );
    // Sort by count to ensure that photos in iOS are first inserted in
    // smallest album marked for backup. This is to ensure that photo is
    // first attempted to upload in a non-recent album.
    final rlMapping = await remoteDB.getLocalIDToMappingForActiveFiles();
    final Set<String> queuedLocalIDs = await localDB.getQueueAssetIDs(ownerID);
    queuedLocalIDs.addAll(rlMapping.keys);
    bool moreFilesMarkedForBackup = false;
    for (final deviceCollection in devicePathConfigs) {
      final AssetPathEntity? assetPath =
          pathIDToAssetPath[deviceCollection.pathID];
      if (assetPath == null) {
        _logger.warning(
          "AssetPathEntity not found for pathID ${deviceCollection.pathID}",
        );
        continue;
      }
      final Set<String> localIDsToSync =
          pathIdToLocalIDs[deviceCollection.pathID] ?? {};
      if (deviceCollection.uploadStrategy == UploadStrategy.ifMissing) {
        localIDsToSync.removeAll(queuedLocalIDs);
      }
      if (localIDsToSync.isEmpty) {
        continue;
      }
      final collectionID = await _getCollectionID(deviceCollection, assetPath);
      if (collectionID == null) {
        _logger.warning('DeviceCollection was either deleted or missing');
        continue;
      }

      moreFilesMarkedForBackup = true;
      await localDB.insertOrUpdateQueue(
        localIDsToSync,
        collectionID,
        ownerID,
        path: deviceCollection.pathID,
      );
      _logger.info(
        "Queued ${localIDsToSync.length} files for upload in collection "
        "$collectionID for path ${deviceCollection.pathID}",
      );
      queuedLocalIDs.addAll(localIDsToSync);
    }
    if (moreFilesMarkedForBackup && !_config.hasSelectedAllFoldersForBackup()) {
      // "force reload due to display new files"
      Bus.instance.fire(ForceReloadHomeGalleryEvent("newFilesDisplay"));
    }
  }

  Future<int?> _getCollectionID(
    PathConfig pathConfig,
    AssetPathEntity assetPath,
  ) async {
    if (pathConfig.destCollectionID != null) {
      final int destCollectionID = pathConfig.destCollectionID!;
      final collection =
          _collectionsService.getCollectionByID(destCollectionID);
      if (collection != null && !collection.isDeleted) {
        return collection.id;
      }
      if (collection == null) {
        // ideally, this should never happen because the app keeps a track of
        // all collections and their IDs. But, if somehow the collection is
        // deleted, we should fetch it again
        _logger.severe("Collection $destCollectionID missing "
            "for pathID ${assetPath.id}");
        _collectionsService.fetchCollectionByID(destCollectionID).ignore();
        // return, by next run collection should be available.
        // we are not waiting on fetch by choice because device might have wrong
        // mapping which will result in breaking upload for other device path
        return null;
      } else if (collection.isDeleted) {
        _logger.warning("Collection $destCollectionID deleted "
            "for pathID ${assetPath.id}, new collection will be created");
      }
    }
    final collection =
        await _collectionsService.getOrCreateForPath(assetPath.name);
    await localDB.updateDestConnection(
      assetPath.id,
      collection.id,
      _config.getUserID()!,
    );
    return collection.id;
  }

  Future<AssetUploadCandidates> getLocalAssetsForUploads(
    int userID,
    bool includeVideos,
  ) async {
    final List<(AssetUploadQueue, EnteFile)> enteries =
        await localDB.getQueueEntriesWithFiles(userID);
    if (enteries.isEmpty) {
      return AssetUploadCandidates(includeVideos: includeVideos);
    }
    final bool shouldRemoveVideos = !includeVideos;
    final ignoredIDs = await IgnoredFilesService.instance.idToIgnoreReasonMap;
    int ignoredForUpload = 0;
    int skippedVideos = 0;
    int forcedVideos = 0;
    final List<(AssetUploadQueue, EnteFile)> own = [];
    final List<(AssetUploadQueue, EnteFile)> shared = [];
    final List<(AssetUploadQueue, EnteFile)> unknown = [];
    for (var entry in enteries) {
      final queueEntry = entry.$1;
      final file = entry.$2;

      if (shouldRemoveVideos && (file.fileType == FileType.video)) {
        // if entry was manaully marked for upload, we should discard video backup settings
        if (queueEntry.manual) {
          forcedVideos++;
        } else {
          skippedVideos++;
          continue;
        }
      }
      if (IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, file)) {
        ignoredForUpload++;
        continue;
      }
      final Collection? c = CollectionsService.instance
          .getCollectionByID(queueEntry.destCollectionId);
      if (c == null) {
        _logger.warning(
          "Collection with ID ${queueEntry.destCollectionId} not found for lAsset ${file.lAsset?.id}",
        );
        unknown.add(entry);
      } else if (c.isOwner(userID)) {
        own.add(entry);
      } else {
        shared.add(entry);
      }
    }
    return AssetUploadCandidates(
      own: own,
      shared: shared,
      unknwon: unknown,
      ignored: ignoredForUpload,
      skippedVideos: skippedVideos,
      forcedVideos: forcedVideos,
      includeVideos: includeVideos,
    );
  }
}
