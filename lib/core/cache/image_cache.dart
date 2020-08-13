import 'dart:io' as io;

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/models/file.dart';

class FileLruCache {
  static LRUMap<String, io.File> _map = LRUMap(25);

  static io.File get(File file) {
    return _map.get(file.tag());
  }

  static void put(File file, io.File imageData) {
    _map.put(file.tag(), imageData);
  }
}

class ThumbnailFileLruCache {
  static LRUMap<String, io.File> _map = LRUMap(500);

  static io.File get(File file) {
    return _map.get(file.tag());
  }

  static void put(File file, io.File imageData) {
    _map.put(file.tag(), imageData);
  }
}
