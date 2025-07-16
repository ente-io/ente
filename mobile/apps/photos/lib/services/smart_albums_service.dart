import "dart:async";
import "dart:convert";

import "package:computer/computer.dart";
import "package:flutter/widgets.dart" show BuildContext;
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/collection/smart_album_config.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/service_locator.dart" show entityService;
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/action_sheet_widget.dart"
    show showActionSheet;
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class SmartAlbumsService {
  SmartAlbumsService._();

  static final SmartAlbumsService instance = SmartAlbumsService._();

  final _logger = Logger((SmartAlbumsService).toString());

  int _lastCacheRefreshTime = 0;

  Map<int, SmartAlbumConfig>? configs;
  Future<Map<int, SmartAlbumConfig>>? _cachedConfigsFuture;

  static const type = EntityType.person;

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
    return entityService.lastSyncTime(type);
  }

  Future<Map<int, SmartAlbumConfig>> getSmartConfigs() async {
    final lastRemoteSyncTimeValue = lastRemoteSyncTime();
    if (_lastCacheRefreshTime != lastRemoteSyncTimeValue) {
      _lastCacheRefreshTime = lastRemoteSyncTimeValue;
      _cachedConfigsFuture = null; // Invalidate cache
    }
    _cachedConfigsFuture ??= _fetchAndCacheSConfigs();
    configs = await _cachedConfigsFuture!;
    return configs!;
  }

  Future<Map<int, SmartAlbumConfig>> _fetchAndCacheSConfigs() async {
    _logger.finest("reading all smart configs from local db");
    final entities = await entityService.getEntities(type);
    final result = await Computer.shared().compute(
      _decodeSConfigEntities,
      param: {"entity": entities},
      taskName: "decode_sconfig_entities",
    ) as (Map<int, SmartAlbumConfig>, Map<int, (String, Set<String>)>);

    for (final entry in result.$2.entries) {
      await _addOrUpdateEntity(
        type,
        result.$1[entry.key]!.toJson(),
        id: entry.value.$1,
      );

      for (final remoteId in entry.value.$2) {
        await _deleteEntry(
          id: remoteId,
        );
      }
    }

    return result.$1;
  }

  static (Map<int, SmartAlbumConfig>, Map<int, (String, Set<String>)>)
      _decodeSConfigEntities(
    Map<String, dynamic> param,
  ) {
    final entities = param["entity"] as List<LocalEntityData>;

    final Map<int, SmartAlbumConfig> sconfigs = {};
    final Map<int, (String, Set<String>)> collectionToRemote = {};
    for (final entity in entities) {
      var config = SmartAlbumConfig.fromJson(
        json.decode(entity.data),
        entity.id,
        entity.updatedAt,
      );

      if (sconfigs.containsKey(config.collectionId)) {
        final existingConfig = sconfigs[config.collectionId]!;
        final configToKeep = config.updatedAt < existingConfig.updatedAt
            ? config
            : existingConfig;
        final configToDelete = config.updatedAt < existingConfig.updatedAt
            ? existingConfig
            : config;
        collectionToRemote[configToKeep.collectionId] = (
          configToKeep.remoteId!,
          {
            ...?collectionToRemote[configToKeep.collectionId]?.$2,
            configToDelete.remoteId!,
          },
        );

        config = sconfigs[config.collectionId]!.merge(config);
      }

      sconfigs[config.collectionId] = config;
    }

    return (sconfigs, collectionToRemote);
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
      type,
      config.toJson(),
      id: config.remoteId,
    );
  }

  Future<SmartAlbumConfig?> getConfig(int collectionId) async {
    final cachedConfigs = await getSmartConfigs();
    return cachedConfigs[collectionId];
  }

  Future<bool> removeFilesDialog(
    BuildContext context,
  ) async {
    final completer = Completer<bool>();
    await showActionSheet(
      context: context,
      body: "Should the files related to the person be removed?",
      buttons: [
        ButtonWidget(
          labelText: S.of(context).yes,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          isInAlert: true,
          onTap: () async {
            completer.complete(true);
          },
        ),
        ButtonWidget(
          labelText: S.of(context).cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          onTap: () async {
            completer.complete(false);
          },
        ),
      ],
    );

    return completer.future;
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
