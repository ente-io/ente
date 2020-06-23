import 'dart:io' as dart;
import 'dart:typed_data';

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

class BytesLruCache {
  static LRUMap<String, Uint8List> _map = LRUMap(25);

  static Uint8List get(File file) {
    return _map.get(file.tag());
  }

  static void put(File file, Uint8List imageData) {
    _map.put(file.tag(), imageData);
  }
}
