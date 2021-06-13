import 'dart:collection';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

typedef EvictionHandler<K, V>(K key, V value);

class LRUMap<K, V> {
  final LinkedHashMap<K, V?> _map = LinkedHashMap<K, V?>();
  final int _maxSize;
  final EvictionHandler<K, V?>? _handler;

  LRUMap(this._maxSize, [this._handler]);

  V? get(K key) {
    V? value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > _maxSize) {
      K evictedKey = _map.keys.first;
      V? evictedValue = _map.remove(evictedKey);
      if (_handler != null) {
        _handler!(evictedKey, evictedValue);
      }
    }
  }

  void remove(K key) {
    _map.remove(key);
  }
}

class ImageLruCache {
  static LRUMap<_ImageCacheEntity, Uint8List> _map = LRUMap(500);

  static Uint8List? getData(AssetEntity entity,
      [int size = 64, ThumbFormat format = ThumbFormat.jpeg]) {
    return _map.get(_ImageCacheEntity(entity, size, format));
  }

  static void setData(
      AssetEntity entity, int size, ThumbFormat format, Uint8List list) {
    _map.put(_ImageCacheEntity(entity, size, format), list);
  }
}

class _ImageCacheEntity {
  AssetEntity entity;
  int size;
  ThumbFormat format;

  _ImageCacheEntity(this.entity, this.size, this.format);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ImageCacheEntity &&
          runtimeType == other.runtimeType &&
          entity == other.entity &&
          size == other.size &&
          format == other.format;

  @override
  int get hashCode => entity.hashCode * size.hashCode * format.hashCode;
}
