import "dart:io";

import "package:flutter/foundation.dart";

Uint8List unGzipUInt8List(Uint8List compressedData) {
  final codec = GZipCodec();
  final List<int> decompressedList = codec.decode(compressedData);
  return Uint8List.fromList(decompressedList);
}

// gzipUInt8List
Uint8List gzipUInt8List(Uint8List data) {
  final codec = GZipCodec();
  final compressedData = codec.encode(data);
  return Uint8List.fromList(compressedData);
}
