import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:photos/models/photo.dart';
import 'package:path/path.dart';

Future<void> share(Photo photo) async {
  final bytes = await photo.getBytes();
  final filename = _getFilename(photo.title);
  final ext = extension(photo.title);
  final shareExt = photo.title.endsWith(".HEIC")
      ? "jpg"
      : ext.substring(1, ext.length).toLowerCase();
  return Share.file(filename, filename, bytes, "image/" + shareExt);
}

Future<void> shareMultiple(List<Photo> photos) async {
  final shareContent = Map<String, Uint8List>();
  for (Photo photo in photos) {
    shareContent[_getFilename(photo.title)] = await photo.getBytes();
  }
  return Share.files("images", shareContent, "*/*");
}

String _getFilename(String name) {
  if (name.endsWith(".HEIC")) {
    return name.substring(0, name.lastIndexOf(".HEIC")) + ".JPG";
  } else {
    return name;
  }
}
