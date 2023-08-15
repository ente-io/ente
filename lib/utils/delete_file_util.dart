import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/events/force_reload_trash_page_event.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/trash_item_request.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/trash_sync_service.dart';
import 'package:photos/ui/common/linear_progress_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/utils/device_info.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
  BuildContext context,
  List<File> files,
) async {
  _logger.info("Trying to deleteFilesFromEverywhere " + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  bool hasLocalOnlyFiles = false;
  for (final file in files) {
    if (file.localID != null) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID!);
      } else if (file.isSharedMediaToAppSandbox) {
        localSharedMediaIDs.add(file.localID!);
      } else {
        localAssetIDs.add(file.localID!);
      }
    }
    if (file.uploadedFileID == null) {
      hasLocalOnlyFiles = true;
    }
  }
  if (hasLocalOnlyFiles && Platform.isAndroid) {
    final shouldProceed = await shouldProceedWithDeletion(context);
    if (!shouldProceed) {
      return;
    }
  }
  Set<String> deletedIDs = <String>{};
  try {
    deletedIDs =
        (await PhotoManager.editor.deleteWithIds(localAssetIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));
  final updatedCollectionIDs = <int>{};
  final List<TrashRequest> uploadedFilesToBeTrashed = [];
  final List<File> deletedFiles = [];
  for (final file in files) {
    if (file.localID != null) {
      // Remove only those files that have already been removed from disk
      if (deletedIDs.contains(file.localID) ||
          alreadyDeletedIDs.contains(file.localID)) {
        deletedFiles.add(file);
        if (file.uploadedFileID != null) {
          uploadedFilesToBeTrashed
              .add(TrashRequest(file.uploadedFileID!, file.collectionID!));
          updatedCollectionIDs.add(file.collectionID!);
        } else {
          await FilesDB.instance.deleteLocalFile(file);
        }
      }
    } else {
      updatedCollectionIDs.add(file.collectionID!);
      deletedFiles.add(file);
      uploadedFilesToBeTrashed
          .add(TrashRequest(file.uploadedFileID!, file.collectionID!));
    }
  }
  if (uploadedFilesToBeTrashed.isNotEmpty) {
    try {
      final fileIDs =
          uploadedFilesToBeTrashed.map((item) => item.fileID).toList();
      await TrashSyncService.instance
          .trashFilesOnServer(uploadedFilesToBeTrashed);
      await FilesDB.instance.deleteMultipleUploadedFiles(fileIDs);
    } catch (e) {
      _logger.severe(e);
      showGenericErrorDialog(context: context);
      rethrow;
    }
    for (final collectionID in updatedCollectionIDs) {
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collectionID,
          deletedFiles
              .where((file) => file.collectionID == collectionID)
              .toList(),
          "deleteFilesEverywhere",
          type: EventType.deletedFromEverywhere,
        ),
      );
    }
  }
  if (deletedFiles.isNotEmpty) {
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(
        deletedFiles,
        type: EventType.deletedFromEverywhere,
        source: "deleteFilesEverywhere",
      ),
    );
    if (hasLocalOnlyFiles && Platform.isAndroid) {
      showShortToast(context, S.of(context).filesDeleted);
    } else {
      showShortToast(context, S.of(context).movedToTrash);
    }
  }
  if (uploadedFilesToBeTrashed.isNotEmpty) {
    RemoteSyncService.instance.sync(silently: true);
  }
}

Future<void> deleteFilesFromRemoteOnly(
  BuildContext context,
  List<File> files,
) async {
  files.removeWhere((element) => element.uploadedFileID == null);
  if (files.isEmpty) {
    showToast(context, S.of(context).selectedFilesAreNotOnEnte);
    return;
  }
  _logger.info(
    "Trying to deleteFilesFromRemoteOnly " +
        files.map((f) => f.uploadedFileID).toString(),
  );
  final updatedCollectionIDs = <int>{};
  final List<int> uploadedFileIDs = [];
  final List<TrashRequest> trashRequests = [];
  for (final file in files) {
    updatedCollectionIDs.add(file.collectionID!);
    uploadedFileIDs.add(file.uploadedFileID!);
    trashRequests.add(TrashRequest(file.uploadedFileID!, file.collectionID!));
  }
  try {
    await TrashSyncService.instance.trashFilesOnServer(trashRequests);
    await FilesDB.instance.deleteMultipleUploadedFiles(uploadedFileIDs);
  } catch (e, s) {
    _logger.severe("Failed to delete files from remote", e, s);
    showGenericErrorDialog(context: context);
    rethrow;
  }
  for (final collectionID in updatedCollectionIDs) {
    Bus.instance.fire(
      CollectionUpdatedEvent(
        collectionID,
        files.where((file) => file.collectionID == collectionID).toList(),
        "deleteFromRemoteOnly",
        type: EventType.deletedFromRemote,
      ),
    );
  }
  Bus.instance.fire(
    LocalPhotosUpdatedEvent(
      files,
      type: EventType.deletedFromRemote,
      source: "deleteFromRemoteOnly",
    ),
  );
  SyncService.instance.sync();
  RemoteSyncService.instance.sync(silently: true);
}

