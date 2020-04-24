import 'dart:typed_data';

import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';

class ThumbnailLruCache {
  static LRUMap<int, Uint8List> _map = LRUMap(500);

  static Uint8List get(Photo photo) {
    return _map.get(photo.generatedId);
  }

  static void put(Photo photo, Uint8List imageData) {
    _map.put(photo.generatedId, imageData);
  }
}
