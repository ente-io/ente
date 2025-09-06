import "dart:io";

import 'package:photos/core/cache/lru_map.dart';

class FileLruCache {
  static final LRUMap<String, File> _map = LRUMap(25);

  static File? get(String key) {
    return _map.get(key);
  }

  static void put(String key, File value) {
    _map.put(key, value);
  }
}
