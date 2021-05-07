import 'dart:typed_data';

import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';

class ThumbnailLruCache {
  static LRUMap<String, Uint8List> _map = LRUMap(1000);

  static Uint8List get(File photo, [int size]) {
    return _map.get(photo.generatedID.toString() +
        "_" +
        (size != null ? size.toString() : THUMBNAIL_LARGE_SIZE.toString()));
  }

  static void put(
    File photo,
    Uint8List imageData, [
    int size,
  ]) {
    _map.put(
        photo.generatedID.toString() +
            "_" +
            (size != null ? size.toString() : THUMBNAIL_LARGE_SIZE.toString()),
        imageData);
  }
}
