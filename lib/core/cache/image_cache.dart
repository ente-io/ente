import 'dart:io' as io;

import 'package:photos/core/cache/lru_map.dart';

class FileLruCache {
  static final LRUMap<String, io.File> _map = LRUMap(25);

  static io.File? get(String key) {
    return _map.get(key);
  }

  static void put(String key, io.File value) {
    _map.put(key, value);
  }
}
