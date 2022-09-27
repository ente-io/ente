// @dart=2.9

import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:math';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/trash_item_request.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/trash_sync_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/common/linear_progress_dialog.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
  BuildContext context,
  List<File> files,
) async {
  final dialog = createProgressDialog(context, "Deleting...");
  await dialog.show();
  _logger.info("Trying to deleteFilesFromEverywhere " + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  bool hasLocalOnlyFiles = false;
  for (final file in files) {
    if (file.localID != null) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else if (file.isSharedMediaToAppSandbox) {
        localSharedMediaIDs.add(file.localID);
      } else {
        localAssetIDs.add(file.localID);
      }
    }
    if (file.uploadedFileID == null) {
      hasLocalOnlyFiles = true;
    }
  }
  if (hasLocalOnlyFiles && Platform.isAndroid) {
    final shouldProceed = await shouldProceedWithDeletion(context);
    if (!shouldProceed) {
      await dialog.hide();
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
              .add(TrashRequest(file.uploadedFileID, file.collectionID));
          updatedCollectionIDs.add(file.collectionID);
        } else {
          await FilesDB.instance.deleteLocalFile(file);
        }
      }
    } else {
      updatedCollectionIDs.add(file.collectionID);
      deletedFiles.add(file);
      uploadedFilesToBeTrashed
          .add(TrashRequest(file.uploadedFileID, file.collectionID));
    }
  }
  if (uploadedFilesToBeTrashed.isNotEmpty) {
    try {
      final fileIDs =
          uploadedFilesToBeTrashed.map((item) => item.fileID).toList();
      await TrashSyncService.instance
          .trashFilesOnServer(uploadedFilesToBeTrashed);
      // await SyncService.instance
      //     .deleteFilesOnServer(fileIDs);
      await FilesDB.instance.deleteMultipleUploadedFiles(fileIDs);
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
      rethrow;
    }
    for (final collectionID in updatedCollectionIDs) {
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collectionID,
          deletedFiles
              .where((file) => file.collectionID == collectionID)
              .toList(),
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
      ),
    );
    if (hasLocalOnlyFiles && Platform.isAndroid) {
      showShortToast(context, "Files deleted");
    } else {
      showShortToast(context, "Moved to trash");
    }
  }
  await dialog.hide();
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
    showToast(context, "Selected files are not on ente");
    return;
  }
  final dialog = createProgressDialog(context, "Deleting...");
  await dialog.show();
  _logger.info(
    "Trying to deleteFilesFromRemoteOnly " +
        files.map((f) => f.uploadedFileID).toString(),
  );
  final updatedCollectionIDs = <int>{};
  final List<int> uploadedFileIDs = [];
  final List<TrashRequest> trashRequests = [];
  for (final file in files) {
    updatedCollectionIDs.add(file.collectionID);
    uploadedFileIDs.add(file.uploadedFileID);
    trashRequests.add(TrashRequest(file.uploadedFileID, file.collectionID));
  }
  try {
    await TrashSyncService.instance.trashFilesOnServer(trashRequests);
    await FilesDB.instance.deleteMultipleUploadedFiles(uploadedFileIDs);
  } catch (e, s) {
    _logger.severe("Failed to delete files from remote", e, s);
    await dialog.hide();
    showGenericErrorDialog(context);
    rethrow;
  }
  for (final collectionID in updatedCollectionIDs) {
    Bus.instance.fire(
      CollectionUpdatedEvent(
        collectionID,
        files.where((file) => file.collectionID == collectionID).toList(),
        type: EventType.deletedFromRemote,
      ),
    );
  }
  Bus.instance
      .fire(LocalPhotosUpdatedEvent(files, type: EventType.deletedFromRemote));
  SyncService.instance.sync();
  await dialog.hide();
  RemoteSyncService.instance.sync(silently: true);
}

