import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  _logger.info("Trying to delete files " + files.toString());
  final List<String> localIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  for (final file in files) {
    if (file.localID != null) {
      final asset = await file.getAsset();
      if (asset == null || !(await asset.exists)) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else {
        localIDs.add(file.localID);
      }
    }
  }
  Set<String> deletedIDs = Set<String>();
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  final updatedCollectionIDs = Set<int>();
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
          await FilesDB.instance.deleteLocalFile(file.localID);
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
      throw e;
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
  final List<String> localIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  for (final file in files) {
    if (file.localID != null) {
      final asset = await file.getAsset();
      if (asset == null || !(await asset.exists)) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID);
      } else {
        localIDs.add(file.localID);
      }
    }
  }
  Set<String> deletedIDs = Set<String>();
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
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

Future<void> deleteLocalFiles(List<String> localIDs) async {
  List<String> deletedIDs = [];
  if (Platform.isAndroid) {
    const batchSize = 100;
    for (int index = 0; index < localIDs.length; index += batchSize) {
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
  } else {
    try {
      deletedIDs.addAll(await PhotoManager.editor.deleteWithIds(localIDs));
    } catch (e, s) {
      _logger.severe("Could not delete files ", e, s);
    }
  }
  if (deletedIDs.isNotEmpty) {
    final deletedFiles = await FilesDB.instance.getLocalFiles(deletedIDs);
    await FilesDB.instance.deleteLocalFiles(deletedIDs);
    _logger.info(deletedFiles.length.toString() + " files deleted locally");
    Bus.instance
        .fire(LocalPhotosUpdatedEvent(deletedFiles, type: EventType.deleted));
  }
}
