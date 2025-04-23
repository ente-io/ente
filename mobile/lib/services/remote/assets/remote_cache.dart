import "package:flutter/foundation.dart";
import "package:photos/db/remote/read/collection_files.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
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

  Future<void> _load() async {
    if (isLoaded == null) {
      final assets = await remoteDB.getAllFiles();
      for (final asset in assets) {
        remoteAssets[asset.id] = asset;
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
    final _ = isLoaded ?? await _load();
    if (cf == null) {
      return null;
    }
    final asset = remoteAssets[cf.fileID];
    if (asset == null) {
      return null;
    }
    return EnteFile.fromRemoteAsset(asset, cf);
  }
}
