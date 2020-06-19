import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';

Future<void> share(File file) async {
  final bytes = await file.getBytes();
  final filename = _getFilename(file.title);
  final ext = extension(file.title);
  final shareExt = file.title.endsWith(".HEIC")
      ? "jpg"
      : ext.substring(1, ext.length).toLowerCase();
  return Share.file(filename, filename, bytes, "image/" + shareExt);
}

Future<void> shareMultiple(List<File> files) async {
  final shareContent = Map<String, Uint8List>();
  for (File file in files) {
    shareContent[_getFilename(file.title)] = await file.getBytes();
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
