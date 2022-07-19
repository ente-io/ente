import 'dart:typed_data';

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/ente_file.dart';

class ThumbnailLruCache {
  static final LRUMap<String, Uint8List> _map = LRUMap(1000);

  static Uint8List get(EnteFile photo, [int size]) {
    return _map.get(
      photo.cacheKey() +
          "_" +
          (size != null ? size.toString() : kThumbnailLargeSize.toString()),
    );
  }

  static void put(
    EnteFile photo,
    Uint8List imageData, [
    int size,
  ]) {
    _map.put(
      photo.cacheKey() +
          "_" +
          (size != null ? size.toString() : kThumbnailLargeSize.toString()),
      imageData,
    );
  }

  static void clearCache(EnteFile file) {
    _map.remove(
      file.cacheKey() + "_" + kThumbnailLargeSize.toString(),
    );
    _map.remove(
      file.cacheKey() + "_" + kThumbnailSmallSize.toString(),
    );
  }
}
