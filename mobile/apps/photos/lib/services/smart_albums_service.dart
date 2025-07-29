import "dart:async";
import "dart:convert";

import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/smart_album_syncing_event.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/collection/smart_album_config.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/service_locator.dart" show entityService, flagService;
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";

class SmartAlbumsService {
  final _logger = Logger((SmartAlbumsService).toString());

  int _lastCacheRefreshTime = 0;

  Future<Map<int, SmartAlbumConfig>>? _cachedConfigsFuture;

  (int, bool)? syncingCollection;

  void clearCache() {
    _cachedConfigsFuture = null;
    _lastCacheRefreshTime = 0;
  }

  int lastRemoteSyncTime() {
    return entityService.lastSyncTime(EntityType.smartAlbum);
  }

  Future<Map<int, SmartAlbumConfig>> getSmartConfigs() async {
    final lastRemoteSyncTimeValue = lastRemoteSyncTime();
    if (_lastCacheRefreshTime != lastRemoteSyncTimeValue) {
      _lastCacheRefreshTime = lastRemoteSyncTimeValue;
      _cachedConfigsFuture = null; // Invalidate cache
    }
    _cachedConfigsFuture ??= _fetchAndCacheSaConfigs();
    return _cachedConfigsFuture!;
  }

  Future<Map<int, SmartAlbumConfig>> _fetchAndCacheSaConfigs() async {
    _logger.finest("reading all smart configs from local db");

    final entities = await entityService.getEntities(EntityType.smartAlbum);

    final result = _decodeSaConfigEntities({"entity": entities});

    return result;
  }

  Map<int, SmartAlbumConfig> _decodeSaConfigEntities(
    Map<String, dynamic> param,
  ) {
    final entities = (param["entity"] as List<LocalEntityData>);

    final Map<int, SmartAlbumConfig> saConfigs = {};

    for (final entity in entities) {
      try {
        final config = SmartAlbumConfig.fromJson(
          json.decode(entity.data),
          entity.id,
          entity.updatedAt,
        );

        saConfigs[config.collectionId] = config;
      } catch (error, stackTrace) {
        _logger.severe(
          "Failed to decode smart album config",
          error,
          stackTrace,
        );
      }
    }

    return saConfigs;
  }

  Future<void> syncSmartAlbums() async {
    final isMLEnabled = flagService.hasGrantedMLConsent;
    if (!isMLEnabled) {
      _logger.warning("ML is not enabled, skipping smart album sync");
      return;
    }

    final cachedConfigs = await getSmartConfigs();
    final userId = Configuration.instance.getUserID()!;

    for (final entry in cachedConfigs.entries) {
      final collectionId = entry.key;
      final config = entry.value;
      final collection =
          CollectionsService.instance.getCollectionByID(collectionId);

      if (!(collection?.canAutoAdd(userId) ?? false)) {
        _logger.warning(
          "Deleting collection config ($collectionId) as user does not have permission",
        );
        await _deleteEntry(
          userId: userId,
          collectionId: collectionId,
        );
        continue;
      }

      syncingCollection = (collectionId, false);
      Bus.instance.fire(
        SmartAlbumSyncingEvent(collectionId: collectionId, isSyncing: false),
      );

      final infoMap = config.infoMap;

      // Person Id key mapped to updatedAt value
      final updatedAtMap = await entityService.getUpdatedAts(
        EntityType.cgroup,
        config.personIDs.toList(),
      );

      Map<String, Set<int>> pendingSyncFiles = {};
      Set<EnteFile> pendingSyncFileSet = {};

      var newConfig = config;
      for (final personId in config.personIDs) {
        // compares current updateAt with last added file's updatedAt
        if (updatedAtMap[personId] == null ||
            infoMap[personId] == null ||
            (updatedAtMap[personId]! <= infoMap[personId]!.updatedAt)) {
          continue;
        }

        final fileIds = (await SearchService.instance
                .getClusterFilesForPersonID(personId))
            .entries
            .expand((e) => e.value)
            .toList()
          ..removeWhere(
            (e) =>
                e.uploadedFileID == null ||
                config.infoMap[personId]!.addedFiles
                    .contains(e.uploadedFileID) ||
                e.ownerID != userId,
          );

        pendingSyncFiles = {
          ...pendingSyncFiles,
          personId: fileIds.map((e) => e.uploadedFileID!).toSet(),
        };
        pendingSyncFileSet = {...pendingSyncFileSet, ...fileIds};
      }

      syncingCollection = (collectionId, true);
      Bus.instance.fire(
        SmartAlbumSyncingEvent(collectionId: collectionId, isSyncing: true),
      );

      if (pendingSyncFiles.isNotEmpty) {
        try {
          await CollectionsService.instance.addOrCopyToCollection(
            collectionId,
            pendingSyncFileSet.toList(),
            toCopy: false,
          );
          newConfig = newConfig.addFiles(updatedAtMap, pendingSyncFiles);

          await saveConfig(newConfig);
        } catch (_) {}
      }
    }
    syncingCollection = null;
    Bus.instance.fire(SmartAlbumSyncingEvent());
  }

  Future<void> saveConfig(SmartAlbumConfig config) async {
    final userId = Configuration.instance.getUserID()!;

    await _addOrUpdateEntity(
      EntityType.smartAlbum,
      config.toJson(),
      collectionId: config.collectionId,
      addWithCustomID: config.id == null,
      userId: userId,
    );
  }

  Future<SmartAlbumConfig?> getConfig(int collectionId) async {
    final cachedConfigs = await getSmartConfigs();
    return cachedConfigs[collectionId];
  }

  String getId({required int collectionId, required int userId}) =>
      "sa_${userId}_$collectionId";

  /// Wrapper method for entityService.addOrUpdate that handles cache refresh
  Future<LocalEntityData> _addOrUpdateEntity(
    EntityType type,
    Map<String, dynamic> jsonMap, {
    required int collectionId,
    bool addWithCustomID = false,
    required int userId,
  }) async {
    final id = getId(
      collectionId: collectionId,
      userId: userId,
    );
    final result = await entityService.addOrUpdate(
      type,
      jsonMap,
      id: id,
      addWithCustomID: addWithCustomID,
    );

    _lastCacheRefreshTime = 0; // Invalidate cache
    return result;
  }

  Future<void> _deleteEntry({
    required int userId,
    required int collectionId,
  }) async {
    final id = getId(collectionId: collectionId, userId: userId);
    await entityService.deleteEntry(id);
    _lastCacheRefreshTime = 0; // Invalidate cache
  }
}
