import 'package:share/share.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';

Future<void> share(BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "preparing...");
  await dialog.show();
  final List<Future<String>> pathFutures = [];
  for (File file in files) {
    pathFutures.add(getFile(file).then((file) => file.path));
  }
  final paths = await Future.wait(pathFutures);
  await dialog.hide();
  return Share.shareFiles(paths);
}

Future<void> shareText(String text) async {
  return Share.share(text);
}
