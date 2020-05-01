import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:photos/models/photo.dart';
import 'package:path/path.dart';

Future<void> share(Photo photo) async {
  final bytes = await photo.getBytes();
  final ext = extension(photo.title);
  final shareExt =
      ext == ".HEIC" ? "jpeg" : ext.substring(1, ext.length).toLowerCase();
  return Share.file(photo.title, photo.title, bytes, "image/" + shareExt);
}

Future<void> shareMultiple(List<Photo> photos) async {
  final shareContent = Map<String, Uint8List>();
  for (Photo photo in photos) {
    shareContent[photo.title] = await photo.getBytes();
  }
  return Share.files("images", shareContent, "*/*");
}
