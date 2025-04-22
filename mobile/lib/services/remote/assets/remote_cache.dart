import "package:photos/db/remote/read/collection_files.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/service_locator.dart";

class RemoteCache {
  Map<int, RemoteAsset> remoteAssets = {};
  bool? isLoaded;

  Future<List<EnteFile>> getCollectionFiles(FilterQueryParam? params) async {
    final cf = await remoteDB.getCollectionFiles(params);
    if (isLoaded == null) {
      final assets = await remoteDB.getAllFiles();
      for (final asset in assets) {
        remoteAssets[asset.id] = asset;
      }
      isLoaded = true;
    }
    final List<EnteFile> files = [];
    for (final file in cf) {
      final asset = remoteAssets[file.fileID];
      if (asset != null) {
        files.add(EnteFile.fromRemoteAsset(asset, file));
      }
    }
    return files;
  }
}