Future<void> deleteFilesOnDeviceOnly(
  BuildContext context,
  List<File> files,
) async {
  _logger.info("Trying to deleteFilesOnDeviceOnly" + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  bool hasLocalOnlyFiles = false;
  for (final file in files) {
    if (file.localID != null) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID!);
      } else if (file.isSharedMediaToAppSandbox) {
        localSharedMediaIDs.add(file.localID!);
      } else {
        localAssetIDs.add(file.localID!);
      }
    }
    if (file.uploadedFileID == null) {
      hasLocalOnlyFiles = true;
    }
  }
  if (hasLocalOnlyFiles && Platform.isAndroid) {
    final shouldProceed = await shouldProceedWithDeletion(context);
    if (!shouldProceed) {
      return;
    }
  }
  Set<String> deletedIDs = <String>{};
  try {
    deletedIDs =
        (await PhotoManager.editor.deleteWithIds(localAssetIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));
  final List<File> deletedFiles = [];
  for (final file in files) {
    // Remove only those files that have been removed from disk
    if (deletedIDs.contains(file.localID) ||
        alreadyDeletedIDs.contains(file.localID)) {
      deletedFiles.add(file);
      file.localID = null;
      FilesDB.instance.update(file);
    }
  }
  if (deletedFiles.isNotEmpty || alreadyDeletedIDs.isNotEmpty) {
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(
        deletedFiles,
        type: EventType.deletedFromDevice,
        source: "deleteFilesOnDeviceOnly",
      ),
    );
  }
}

Future<bool> deleteFromTrash(BuildContext context, List<File> files) async {
  bool didDeletionStart = false;
  final actionResult = await showChoiceActionSheet(
    context,
    title: S.of(context).permanentlyDelete,
    body: S.of(context).thisActionCannotBeUndone,
    firstButtonLabel: S.of(context).delete,
    isCritical: true,
    firstButtonOnTap: () async {
      try {
        didDeletionStart = true;
        await TrashSyncService.instance.deleteFromTrash(files);
        Bus.instance.fire(
          FilesUpdatedEvent(
            files,
            type: EventType.deletedFromEverywhere,
            source: "deleteFromTrash",
          ),
        );
        //the FilesUpdateEvent is not reloading trash on premanently removing
        //files, so need to fire ForceReloadTrashPageEvent
        Bus.instance.fire(ForceReloadTrashPageEvent());
      } catch (e, s) {
        _logger.info("failed to delete from trash", e, s);
        rethrow;
      }
    },
  );

  if (actionResult?.action == null ||
      actionResult!.action == ButtonAction.cancel) {
    return didDeletionStart ? true : false;
  } else if (actionResult.action == ButtonAction.error) {
    await showGenericErrorDialog(context: context);
    return false;
  } else {
    return true;
  }
}

Future<bool> emptyTrash(BuildContext context) async {
  final actionResult = await showChoiceActionSheet(
    context,
    title: S.of(context).emptyTrash,
    body: S.of(context).permDeleteWarning,
    firstButtonLabel: S.of(context).empty,
    isCritical: true,
    firstButtonOnTap: () async {
      try {
        await TrashSyncService.instance.emptyTrash();
      } catch (e, s) {
        _logger.info("failed empty trash", e, s);
        rethrow;
      }
    },
  );
  if (actionResult?.action == null ||
      actionResult!.action == ButtonAction.cancel) {
    return false;
  } else if (actionResult.action == ButtonAction.error) {
    await showGenericErrorDialog(context: context);
    return false;
  } else {
    return true;
  }
}

