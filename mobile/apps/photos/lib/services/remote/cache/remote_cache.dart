import "dart:async";
import "package:logging/logging.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/db/remote/table/collection_files.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/models/file/remote/rl_mapping.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/filter/db_filters.dart";
import "package:photos/services/remote/localMapper/merge.dart";

class RemoteCache {
  final Logger logger = Logger("RemoteCache");
  Map<int, RemoteAsset> remoteAssets = {};
  Map<String, RLMapping> lToRMapping = {};
  Map<int, RLMapping> rToLMapping = {};
  bool _isLoaded = false;
  Completer<void>? _loadCompleter;

  Future<List<EnteFile>> getCollectionFiles(FilterQueryParam? params) async {
    if (!_isLoaded) await _ensureLoaded();
    final cf = await remoteDB.getCollectionFiles(params);
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return files;
  }

  Future<List<EnteFile>> getFilesForCollection(int collectionID) async {
    if (!_isLoaded) await _ensureLoaded();
    final cf = await remoteDB.getCollectionFiles(
      FilterQueryParam(
        collectionID: collectionID,
      ),
    );
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return files;
  }

  Future<List<EnteFile>> getFilesForCollections(Set<int> cIDs) async {
    final cf = await remoteDB.getCollectionsFiles(
      cIDs,
    );
    if (!_isLoaded) await _ensureLoaded();
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return files;
  }

  Future<FileLoadResult> getCollectionFilesResult(
    FilterQueryParam? params,
  ) async {
    if (!_isLoaded) await _ensureLoaded();
    final cf = await remoteDB.getCollectionFiles(params);
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return FileLoadResult(files, params?.limit == files.length);
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;

    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }
    _loadCompleter = Completer<void>();

