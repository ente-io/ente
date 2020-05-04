import 'dart:typed_data';

import 'package:photos/core/lru_map.dart';
import 'package:photos/models/photo.dart';

class ThumbnailLruCache {
  static LRUMap<_ThumbnailCacheKey, Uint8List> _map = LRUMap(5000);

  static Uint8List get(Photo photo, int size) {
    return _map.get(_ThumbnailCacheKey(photo, size));
  }

  static void put(Photo photo, int size, Uint8List imageData) {
    _map.put(_ThumbnailCacheKey(photo, size), imageData);
  }
}

class _ThumbnailCacheKey {
  Photo photo;
  int size;

  _ThumbnailCacheKey(this.photo, this.size);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThumbnailCacheKey &&
          runtimeType == other.runtimeType &&
          photo.generatedId == other.photo.generatedId &&
          size == other.size;

  @override
  int get hashCode => photo.hashCode * size.hashCode;
}