Future<bool> deleteLocalFiles(
  BuildContext context,
  List<String> localIDs,
) async {
  final List<String> deletedIDs = [];
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  for (String id in localIDs) {
    if (id.startsWith(oldSharedMediaIdentifier) ||
        id.startsWith(sharedMediaIdentifier)) {
      localSharedMediaIDs.add(id);
    } else {
      localAssetIDs.add(id);
    }
  }
  deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));

  final bool shouldDeleteInBatches =
      await isAndroidSDKVersionLowerThan(android11SDKINT);
  if (shouldDeleteInBatches) {
    deletedIDs.addAll(await deleteLocalFilesInBatches(context, localAssetIDs));
  } else {
    deletedIDs.addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
  }
  // In IOS, the library returns no error and fail to delete any file is
  // there's any shared file. As a stop-gap solution, we initiate deletion in
  // batches. Similar in Android, for large number of files, we have observed
  // that the library fails to delete any file. So, we initiate deletion in
  // batches.
  if (deletedIDs.isEmpty) {
    deletedIDs.addAll(
      await deleteLocalFilesInBatches(
        context,
        localAssetIDs,
        maximumBatchSize: 1000,
        minimumBatchSize: 10,
      ),
    );
    _logger
        .severe("iOS free-space fallback, deleted ${deletedIDs.length} files "
            "in batches}");
  }
  if (deletedIDs.isNotEmpty) {
    final deletedFiles = await FilesDB.instance.getLocalFiles(deletedIDs);
    await FilesDB.instance.deleteLocalFiles(deletedIDs);
    _logger.info(deletedFiles.length.toString() + " files deleted locally");
    Bus.instance.fire(
      LocalPhotosUpdatedEvent(deletedFiles, source: "deleteLocal"),
    );
    return true;
  } else {
    showToast(context, S.of(context).couldNotFreeUpSpace);
    return false;
  }
}

Future<List<String>> _deleteLocalFilesInOneShot(
  BuildContext context,
  List<String> localIDs,
) async {
  _logger.info('starting _deleteLocalFilesInOneShot for ${localIDs.length}');
  final List<String> deletedIDs = [];
  final dialog = createProgressDialog(
    context,
    "Deleting " + localIDs.length.toString() + " backed up files...",
  );
  await dialog.show();
  try {
    deletedIDs.addAll(await PhotoManager.editor.deleteWithIds(localIDs));
  } catch (e, s) {
    _logger.severe("Could not delete files ", e, s);
  }
  _logger.info(
    '_deleteLocalFilesInOneShot deleted ${deletedIDs.length} out '
    'of ${localIDs.length}',
  );
  await dialog.hide();
  return deletedIDs;
}

Future<List<String>> deleteLocalFilesInBatches(
  BuildContext context,
  List<String> localIDs, {
  int minimumParts = 10,
  int minimumBatchSize = 1,
  int maximumBatchSize = 100,
}) async {
  final dialogKey = GlobalKey<LinearProgressDialogState>();
  final dialog = LinearProgressDialog(
    "Deleting " + localIDs.length.toString() + " backed up files...",
    key: dialogKey,
  );
  showDialog(
    context: context,
    builder: (context) {
      return dialog;
    },
    barrierColor: Colors.black.withOpacity(0.85),
  );
  final batchSize = min(
    max(minimumBatchSize, (localIDs.length / minimumParts).round()),
    maximumBatchSize,
  );
  final List<String> deletedIDs = [];
  for (int index = 0; index < localIDs.length; index += batchSize) {
    if (dialogKey.currentState != null) {
      dialogKey.currentState!.setProgress(index / localIDs.length);
    }
    final ids = localIDs
        .getRange(index, min(localIDs.length, index + batchSize))
        .toList();
    _logger.info("Trying to delete " + ids.toString());
    try {
      deletedIDs.addAll(await PhotoManager.editor.deleteWithIds(ids));
      _logger.info("Deleted " + ids.toString());
    } catch (e, s) {
      _logger.severe("Could not delete batch " + ids.toString(), e, s);
      for (final id in ids) {
        try {
          deletedIDs.addAll(await PhotoManager.editor.deleteWithIds([id]));
          _logger.info("Deleted " + id);
        } catch (e, s) {
          _logger.severe("Could not delete file " + id, e, s);
        }
      }
    }
  }
  Navigator.of(dialogKey.currentContext!, rootNavigator: true).pop('dialog');
  return deletedIDs;
}

Future<bool> _localFileExist(File file) {
  if (file.isSharedMediaToAppSandbox) {
    final localFile = io.File(getSharedMediaFilePath(file));
    return localFile.exists();
  } else {
    return file.getAsset.then((asset) {
      if (asset == null) {
        return false;
      }
      return asset.exists;
    });
  }
}

