import "dart:async";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/events/collection_meta_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import 'package:photos/events/force_reload_home_gallery_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/collection_magic.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/dialog_util.dart';

final _logger = Logger('MagicUtil');

enum _VisibilityAction { hide, unHide, archive, unarchive }

Future<void> changeVisibility(
  BuildContext context,
  List<EnteFile> files,
  int newVisibility,
) async {
  final dialog = createProgressDialog(
    context,
    newVisibility == archiveVisibility
        ? S.of(context).archiving
        : S.of(context).unarchiving,
  );
  await dialog.show();
  try {
    await FileMagicService.instance.changeVisibility(files, newVisibility);
    showShortToast(
      context,
      newVisibility == archiveVisibility
          ? S.of(context).successfullyArchived
          : S.of(context).successfullyUnarchived,
    );

    await dialog.hide();
  } catch (e, s) {
    _logger.severe("failed to update file visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}

Future<void> changeCollectionVisibility(
  BuildContext context, {
  required Collection collection,
  required int newVisibility,
  required int prevVisibility,
  bool isOwner = true,
}) async {
  final visibilityAction =
      _getVisibilityAction(context, newVisibility, prevVisibility);
  final dialog = createProgressDialog(
    context,
    _visActionProgressDialogText(
      context,
      visibilityAction,
    ),
  );

  await dialog.show();
  try {
    final Map<String, dynamic> update = {magicKeyVisibility: newVisibility};
    if (isOwner) {
      await CollectionsService.instance.updateMagicMetadata(collection, update);
    } else {
      await CollectionsService.instance
          .updateShareeMagicMetadata(collection, update);
    }
    // Force reload home gallery to pull in/remove the now visibility changed
    // files
    Bus.instance.fire(
      ForceReloadHomeGalleryEvent(
        "CollectionVisibilityChange: $visibilityAction",
      ),
    );
    showShortToast(
      context,
      _visActionSuccessfulText(
        context,
        visibilityAction,
      ),
    );

    await dialog.hide();
  } catch (e, s) {
    _logger.severe("failed to update collection visibility", e, s);
    await dialog.hide();
    rethrow;
  }
}

Future<void> changeSortOrder(
  BuildContext context,
  Collection collection,
  bool sortedInAscOrder,
) async {
  try {
    final Map<String, dynamic> update = {"asc": sortedInAscOrder};
    await CollectionsService.instance
        .updatePublicMagicMetadata(collection, update);
    Bus.instance.fire(
      CollectionMetaEvent(collection.id, CollectionMetaEventType.sortChanged),
    );
  } catch (e, s) {
    _logger.severe("failed to update collection visibility", e, s);
    showShortToast(context, S.of(context).somethingWentWrong);
    rethrow;
  }
}

Future<void> updateOrder(
  BuildContext context,
  Collection collection,
  int order,
) async {
  try {
    final Map<String, dynamic> update = {
      orderKey: order,
    };
    await CollectionsService.instance.updateMagicMetadata(collection, update);
    Bus.instance.fire(
      CollectionMetaEvent(collection.id, CollectionMetaEventType.orderChanged),
    );
  } catch (e, s) {
    _logger.severe("failed to update order", e, s);
    showShortToast(context, S.of(context).somethingWentWrong);
    rethrow;
  }
}

// changeCoverPhoto is used to change cover photo for a collection. To reset to
// default cover photo, pass uploadedFileID as 0
Future<void> changeCoverPhoto(
  BuildContext context,
  Collection collection,
  int uploadedFileID,
) async {
  try {
    final Map<String, dynamic> update = {"coverID": uploadedFileID};
    await CollectionsService.instance
        .updatePublicMagicMetadata(collection, update);
    Bus.instance.fire(
      CollectionUpdatedEvent(
        collection.id,
        <EnteFile>[],
        "cover_change",
        type: EventType.coverChanged,
      ),
    );
  } catch (e, s) {
    _logger.severe("failed to update cover", e, s);
    showShortToast(context, S.of(context).somethingWentWrong);
    rethrow;
  }
}

Future<bool> editTime(
  BuildContext context,
  Map<EnteFile, int> filesToEditedTimes,
) async {
  try {
    final files = filesToEditedTimes.keys
        .where((file) => file.uploadedFileID != null)
        .toList();
    if (files.isEmpty) {
      _logger.severe('No files to edit time for');
      return false;
    }
    final fileIdToTimeUpdate = <int, Map<String, dynamic>>{};
    for (final entry in filesToEditedTimes.entries) {
      final file = entry.key;
      if (file.uploadedFileID == null) continue;
      final editedTime = entry.value;
      fileIdToTimeUpdate[file.uploadedFileID!] = {editTimeKey: editedTime};
    }

    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
    try {
      await FileMagicService.instance.updatePublicMagicMetadata(
        files,
        null,
        metadataUpdateMap: fileIdToTimeUpdate,
      );
      if (_shouldReloadGallery(editTimeKey)) {
        Bus.instance.fire(
          ForceReloadHomeGalleryEvent("FileMetadataChange-$editTimeKey"),
        );
      }
      showShortToast(context, S.of(context).done);
      await dialog.hide();
    } catch (e, s) {
      _logger.severe("failed to update times $fileIdToTimeUpdate", e, s);
      await dialog.hide();
      rethrow;
    }
    return true;
  } catch (e) {
    showShortToast(context, S.of(context).somethingWentWrong);
    return false;
  }
}

Future<void> editFilename(
  BuildContext context,
  EnteFile file,
) async {
  final fileName = file.displayName;
  final nameWithoutExt = basenameWithoutExtension(fileName);
  final extName = extension(fileName);
  final result = await showTextInputDialog(
    context,
    title: S.of(context).renameFile,
    submitButtonLabel: S.of(context).rename,
    initialValue: nameWithoutExt,
    message: extName.toUpperCase(),
    alignMessage: Alignment.centerRight,
    hintText: S.of(context).enterFileName,
    maxLength: 50,
    alwaysShowSuccessState: true,
    onSubmit: (String text) async {
      if (text.isEmpty || text.trim() == nameWithoutExt.trim()) {
        return;
      }
      final newName = text + extName;
      await _updatePublicMetadata(
        context,
        List.of([file]),
        editNameKey,
        newName,
        showProgressDialogs: false,
        showDoneToast: false,
      );
    },
  );
  if (result is Exception) {
    _logger.severe("Failed to rename file");
    await showGenericErrorDialog(context: context, error: result);
  }
}

Future<bool> editFileCaption(
  BuildContext? context,
  EnteFile file,
  String caption,
) async {
  try {
    await _updatePublicMetadata(
      context,
      [file],
      captionKey,
      caption,
      showDoneToast: false,
    );

    return true;
  } catch (e) {
    return false;
  }
}

Future<void> _updatePublicMetadata(
  BuildContext? context,
  List<EnteFile> files,
  String key,
  dynamic value, {
  bool showDoneToast = true,
  bool showProgressDialogs = true,
}) async {
  if (files.isEmpty) {
    return;
  }
  ProgressDialog? dialog;
  if (context != null && showProgressDialogs) {
    dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
  }
  try {
    final Map<String, dynamic> update = {key: value};
    await FileMagicService.instance.updatePublicMagicMetadata(files, update);
    if (context != null) {
      if (showDoneToast) {
        showShortToast(context, S.of(context).done);
      }
      await dialog?.hide();
    }

    if (_shouldReloadGallery(key)) {
      Bus.instance.fire(ForceReloadHomeGalleryEvent("FileMetadataChange-$key"));
    }
  } catch (e, s) {
    _logger.severe("failed to update $key = $value", e, s);
    if (context != null) {
      await dialog?.hide();
    }
    rethrow;
  }
}

bool _shouldReloadGallery(String key) {
  return key == editTimeKey;
}

_visActionProgressDialogText(BuildContext context, _VisibilityAction action) {
  switch (action) {
    case _VisibilityAction.archive:
      return S.of(context).archiving;
    case _VisibilityAction.hide:
      return S.of(context).hiding;
    case _VisibilityAction.unarchive:
      return S.of(context).unarchiving;
    case _VisibilityAction.unHide:
      return S.of(context).unhiding;
  }
}

_visActionSuccessfulText(BuildContext context, _VisibilityAction action) {
  switch (action) {
    case _VisibilityAction.archive:
      return S.of(context).successfullyArchived;
    case _VisibilityAction.hide:
      return S.of(context).successfullyHid;
    case _VisibilityAction.unarchive:
      return S.of(context).successfullyUnarchived;
    case _VisibilityAction.unHide:
      return S.of(context).successfullyUnhid;
  }
}

_VisibilityAction _getVisibilityAction(
  context,
  int newVisibility,
  int prevVisibility,
) {
  if (newVisibility == archiveVisibility) {
    return _VisibilityAction.archive;
  } else if (newVisibility == hiddenVisibility) {
    return _VisibilityAction.hide;
  } else if (newVisibility == visibleVisibility &&
      prevVisibility == archiveVisibility) {
    return _VisibilityAction.unarchive;
  } else {
    return _VisibilityAction.unHide;
  }
}
