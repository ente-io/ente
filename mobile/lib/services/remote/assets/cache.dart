import "package:photos/models/file/remote/asset.dart";

class RemoteAssetCache {
  static final RemoteAssetCache _instance = RemoteAssetCache._internal();

  factory RemoteAssetCache() {
    return _instance;
  }

  RemoteAssetCache._internal();

  final Map<int, RemoteAsset> _cache = {};

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
