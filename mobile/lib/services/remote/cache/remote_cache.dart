import "package:photos/db/remote/schema.dart";
import "package:photos/db/remote/table/collection_files.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/service_locator.dart";

class RemoteCache {
  Map<int, RemoteAsset> remoteAssets = {};
  bool? isLoaded;

  Future<List<EnteFile>> getCollectionFiles(FilterQueryParam? params) async {
    final cf = await remoteDB.getCollectionFiles(params);
    final _ = isLoaded ?? await _load();
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
    final cf = await remoteDB.getCollectionFiles(params);
    final _ = isLoaded ?? await _load();
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return FileLoadResult(files, params?.limit == files.length);
  }

  Future<void> _load() async {
    if (isLoaded == null) {
      final rAssets = await remoteDB.getRemoteAssets();
      for (final item in rAssets) {
        remoteAssets[item.id] = item;
      }
      isLoaded = true;
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
    final _ = isLoaded ?? await _load();
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

    final _ = isLoaded ?? await _load();
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
    final _ = isLoaded ?? await _load();
    final asset = remoteAssets[cf.fileID];
    if (asset == null) {
      return null;
    }
    return EnteFile.fromRemoteAsset(asset, cf);
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
    final _ = isLoaded ?? await _load();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      }
    }
    return files;
  }

  Future<Map<String, EnteFile>> ownedFilesWithSameHash(
    List<String> hashes,
    int ownerID,
  ) async {
    final collectionFileEntries = await remoteDB.ownedFilesWithSameHash(
      hashes,
      ownerID,
    );
    final _ = isLoaded ?? await _load();
    final List<EnteFile> files = [];
    for (final entry in collectionFileEntries) {
      final asset = remoteAssets[entry.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, entry));
      } else {
        // If the asset is not found, we can log or handle it as needed.
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
