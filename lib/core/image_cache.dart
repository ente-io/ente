import 'dart:typed_data';

import 'lru_map.dart';
import 'package:photos/models/photo.dart';

class ImageLruCache {
  static LRUMap<int, Uint8List> _map = LRUMap(500);

  static Uint8List get(Photo photo) {
    return _map.get(photo.generatedId);
  }

  static void put(Photo photo, Uint8List imageData) {
    _map.put(photo.generatedId, imageData);
  }
}
