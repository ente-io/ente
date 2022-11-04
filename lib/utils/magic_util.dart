// @dart=2.9

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/common/rename_dialog.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger('MagicUtil');

Future<void> changeVisibility(
  BuildContext context,
  List<File> files,
  int newVisibility,
) async {
  final dialog = createProgressDialog(
    context,
    newVisibility == visibilityArchive ? "Hiding..." : "Unhiding...",
  );
  await dialog.show();
  try {
    await FileMagicService.instance.changeVisibility(files, newVisibility);
    showShortToast(
      context,
      newVisibility == visibilityArchive
          ? "Successfully hidden"
          : "Successfully unhidden",
    );

    await dialog.hide();
  } catch (e, s) {
    _logger.severe("failed to update file visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}

Future<void> changeCollectionVisibility(
  BuildContext context,
  Collection collection,
  int newVisibility,
) async {
  final dialog = createProgressDialog(
    context,
    newVisibility == visibilityArchive ? "Hiding..." : "Unhiding...",
  );
  await dialog.show();
  try {
    final Map<String, dynamic> update = {magicKeyVisibility: newVisibility};
    await CollectionsService.instance.updateMagicMetadata(collection, update);
    // Force reload home gallery to pull in the now unarchived files
    Bus.instance.fire(ForceReloadHomeGalleryEvent());
    showShortToast(
      context,
      newVisibility == visibilityArchive
          ? "Successfully hidden"
          : "Successfully unhidden",
    );

    await dialog.hide();
  } catch (e, s) {
    _logger.severe("failed to update collection visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}

Future<bool> editTime(
  BuildContext context,
  List<File> files,
  int editedTime,
) async {
  try {
    await _updatePublicMetadata(
      context,
      files,
      pubMagicKeyEditedTime,
      editedTime,
    );
    return true;
  } catch (e) {
    showToast(context, 'something went wrong');
    return false;
  }
}

Future<bool> editFilename(
  BuildContext context,
  File file,
) async {
  try {
    final fileName = file.displayName;
    final nameWithoutExt = basenameWithoutExtension(fileName);
    final extName = extension(fileName);
    var result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return RenameDialog(nameWithoutExt, 'file', maxLength: 50);
      },
      barrierColor: Colors.black.withOpacity(0.85),
    );

    if (result == null || result.trim() == nameWithoutExt.trim()) {
      return true;
    }
    result = result + extName;
    await _updatePublicMetadata(
      context,
      List.of([file]),
      pubMagicKeyEditedName,
      result,
    );
    return true;
  } catch (e) {
    showToast(context, 'Something went wrong');
    return false;
  }
}

Future<bool> editFileCaption(
  BuildContext context,
  File file,
  String caption,
) async {
  try {
    await _updatePublicMetadata(context, [file], pubMagicKeyCaption, caption);
    return true;
  } catch (e) {
    if (context != null) {
      showToast(context, "Something went wrong");
    }
    return false;
  }
}

Future<void> _updatePublicMetadata(
  BuildContext context,
  List<File> files,
  String key,
  dynamic value,
) async {
  if (files.isEmpty) {
    return;
  }
  ProgressDialog dialog;
  if (context != null) {
    dialog = createProgressDialog(context, 'please wait...');
    await dialog.show();
  }
  try {
    final Map<String, dynamic> update = {key: value};
    await FileMagicService.instance.updatePublicMagicMetadata(files, update);
    if (context != null) {
      showShortToast(context, 'done');
      await dialog.hide();
    }

    if (_shouldReloadGallery(key)) {
      Bus.instance.fire(ForceReloadHomeGalleryEvent());
    }
  } catch (e, s) {
    _logger.severe("failed to update $key = $value", e, s);
    if (context != null) {
      await dialog.hide();
    }
    rethrow;
  }
}

bool _shouldReloadGallery(String key) {
  return key == pubMagicKeyEditedTime;
}
