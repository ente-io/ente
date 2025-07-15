import "dart:async";

import "package:logging/logging.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/collection/smart_album_config.dart";
import "package:photos/service_locator.dart" show entityService, ServiceLocator;
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";

class SmartAlbumsService {
  SmartAlbumsService._();

  static final SmartAlbumsService instance = SmartAlbumsService._();

  final _logger = Logger((SmartAlbumsService).toString());

  final Map<int, SmartAlbumConfig> _cachedConfigs = {};
  bool isInitialized = false;

  void init() {
    _logger.info("SmartAlbumsService initialized");
    refresh();
  }

  Future<void> refresh() async {
    if (isInitialized) return;

    _logger.info("Refreshing SmartAlbumsService");

    final collections = CollectionsService.instance.nonHiddenOwnedCollections();

    for (final collectionId in collections) {
      try {
        final config = await loadConfig(collectionId);
        _cachedConfigs[collectionId] = config;
      } catch (_) {}
    }

    isInitialized = true;
  }

  void updateCachedCollection(SmartAlbumConfig config) =>
      _cachedConfigs[config.collectionId] = config;

  Future<void> syncSmartAlbums() async {
    if (!isInitialized) await refresh();

    for (final entry in _cachedConfigs.entries) {
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

  static const _personIdsKey = "smart_album_person_ids";
  static const _addedFilesKey = "smart_album_added_files";

  Future<void> saveConfig(SmartAlbumConfig config) async {
    await ServiceLocator.instance.prefs.setStringList(
      "${_personIdsKey}_${config.collectionId}",
      config.personIDs.toList(),
    );

    await ServiceLocator.instance.prefs.setString(
      "${_addedFilesKey}_${config.collectionId}",
      config.infoMap.entries
          .map(
            (e) => "${e.key}:${e.value.updatedAt}|"
                "${e.value.addedFiles.join(',')}",
          )
          .join(';'),
    );

    updateCachedCollection(config);
  }

  Future<SmartAlbumConfig?> getConfig(int collectionId) async {
    await refresh();

    if (_cachedConfigs.containsKey(collectionId)) {
      return _cachedConfigs[collectionId]!;
    }

    return null;
  }

  Future<SmartAlbumConfig> loadConfig(int collectionId) async {
    final personIDs = ServiceLocator.instance.prefs
        .getStringList("${_personIdsKey}_$collectionId");
    if (personIDs == null || personIDs.isEmpty) {
      throw Exception(
        "No person IDs found for collection $collectionId",
      );
    }
    final addedFilesString = ServiceLocator.instance.prefs
            .getString("${_addedFilesKey}_$collectionId") ??
        "";

    final addedFiles = <String, PersonInfo>{};

    if (addedFilesString.isNotEmpty) {
      for (final entry in addedFilesString.split(';')) {
        final parts = entry.split(':');

        if (parts.length == 2) {
          final part2 = parts[1].split('|')[1];
          addedFiles[parts[0]] = (
            updatedAt: int.parse(parts[1].split('|')[0]),
            addedFiles:
                part2.isNotEmpty ? part2.split(',').map(int.parse).toSet() : {},
          );
        }
      }
    }

    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: personIDs.toSet(),
      infoMap: addedFiles,
    );
  }
}
