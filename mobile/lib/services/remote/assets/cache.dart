import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/file_entry.dart";

class RemoteAssetCache {
  final Map<int, RemoteAsset> _cache = {};
  final Map<int, Set<int>> _collectionsToAssets = {};
  final Map<int, Set<int>> _assetsToCollections = {};
  final Map<String, CollectionFileEntry> _fileEntries = {};

  List<int>? uncachedAssets(List<int> assetIDs) {
    final missing = <int>[];
    for (final id in assetIDs) {
      if (!_cache.containsKey(id)) {
        missing.add(id);
      }
    }
    return missing.isEmpty ? null : missing;
  }

  void addOrUpdate(List<RemoteAsset> assets) {
    for (final asset in assets) {
      _cache[asset.id] = asset;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
