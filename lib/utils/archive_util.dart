import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

Future<void> changeVisibility(
    BuildContext context, List<File> files, int newVisibility) async {
  final dialog = createProgressDialog(context,
      newVisibility == kVisibilityArchive ? "archiving..." : "unarchiving...");
  await dialog.show();
  try {
    await FileMagicService.instance.changeVisibility(files, newVisibility);
    showToast(
        newVisibility == kVisibilityArchive
            ? "successfully archived"
            : "successfully unarchived",
        toastLength: Toast.LENGTH_SHORT);

    await dialog.hide();
  } catch (e, s) {
    Logger("ArchiveUtil").severe("failed to update file visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}