    try {
      logger.info("Loading remote assets into cache");
      final rAssets = await remoteDB.getRemoteAssets();
      final mappings = await remoteDB.getMappings();
      for (final mapping in mappings) {
        lToRMapping[mapping.localID] = mapping;
        rToLMapping[mapping.remoteUploadID] = mapping;
      }
      for (final item in rAssets) {
        remoteAssets[item.id] = item;
      }
      _isLoaded = true;
      _loadCompleter!.complete();
    } catch (error) {
      _loadCompleter!.completeError(error);
      _loadCompleter = null;
      rethrow;
    }
  }

  Future<void> insertDiffItems(
    List<DiffItem> items,
  ) async {
    if (items.isEmpty) return;
    final rAssets = await remoteDB.insertDiffItems(items);
    for (final rAsset in rAssets) {
      remoteAssets[rAsset.id] = rAsset;
    }
  }

  Future<void> insertDiffPairItems(
    List<(CollectionFile, RemoteAsset)> items,
  ) async {
    if (items.isEmpty) return;
    // final rAssets = await remoteDB.insertDiffItems(items);
    for (final (_, remoteAsset) in items) {
      remoteAssets[remoteAsset.id] = remoteAsset;
    }
  }

  void updateItems(List<RemoteAsset> items) {
    for (final item in items) {
      remoteAssets[item.id] = item;
    }
  }

  Future<EnteFile?> getAlbumCover(Collection c) async {
    final cf = await remoteDB.coverFile(
      c.id,
      c.pubMagicMetadata.coverID,
      sortInAsc: c.pubMagicMetadata.asc ?? false,
    );
    if (cf == null) {
      return null;
    }
    if (!_isLoaded) await _ensureLoaded();
    final asset = remoteAssets[cf.fileID];
    if (asset == null) {
      return null;
    }
    return EnteFile.fromRemoteAsset(asset, cf);
  }

  Future<EnteFile?> getCollectionFile(int collectionID, int fileID) async {
    final cf = await remoteDB.getCollectionFileEntry(collectionID, fileID);
    if (cf == null) {
      return null;
    }

    if (!_isLoaded) await _ensureLoaded();
    final rAsset = remoteAssets[cf.fileID];
    if (rAsset == null) {
      return null;
    }
    return EnteFile.fromRemoteAsset(rAsset, cf);
  }

  Future<EnteFile?> getAnyCollectionFile(int fileID) async {
    final cf = await remoteDB.getAnyCollectionEntry(fileID);
    if (cf == null) {
      return null;
    }
    if (!_isLoaded) await _ensureLoaded();
    final asset = remoteAssets[cf.fileID];
    if (asset == null) {
      return null;
    }
    return EnteFile.fromRemoteAsset(asset, cf);
  }

  Future<Map<int, List<EnteFile>>> getFilesGroupByCollection(
    List<int> fileIDs,
  ) async {
    final collectionFiles =
        await remoteDB.getCollectionFilesGroupedByCollection(fileIDs);
    if (!_isLoaded) await _ensureLoaded();

    final Map<int, List<EnteFile>> result = {};

    for (final entry in collectionFiles.entries) {
      final collectionID = entry.key;
      final collectionFileList = entry.value;
      for (final cf in collectionFileList) {
        final asset = remoteAssets[cf.fileID];
        if (asset != null) {
          result[collectionID] ??= [];
          result[collectionID]!.add(EnteFile.fromRemoteAsset(asset, cf));
        }
      }
    }
    return result;
  }

  // Returns a map of fileID to EnteFile for the given fileIDs.
  // and also returns a set of fileIDs that were not found in the DB
  Future<(Map<int, EnteFile>, Set<int>)> getUniqueFiles(
    List<int> fileIDs, {
    Set<int> ignoredCollectionIDs = const {},
  }) async {
    final collectionFiles = await remoteDB.getAllCFForFileIDs(fileIDs);
    final Set<int> missingIDs = fileIDs.toSet();
    if (!_isLoaded) await _ensureLoaded();
    final Map<int, EnteFile> result = {};
    final Set<int> toIgnoreFileIds = {};
    for (final cf in collectionFiles) {
      missingIDs.remove(cf.fileID);
      final asset = remoteAssets[cf.fileID];
      if (asset != null) {
        result[cf.fileID] = EnteFile.fromRemoteAsset(asset, cf);
      }
      if (ignoredCollectionIDs.contains(cf.collectionID)) {
        toIgnoreFileIds.add(cf.fileID);
      }
    }
    for (final fileID in toIgnoreFileIds) {
      result.remove(fileID);
    }
    return (result, missingIDs);
  }

  Future<List<EnteFile>> getFilesCreatedWithinDurations(
    List<List<int>> durations,
    Set<int> ignoredCollectionIDs, {
    String order = 'DESC',
  }) async {
    final collectionFileEntries = await remoteDB.getFilesCreatedWithinDurations(
      durations,
      ignoredCollectionIDs,
      order: order,
    );
    if (!_isLoaded) await _ensureLoaded();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      }
    }
    return files;
  }

  Future<FileLoadResult> getFilesWithLocation(
    Set<int> ignoredCollectionIDs,
  ) async {
    final collectionFileEntries = await remoteDB.filesWithLocation();
    if (!_isLoaded) await _ensureLoaded();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      }
    }
    final filterFiles = await merge(
      localFiles: [],
      remoteFiles: files,
      filterOptions: DBFilterOptions(
        ignoredCollectionIDs: ignoredCollectionIDs,
      ),
    );
    return FileLoadResult(filterFiles, true);
  }

  Future<List<EnteFile>> getAllFiles(
    Set<int> ignoredCollectionIDs,
    int userID, {
    bool dedupeByUploadId = true,
  }) async {
    final collectionFileEntries = await remoteDB.getAllFiles(userID);
    if (!_isLoaded) await _ensureLoaded();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      }
    }
    return await merge(
      localFiles: [],
      remoteFiles: files,
      filterOptions: DBFilterOptions(
        ignoredCollectionIDs: ignoredCollectionIDs,
        dedupeUploadID: dedupeByUploadId,
      ),
    );
  }

  Future<Map<String, EnteFile>> ownedFilesWithSameHash(
    List<String> hashes,
    int ownerID,
  ) async {
    final collectionFileEntries = await remoteDB.ownedFilesWithSameHash(
      hashes,
      ownerID,
    );
    if (!_isLoaded) await _ensureLoaded();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      } else {
        throw Exception(
          'ownedFilesWithSameHash: remoteAsset not cached ${entry.fileID}',
        );
      }
    }
    final Map<String, EnteFile> fileMap = {};
    for (final file in files) {
      fileMap[file.rAsset!.hash!] = file;
    }
    return fileMap;
  }
}
