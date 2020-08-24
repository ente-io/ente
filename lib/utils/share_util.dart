import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:share_extend/share_extend.dart';

Future<void> share(BuildContext context, File file) async {
  final dialog = createProgressDialog(context, "Preparing...");
  if (file.fileType == FileType.image) {
    return _shareImage(dialog, file);
  } else {
    return _shareVideo(dialog, file);
  }
}

Future<void> shareMultiple(BuildContext context, List<File> files) async {
  if (files.length == 1) {
    return share(context, files[0]);
  }
  final dialog = createProgressDialog(context, "Preparing...");
  await dialog.show();
  final pathList = List<String>();
  for (File file in files) {
    pathList.add((await getNativeFile(file)).path);
  }
  await dialog.hide();
  return ShareExtend.shareMultiple(pathList, "image");
}

Future<void> _shareVideo(ProgressDialog dialog, File file) async {
  await dialog.show();
  final path = (await getNativeFile(file)).path;
  await dialog.hide();
  return ShareExtend.share(path, "image");
}

Future<void> _shareImage(ProgressDialog dialog, File file) async {
  await dialog.show();
  final bytes = await getBytes(file);
  final filename = _getFilename(file.title);
  final ext = extension(file.title);
  final shareExt = file.title.endsWith(".HEIC")
      ? "jpg"
      : ext.substring(1, ext.length).toLowerCase();
  await dialog.hide();
  return Share.file(filename, filename, bytes, "image/" + shareExt);
}

String _getFilename(String name) {
  if (name.endsWith(".HEIC")) {
    return name.substring(0, name.lastIndexOf(".HEIC")) + ".JPG";
  } else {
    return name;
  }
}
