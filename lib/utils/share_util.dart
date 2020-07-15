import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:photos/utils/dialog_util.dart';

Future<void> share(BuildContext context, File file) async {
  final dialog = createProgressDialog(context, "Preparing...");
  await dialog.show();
  final bytes = await file.getBytes();
  final filename = _getFilename(file.title);
  final ext = extension(file.title);
  final shareExt = file.title.endsWith(".HEIC")
      ? "jpg"
      : ext.substring(1, ext.length).toLowerCase();
  await dialog.hide();
  return Share.file(filename, filename, bytes, "image/" + shareExt);
}

Future<void> shareMultiple(BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "Preparing...");
  await dialog.show();
  final shareContent = Map<String, Uint8List>();
  for (File file in files) {
    shareContent[_getFilename(file.title)] = await file.getBytes();
  }
  await dialog.hide();
  return Share.files("images", shareContent, "*/*");
}

String _getFilename(String name) {
  if (name.endsWith(".HEIC")) {
    return name.substring(0, name.lastIndexOf(".HEIC")) + ".JPG";
  } else {
    return name;
  }
}
