import "package:photos/models/api/entity/type.dart";
import "package:photos/service_locator.dart" show entityService, prefs;
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class SmartAlbumConfig {
  final int collectionId;
  // person ids
  final Set<String> personIDs;
  // person id mapped with updatedat, file ids
  final Map<String, (int, Set<int>)> addedFiles;

  SmartAlbumConfig({
    required this.collectionId,
    required this.personIDs,
    required this.addedFiles,
  });

  static const _personIdsKey = "smart_album_person_ids";
  static const _addedFilesKey = "smart_album_added_files";

  Future<SmartAlbumConfig> getUpdatedConfig(Set<String> newPersonsIds) async {
    final toAdd = newPersonsIds.difference(personIDs);
    final toRemove = personIDs.difference(newPersonsIds);
    final newFiles = Map<String, (int, Set<int>)>.from(addedFiles);

    // Remove whats not needed
    for (final personId in toRemove) {
      newFiles.remove(personId);
    }

    // Add files which are needed
    for (final personId in toAdd) {
      newFiles[personId] = (0, {});
    }

    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: newPersonsIds,
      addedFiles: newFiles,
    );
  }

  Future<SmartAlbumConfig> addFiles(
    String personId,
    int updatedAt,
    Set<int> fileId,
  ) async {
    if (!addedFiles.containsKey(personId)) {
      return this;
    }

    final newFiles = Map<String, (int, Set<int>)>.from(addedFiles);
    newFiles[personId] = (
      updatedAt,
      newFiles[personId]!.$2.union(fileId),
    );
    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: personIDs,
      addedFiles: newFiles,
    );
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      "${_personIdsKey}_$collectionId",
      personIDs.toList(),
    );

    await prefs.setString(
      "${_addedFilesKey}_$collectionId",
      addedFiles.entries
          .map((e) => "${e.key}:${e.value.$1}|${e.value.$2.join(',')}")
          .join(';'),
    );
  }

  static Future<SmartAlbumConfig> loadConfig(int collectionId) async {
    final personIDs =
        prefs.getStringList("${_personIdsKey}_$collectionId") ?? [];
    final addedFilesString =
        prefs.getString("${_addedFilesKey}_$collectionId") ?? "";

    final addedFiles = <String, (int, Set<int>)>{};
    if (addedFilesString.isNotEmpty) {
      for (final entry in addedFilesString.split(';')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          addedFiles[parts[0]] = (
            int.parse(parts[1].split('|')[0]),
            parts[1].split('|')[1].split(',').map(int.parse).toSet(),
          );
        }
      }
    }

    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: personIDs.toSet(),
      addedFiles: addedFiles,
    );
  }
}

final _lock = Lock();

Future<void> syncSmartAlbums() async {
  await _lock.synchronized(() async {
    // get all collections
    final collections = CollectionsService.instance.nonHiddenOwnedCollections();
    for (final collectionId in collections) {
      final config = await SmartAlbumConfig.loadConfig(collectionId);

      if (config.personIDs.isEmpty) {
        continue;
      }

      for (final personId in config.personIDs) {
        final person =
            await entityService.getEntity(EntityType.cgroup, personId);

        if (person == null ||
            config.addedFiles[personId]?.$1 == null ||
            (person.updatedAt <= config.addedFiles[personId]!.$1)) {
          continue;
        }

        final files =
            (await SearchService.instance.getClusterFilesForPersonID(personId))
                .entries
                .expand((e) => e.value)
                .toSet();

        final toBeSynced =
            files.difference(config.addedFiles[personId]?.$2 ?? {});

        if (toBeSynced.isNotEmpty) {
          final CollectionActions collectionActions =
              CollectionActions(CollectionsService.instance);
          final result = await collectionActions.addToCollection(
            null,
            collectionId,
            false,
            selectedFiles: toBeSynced.toList(),
          );
          if (result) {
            final newConfig = await config.addFiles(
              personId,
              person.updatedAt,
              toBeSynced.map((e) => e.uploadedFileID!).toSet(),
            );
            await newConfig.saveConfig();
          }
        }
      }
    }
  });
}