Future<List<String>> _tryDeleteSharedMediaFiles(List<String> localIDs) {
  final List<String> actuallyDeletedIDs = [];
  try {
    return Future.forEach<String>(localIDs, (id) async {
      final String localPath = getSharedMediaPathFromLocalID(id);
      try {
        // verify the file exists as the OS may have already deleted it from cache
        if (io.File(localPath).existsSync()) {
          await io.File(localPath).delete();
        }
        actuallyDeletedIDs.add(id);
      } catch (e, s) {
        _logger.warning("Could not delete file " + id, e, s);
        // server log shouldn't contain localId
        _logger.severe("Could not delete file ", e, s);
      }
    }).then((ignore) {
      return actuallyDeletedIDs;
    });
  } catch (e, s) {
    _logger.severe("Unexpected error while deleting share media files", e, s);
    return Future.value(actuallyDeletedIDs);
  }
}

Future<bool> shouldProceedWithDeletion(BuildContext context) async {
  final actionResult = await showChoiceActionSheet(
    context,
    title: S.of(context).permanentlyDeleteFromDevice,
    body: S.of(context).someOfTheFilesYouAreTryingToDeleteAre,
    firstButtonLabel: S.of(context).delete,
    isCritical: true,
  );
  if (actionResult?.action == null) {
    return false;
  } else {
    return actionResult!.action == ButtonAction.first;
  }
}

Future<void> showDeleteSheet(
  BuildContext context,
  SelectedFiles selectedFiles,
) async {
  bool containsUploadedFile = false, containsLocalFile = false;
  for (final file in selectedFiles.files) {
    if (file.uploadedFileID != null) {
      debugPrint("${file.toString()} is uploaded");
      containsUploadedFile = true;
    }
    if (file.localID != null) {
      debugPrint("${file.toString()} has local");
      containsLocalFile = true;
    }
  }
  final List<ButtonWidget> buttons = [];
  final bool isBothLocalAndRemote = containsUploadedFile && containsLocalFile;
  final bool isLocalOnly = !containsUploadedFile;
  final bool isRemoteOnly = !containsLocalFile;
  final String? bodyHighlight = isBothLocalAndRemote
      ? S.of(context).theyWillBeDeletedFromAllAlbums
      : null;
  String body = "";
  if (isBothLocalAndRemote) {
    body = S.of(context).someItemsAreInBothEnteAndYourDevice;
  } else if (isRemoteOnly) {
    body = S.of(context).selectedItemsWillBeDeletedFromAllAlbumsAndMoved;
  } else if (isLocalOnly) {
    body = S.of(context).theseItemsWillBeDeletedFromYourDevice;
  } else {
    throw AssertionError("Unexpected state");
  }
  // Add option to delete from ente
  if (isBothLocalAndRemote || isRemoteOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote
            ? S.of(context).deleteFromEnte
            : S.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromRemoteOnly(
            context,
            selectedFiles.files.toList(),
          ).then(
            (value) {
              showShortToast(context, S.of(context).movedToTrash);
            },
            onError: (e, s) {
              showGenericErrorDialog(context: context);
            },
          );
        },
      ),
    );
  }
  // Add option to delete from local
  if (isBothLocalAndRemote || isLocalOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote
            ? S.of(context).deleteFromDevice
            : S.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.second,
        shouldSurfaceExecutionStates: false,
        isInAlert: true,
        onTap: () async {
          await deleteFilesOnDeviceOnly(context, selectedFiles.files.toList());
        },
      ),
    );
  }

  if (isBothLocalAndRemote) {
    buttons.add(
      ButtonWidget(
        labelText: S.of(context).deleteFromBoth,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.third,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromEverywhere(
            context,
            selectedFiles.files.toList(),
          );
        },
      ),
    );
  }
  buttons.add(
    ButtonWidget(
      labelText: S.of(context).cancel,
      buttonType: ButtonType.secondary,
      buttonSize: ButtonSize.large,
      shouldStickToDarkTheme: true,
      buttonAction: ButtonAction.fourth,
      isInAlert: true,
    ),
  );
  final actionResult = await showActionSheet(
    context: context,
    buttons: buttons,
    actionSheetType: ActionSheetType.defaultActionSheet,
    body: body,
    bodyHighlight: bodyHighlight,
  );
  if (actionResult?.action != null &&
      actionResult!.action == ButtonAction.error) {
    showGenericErrorDialog(context: context);
  } else {
    selectedFiles.clearAll();
  }
}
