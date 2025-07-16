import "dart:async";
import "dart:convert";

import "package:computer/computer.dart";
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
  SmartAlbumsService._();

  static final SmartAlbumsService instance = SmartAlbumsService._();

  final _logger = Logger((SmartAlbumsService).toString());

  int _lastCacheRefreshTime = 0;

  Future<Map<int, SmartAlbumConfig>>? _cachedConfigsFuture;

  void clearCache() {
    _cachedConfigsFuture = null;
    _lastCacheRefreshTime = 0;
  }

  Future<void> refreshSmartConfigCache() async {
    _lastCacheRefreshTime = 0;
    // wait to ensure cache is refreshed
    final _ = await getSmartConfigs();
  }

  int lastRemoteSyncTime() {
    return entityService.lastSyncTime(EntityType.smartConfig);
  }

  Future<Map<int, SmartAlbumConfig>> getSmartConfigs() async {
    if (_lastCacheRefreshTime != lastRemoteSyncTime()) {
      _lastCacheRefreshTime = lastRemoteSyncTime();
      _cachedConfigsFuture = null; // Invalidate cache
    }
    _cachedConfigsFuture ??= _fetchAndCacheSConfigs();
    return _cachedConfigsFuture!;
  }

  Future<Map<int, SmartAlbumConfig>> _fetchAndCacheSConfigs() async {
    _logger.finest("reading all smart configs from local db");
    final entities = await entityService.getEntities(EntityType.smartConfig);
    final sconfigs = await Computer.shared().compute(
      _decodeSConfigEntities,
      param: {"entity": entities},
      taskName: "decode_sconfig_entities",
    );

    return sconfigs;
  }

  static Map<int, SmartAlbumConfig> _decodeSConfigEntities(
    Map<String, dynamic> param,
  ) {
    final entities = param["entity"] as List<LocalEntityData>;
    return Map.fromEntries(
      entities.map(
        (e) {
          final config = SmartAlbumConfig.fromJson(
            json.decode(e.data),
            e.id,
          );
          return MapEntry(config.collectionId, config);
        },
      ),
    );
  }

  Future<void> syncSmartAlbums() async {
    final cachedConfigs = await _fetchAndCacheSConfigs();

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
      EntityType.smartConfig,
      config.toJson(),
    );
  }

  Future<SmartAlbumConfig?> getConfig(int collectionId) async {
    final cachedConfigs = await getSmartConfigs();
    return cachedConfigs[collectionId]!;
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
}
