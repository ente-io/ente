import 'dart:typed_data';

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/models/file.dart';

class ThumbnailLruCache {
  static LRUMap<_ThumbnailCacheKey, Uint8List> _map = LRUMap(1000);

  static Uint8List get(File photo, int size) {
    return _map.get(_ThumbnailCacheKey(photo, size));
  }

  static void put(File photo, int size, Uint8List imageData) {
    _map.put(_ThumbnailCacheKey(photo, size), imageData);
  }
}

class _ThumbnailCacheKey {
  File photo;
  int size;

  _ThumbnailCacheKey(this.photo, this.size);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThumbnailCacheKey &&
          runtimeType == other.runtimeType &&
          photo.hashCode == other.photo.hashCode &&
          size == other.size;

  @override
  int get hashCode => photo.hashCode * size.hashCode;
}
