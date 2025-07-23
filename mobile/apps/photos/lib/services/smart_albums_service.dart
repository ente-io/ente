import "dart:async";
import "dart:convert";

import "package:logging/logging.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/collection/smart_album_config.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/service_locator.dart" show entityService;
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";

class SmartAlbumsService {
  final _logger = Logger((SmartAlbumsService).toString());

  int _lastCacheRefreshTime = 0;

  Future<Map<int, SmartAlbumConfig>>? _cachedConfigsFuture;

  static const type = EntityType.person;

  void clearCache() {
    _cachedConfigsFuture = null;
    _lastCacheRefreshTime = 0;
  }

  int lastRemoteSyncTime() {
    return entityService.lastSyncTime(type);
  }

  Future<Map<int, SmartAlbumConfig>> getSmartConfigs() async {
    final lastRemoteSyncTimeValue = lastRemoteSyncTime();
    if (_lastCacheRefreshTime != lastRemoteSyncTimeValue) {
      _lastCacheRefreshTime = lastRemoteSyncTimeValue;
      _cachedConfigsFuture = null; // Invalidate cache
    }
    _cachedConfigsFuture ??= _fetchAndCacheSConfigs();
    return await _cachedConfigsFuture!;
  }

  Future<Map<int, SmartAlbumConfig>> _fetchAndCacheSConfigs() async {
    _logger.finest("reading all smart configs from local db");

    final entities = await entityService.getEntities(type);

    final result = _decodeSConfigEntities(
      {"entity": entities},
    );

    final sconfigs = result["sconfigs"] as Map<int, SmartAlbumConfig>;

    final collectionToUpdate = result["collectionToUpdate"] as Set<int>;
    final idToDelete = result["idToDelete"] as Set<String>;

    // update the merged config to remote db
    for (final collectionid in collectionToUpdate) {
      try {
        await saveConfig(sconfigs[collectionid]!);
      } catch (error, stackTrace) {
        _logger.severe(
          "Failed to update smart album config for collection $collectionid",
          error,
          stackTrace,
        );
      }
    }

    // delete all remote ids that are merged into the config
    for (final remoteId in idToDelete) {
      try {
        await _deleteEntry(id: remoteId);
      } catch (error, stackTrace) {
        _logger.severe(
          "Failed to delete smart album config for remote id $remoteId",
          error,
          stackTrace,
        );
      }
    }

    return sconfigs;
  }

  Map<String, dynamic> _decodeSConfigEntities(
    Map<String, dynamic> param,
  ) {
    final entities = (param["entity"] as List<LocalEntityData>);

    final Map<int, SmartAlbumConfig> sconfigs = {};
    final Set<int> collectionToUpdate = {};
    final Set<String> idToDelete = {};

    for (final entity in entities) {
      try {
        var config = SmartAlbumConfig.fromJson(
          json.decode(entity.data),
          entity.id,
          entity.updatedAt,
        );

        if (sconfigs.containsKey(config.collectionId)) {
          final existingConfig = sconfigs[config.collectionId]!;
          final collectionIdToKeep = config.updatedAt < existingConfig.updatedAt
              ? config.collectionId
              : existingConfig.collectionId;
          final remoteIdToDelete = config.updatedAt < existingConfig.updatedAt
              ? existingConfig.id
              : config.id;

          config = config.merge(sconfigs[config.collectionId]!);

          // Update the config to be updated and deleted list
          collectionToUpdate.add(collectionIdToKeep);
          idToDelete.add(remoteIdToDelete!);
        }

        sconfigs[config.collectionId] = config;
      } catch (error, stackTrace) {
        _logger.severe(
          "Failed to decode smart album config",
          error,
          stackTrace,
        );
      }
    }

    return {
      "sconfigs": sconfigs,
      "collectionToUpdate": collectionToUpdate,
      "idToDelete": idToDelete,
    };
  }

  Future<void> syncSmartAlbums() async {
    final cachedConfigs = await getSmartConfigs();

    for (final entry in cachedConfigs.entries) {
      final collectionId = entry.key;
      final config = entry.value;

      final infoMap = config.infoMap;

      // Person Id key mapped to updatedAt value
      final updatedAtMap = await entityService.getUpdatedAts(
        EntityType.cgroup,
        config.personIDs.toList(),
      );

      for (final personId in config.personIDs) {
        // compares current updateAt with last added file's updatedAt
        if (updatedAtMap[personId] == null ||
            infoMap[personId] == null ||
            (updatedAtMap[personId]! <= infoMap[personId]!.updatedAt)) {
          continue;
        }

        final toBeSynced = (await SearchService.instance
                .getClusterFilesForPersonID(personId))
            .entries
            .expand((e) => e.value)
            .toList()
          ..removeWhere(
            (e) =>
                e.uploadedFileID == null ||
                config.infoMap[personId]!.addedFiles.contains(e.uploadedFileID),
          );

        if (toBeSynced.isNotEmpty) {
          final CollectionActions collectionActions =
              CollectionActions(CollectionsService.instance);

          final result = await collectionActions.addToCollection(
            null,
            collectionId,
            false,
            selectedFiles: toBeSynced,
          );

          if (result) {
            final newConfig = await config.addFiles(
              personId,
              updatedAtMap[personId]!,
              toBeSynced.map((e) => e.uploadedFileID!).toSet(),
            );
            await saveConfig(newConfig);
          }
        }
      }
    }
  }

  Future<void> saveConfig(SmartAlbumConfig config) async {
    await _addOrUpdateEntity(
      type,
      config.toJson(),
      id: config.id,
    );
  }

  Future<SmartAlbumConfig?> getConfig(int collectionId) async {
    final cachedConfigs = await getSmartConfigs();
    return cachedConfigs[collectionId];
  }

  /// Wrapper method for entityService.addOrUpdate that handles cache refresh
  Future<LocalEntityData> _addOrUpdateEntity(
    EntityType type,
    Map<String, dynamic> jsonMap, {
    String? id,
  }) async {
    final result = await entityService.addOrUpdate(
      type,
      jsonMap,
      id: id,
    );
    _lastCacheRefreshTime = 0; // Invalidate cache
    return result;
  }

  Future<void> _deleteEntry({
    required String id,
  }) async {
    await entityService.deleteEntry(id);
    _lastCacheRefreshTime = 0; // Invalidate cache
  }
}
