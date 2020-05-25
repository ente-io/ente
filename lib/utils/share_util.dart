import 'dart:io';
import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/foundation.dart';
import 'package:photos/models/photo.dart';
import 'package:path/path.dart';

Future<void> share(Photo photo) async {
  final bytes = await _getPhotoBytes(photo);
  final ext = extension(photo.title);
  final shareExt =
      ext == ".HEIC" ? "jpeg" : ext.substring(1, ext.length).toLowerCase();
  return Share.file(photo.title, photo.title, bytes, "image/" + shareExt);
}

Future<void> shareMultiple(List<Photo> photos) async {
  final shareContent = Map<String, Uint8List>();
  for (Photo photo in photos) {
    shareContent[photo.title] = await _getPhotoBytes(photo);
  }
  return Share.files("images", shareContent, "*/*");
}

Future<Uint8List> _getPhotoBytes(Photo photo) async {
  if (photo.localId != null) {
    return await photo.getBytes();
  } else {
    var request = await HttpClient().getUrl(Uri.parse(photo.getRemoteUrl()));
    var response = await request.close();
    return await consolidateHttpClientResponseBytes(response);
  }
}
