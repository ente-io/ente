import 'dart:collection';

import 'package:flutter/material.dart';

typedef EvictionHandler<K, V>(K key, V value);

class LRUMap<K, V> {
  final LinkedHashMap<K, V> _map = new LinkedHashMap<K, V>();
  final int _maxSize;
  final EvictionHandler<K, V> _handler;

  LRUMap(this._maxSize, [this._handler]);

  V get(K key) {
    V value = _map.remove(key);
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
      V evictedValue = _map.remove(evictedKey);
      if (_handler != null) {
        _handler(evictedKey, evictedValue);
      }
    }
  }

  void remove(K key) {
    _map.remove(key);
  }
}

class ImageLruCache {
  static LRUMap<_ImageCacheEntity, Image> _map = LRUMap(500);

  static Image getData(String path, [int size = 64]) {
    return _map.get(_ImageCacheEntity(path, size));
  }

  static void setData(String path, int size, Image image) {
    _map.put(_ImageCacheEntity(path, size), image);
  }
}

class _ImageCacheEntity {
  String path;
  int size;

  _ImageCacheEntity(this.path, this.size);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ImageCacheEntity &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          size == other.size;

  @override
  int get hashCode => path.hashCode ^ size.hashCode;
}
