import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger('MagicUtil');

Future<void> changeVisibility(
    BuildContext context, List<File> files, int newVisibility) async {
  final dialog = createProgressDialog(context,
      newVisibility == kVisibilityArchive ? "archiving..." : "unarchiving...");
  await dialog.show();
  try {
    await FileMagicService.instance.changeVisibility(files, newVisibility);
    showShortToast(newVisibility == kVisibilityArchive
        ? "successfully archived"
        : "successfully unarchived");

    await dialog.hide();
  } catch (e, s) {
    _logger.severe("failed to update file visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}

Future<bool> editTime(
    BuildContext context, List<File> files, int editedTime) async {
  try {
    await _updatePublicMetadata(
        context, files, kPubMagicKeyEditedTime, editedTime);
    return true;
  } catch (e, s) {
    showToast('something went wrong');
    return false;
  }
}

Future<void> _updatePublicMetadata(
    BuildContext context, List<File> files, String key, dynamic value) async {
  if (files.isEmpty) {
    return;
  }
  final dialog = createProgressDialog(context, 'please wait...');
  await dialog.show();
  try {
    Map<String, dynamic> update = {key: value};
    await FileMagicService.instance.updatePublicMagicMetadata(files, update);
    showShortToast('done');
    await dialog.hide();
    if (_shouldReloadGallery(key)) {
      Bus.instance.fire(ForceReloadHomeGalleryEvent());
    }
  } catch (e, s) {
    _logger.severe("failed to update $key = $value", e, s);
    await dialog.hide();
    rethrow;
  }
}

bool _shouldReloadGallery(String key) {
  return key == kPubMagicKeyEditedTime;
}
