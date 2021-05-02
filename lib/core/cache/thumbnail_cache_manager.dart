import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ThumbnailCacheManager {
  static const key = 'cached-thumbnail-data';
  static CacheManager instance = CacheManager(
    Config(
      key,
      maxNrOfCacheObjects: 2500,
    ),
  );
}