Future<void> deleteFilesOnDeviceOnly(
  BuildContext context,
  List<File> files,
) async {
  final dialog = createProgressDialog(context, "Deleting...");
  await dialog.show();
  _logger.info("Trying to deleteFilesOnDeviceOnly" + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  bool hasLocalOnlyFiles = false;
  for (final file in files) {
    if (file.localID != null) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else if (file.isSharedMediaToAppSandbox) {
        localSharedMediaIDs.add(file.localID);
      } else {
        localAssetIDs.add(file.localID);
      }
    }
    if (file.uploadedFileID == null) {
      hasLocalOnlyFiles = true;
    }
  }
  if (hasLocalOnlyFiles && Platform.isAndroid) {
    final shouldProceed = await shouldProceedWithDeletion(context);
    if (!shouldProceed) {
      await dialog.hide();
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
      ),
    );
  }
  await dialog.hide();
}

Future<bool> deleteFromTrash(BuildContext context, List<File> files) async {
  final result = await showChoiceDialog(
    context,
    "Delete permanently?",
    "This action cannot be undone",
    firstAction: "Delete",
    actionType: ActionType.critical,
  );
  if (result != DialogUserChoice.firstChoice) {
    return false;
  }
  final dialog = createProgressDialog(context, "Permanently deleting...");
  await dialog.show();
  try {
    await TrashSyncService.instance.deleteFromTrash(files);
    showShortToast(context, "Successfully deleted");
    await dialog.hide();
    Bus.instance
        .fire(FilesUpdatedEvent(files, type: EventType.deletedFromEverywhere));
    return true;
  } catch (e, s) {
    _logger.info("failed to delete from trash", e, s);
    await dialog.hide();
    await showGenericErrorDialog(context);
    return false;
  }
}

Future<bool> emptyTrash(BuildContext context) async {
  final result = await showChoiceDialog(
    context,
    "Empty trash?",
    "These files will be permanently removed from your ente account",
    firstAction: "Empty",
    actionType: ActionType.critical,
  );
  if (result != DialogUserChoice.firstChoice) {
    return false;
  }
  final dialog = createProgressDialog(context, "Please wait...");
  await dialog.show();
  try {
    await TrashSyncService.instance.emptyTrash();
    showShortToast(context, "Trash emptied");
    await dialog.hide();
    return true;
  } catch (e, s) {
    _logger.info("failed empty trash", e, s);
    await dialog.hide();
    await showGenericErrorDialog(context);
    return false;
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

  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < android11SDKINT) {
      deletedIDs
          .addAll(await _deleteLocalFilesInBatches(context, localAssetIDs));
    } else {
      deletedIDs
          .addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
    }
  } else {
    deletedIDs.addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
  }
  if (deletedIDs.isNotEmpty) {
    final deletedFiles = await FilesDB.instance.getLocalFiles(deletedIDs);
    await FilesDB.instance.deleteLocalFiles(deletedIDs);
    _logger.info(deletedFiles.length.toString() + " files deleted locally");
    Bus.instance.fire(LocalPhotosUpdatedEvent(deletedFiles));
    return true;
  } else {
    showToast(context, "Could not free up space");
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

Future<List<String>> _deleteLocalFilesInBatches(
  BuildContext context,
  List<String> localIDs,
) async {
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
  const minimumParts = 10;
  const minimumBatchSize = 1;
  const maximumBatchSize = 100;
  final batchSize = min(
    max(minimumBatchSize, (localIDs.length / minimumParts).round()),
    maximumBatchSize,
  );
  final List<String> deletedIDs = [];
  for (int index = 0; index < localIDs.length; index += batchSize) {
    if (dialogKey.currentState != null) {
      dialogKey.currentState.setProgress(index / localIDs.length);
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
  Navigator.of(dialogKey.currentContext, rootNavigator: true).pop('dialog');
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
    return Future.forEach(localIDs, (id) async {
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
  final choice = await showChoiceDialog(
    context,
    "Are you sure?",
    "Some of the files you are trying to delete are only available on your device and cannot be recovered if deleted",
    firstAction: "Cancel",
    secondAction: "Delete",
    secondActionColor: Colors.red,
  );
  return choice == DialogUserChoice.secondChoice;
}
