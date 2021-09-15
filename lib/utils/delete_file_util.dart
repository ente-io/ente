import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:math';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/linear_progress_dialog.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

import 'file_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  _logger.info("Trying to delete files " + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  for (final file in files) {
    if (file.localID != null)  {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else if(file.isSharedMediaToAppSandbox()) {
        localSharedMediaIDs.add(file.localID);
      } else {
        localAssetIDs.add(file.localID);
      }
    }
  }
  Set<String> deletedIDs = <String>{};
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localAssetIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));
  final updatedCollectionIDs = <int>{};
  final List<int> uploadedFileIDsToBeDeleted = [];
  final List<File> deletedFiles = [];
  for (final file in files) {
    if (file.localID != null) {
      // Remove only those files that have already been removed from disk
      if (deletedIDs.contains(file.localID) ||
          alreadyDeletedIDs.contains(file.localID)) {
        deletedFiles.add(file);
        if (file.uploadedFileID != null) {
          uploadedFileIDsToBeDeleted.add(file.uploadedFileID);
          updatedCollectionIDs.add(file.collectionID);
        } else {
          await FilesDB.instance.deleteLocalFile(file);
        }
      }
    } else {
      updatedCollectionIDs.add(file.collectionID);
      deletedFiles.add(file);
      uploadedFileIDsToBeDeleted.add(file.uploadedFileID);
    }
  }
  if (uploadedFileIDsToBeDeleted.isNotEmpty) {
    try {
      await SyncService.instance
          .deleteFilesOnServer(uploadedFileIDsToBeDeleted);
      await FilesDB.instance
          .deleteMultipleUploadedFiles(uploadedFileIDsToBeDeleted);
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
      rethrow;
    }
    for (final collectionID in updatedCollectionIDs) {
      Bus.instance.fire(CollectionUpdatedEvent(
        collectionID,
        deletedFiles
            .where((file) => file.collectionID == collectionID)
            .toList(),
        type: EventType.deleted,
      ));
    }
  }
  if (deletedFiles.isNotEmpty) {
    Bus.instance
        .fire(LocalPhotosUpdatedEvent(deletedFiles, type: EventType.deleted));
  }
  await dialog.hide();
  showToast("deleted from everywhere");
  if (uploadedFileIDsToBeDeleted.isNotEmpty) {
    RemoteSyncService.instance.sync(silently: true);
  }
}

Future<void> deleteFilesOnDeviceOnly(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  _logger.info("Trying to delete files " + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  for (final file in files) {
    if (file.localID != null) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else if(file.isSharedMediaToAppSandbox()) {
        localSharedMediaIDs.add(file.localID);
      } else {
        localAssetIDs.add(file.localID);
      }
    }
  }
  Set<String> deletedIDs = <String>{};
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localAssetIDs)).toSet();
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
    Bus.instance
        .fire(LocalPhotosUpdatedEvent(deletedFiles, type: EventType.deleted));
  }
  await dialog.hide();
}

Future<bool> deleteLocalFiles(
    BuildContext context, List<String> localIDs) async {
  final List<String> deletedIDs = [];
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  for (String id in localIDs) {
    if (id.startsWith(kSharedMediaIdentifier)) {
      localSharedMediaIDs.add(id);
    } else {
      localAssetIDs.add(id);
    }
  }
  deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));

  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < kAndroid11SDKINT) {
      deletedIDs.addAll(await _deleteLocalFilesInBatches(context, localAssetIDs));
    } else {
      deletedIDs.addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
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
    showToast("could not free up space");
    return false;
  }
}

Future<List<String>> _deleteLocalFilesInOneShot(
    BuildContext context, List<String> localIDs) async {
  final List<String> deletedIDs = [];
  final dialog = createProgressDialog(context,
      "deleting " + localIDs.length.toString() + " backed up files...");
  await dialog.show();
  try {
    deletedIDs.addAll(await PhotoManager.editor.deleteWithIds(localIDs));
  } catch (e, s) {
    _logger.severe("Could not delete files ", e, s);
  }
  await dialog.hide();
  return deletedIDs;
}

Future<List<String>> _deleteLocalFilesInBatches(
    BuildContext context, List<String> localIDs) async {
  final dialogKey = GlobalKey<LinearProgressDialogState>();
  final dialog = LinearProgressDialog(
    "deleting " + localIDs.length.toString() + " backed up files...",
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
      maximumBatchSize);
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
  if (file.isSharedMediaToAppSandbox()) {
    var localFile = io.File(getSharedMediaFilePath(file));
    return localFile.exists();
  } else {
    return file.getAsset().then((asset) {
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
      String localPath = Configuration.instance.getSharedMediaCacheDirectory() +
          "/" +
          id.replaceAll(kSharedMediaIdentifier, '');
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
