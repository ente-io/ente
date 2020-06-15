import 'dart:io';
import 'dart:typed_data';

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/models/photo.dart';

class FileLruCache {
  static LRUMap<int, File> _map = LRUMap(25);

  static File get(Photo photo) {
    return _map.get(photo.hashCode);
  }

  static void put(Photo photo, File imageData) {
    _map.put(photo.hashCode, imageData);
  }
}

class BytesLruCache {
  static LRUMap<int, Uint8List> _map = LRUMap(25);

  static Uint8List get(Photo photo) {
    return _map.get(photo.hashCode);
  }

  static void put(Photo photo, Uint8List imageData) {
    _map.put(photo.hashCode, imageData);
  }
}
