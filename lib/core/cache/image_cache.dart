import 'dart:io' as dart;

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/models/file.dart';

class FileLruCache {
  static LRUMap<String, dart.File> _map = LRUMap(25);

  static dart.File get(File file) {
    return _map.get(file.tag());
  }

  static void put(File file, dart.File imageData) {
    _map.put(file.tag(), imageData);
  }
}

class ThumbnailFileLruCache {
  static LRUMap<String, dart.File> _map = LRUMap(500);

  static dart.File get(File file) {
    return _map.get(file.tag());
  }

  static void put(File file, dart.File imageData) {
    _map.put(file.tag(), imageData);
  }
}
