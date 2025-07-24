import "dart:async";
import "dart:convert";

import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
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
    return await _cachedConfigsFuture!;
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
    final userId = Configuration.instance.getUserID();

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

  /// Wrapper method for entityService.addOrUpdate that handles cache refresh
  Future<LocalEntityData> _addOrUpdateEntity(
    EntityType type,
    Map<String, dynamic> jsonMap, {
    required int collectionId,
    bool addWithCustomID = false,
    int? userId,
  }) async {
    final id = "sa_${userId!}_$collectionId";
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
    required String id,
  }) async {
    await entityService.deleteEntry(id);
    _lastCacheRefreshTime = 0; // Invalidate cache
  }
}
