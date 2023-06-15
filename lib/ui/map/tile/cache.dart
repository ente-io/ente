import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import "package:flutter_map/flutter_map.dart";

class TilesCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'tiles-cached-image-data';

  static final TilesCacheManager _instance = TilesCacheManager._();
  factory TilesCacheManager() {
    return _instance;
  }

  TilesCacheManager._() : super(Config(key));
}

class CachedNetworkTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      cacheManager: TilesCacheManager(),
    );
  }
}
