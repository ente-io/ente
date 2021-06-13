part of '../photo_manager.dart';

/// Cached thumbnails for album management.
class PhotoCachingManager {
  PhotoCachingManager._();

  static late final PhotoCachingManager _ins = PhotoCachingManager._();

  final _plugin = Plugin();

  static const ThumbOption defaultOption = const ThumbOption(
    width: 150,
    height: 150,
    format: ThumbFormat.jpeg,
    quality: 100,
  );

  /// Singleton.
  factory PhotoCachingManager() => _ins;

  // /// Request to cache the photo album's thumbnails.
  // ///
  // ///
  // Future<String> requestCachePath({
  //   @required AssetPathEntity entity,
  //   ThumbOption option = defaultOption,
  // }) {
  //   assert(entity != null);
  //   assert(option != null);
  // }

  Future<void> requestCacheAssets({
    required List<AssetEntity> assets,
    ThumbOption option = defaultOption,
  }) async {
    assert(assets.isNotEmpty);

    await _plugin.requestCacheAssetsThumb(
      assets.map((e) => e.id).toList(),
      option,
    );
  }

  Future<void> requestCacheAssetsWithIds({
    required List<String> assetIds,
    ThumbOption option = defaultOption,
  }) async {
    assert(assetIds.isNotEmpty);

    await _plugin.requestCacheAssetsThumb(
      assetIds,
      option,
    );
  }

  /// Cancel all cache request.
  Future<void> cancelCacheRequest() => _plugin.cancelCacheRequests();
}
