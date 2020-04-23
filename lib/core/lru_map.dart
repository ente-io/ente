import 'dart:collection';
import 'dart:typed_data';

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
  static LRUMap<_ImageCacheEntity, Uint8List> _map = LRUMap(500);

  static Uint8List getData(int id, [int size = 64]) {
    return _map.get(_ImageCacheEntity(id, size));
  }

  static void setData(int id, int size, Uint8List imageData) {
    _map.put(_ImageCacheEntity(id, size), imageData);
  }
}

class _ImageCacheEntity {
  int id;
  int size;

  _ImageCacheEntity(this.id, this.size);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ImageCacheEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          size == other.size;

  @override
  int get hashCode => id.hashCode ^ size.hashCode;
}
