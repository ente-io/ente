import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  final localIDs = List<String>();
  for (final file in files) {
    if (file.localID != null) {
      localIDs.add(file.localID);
    }
  }
  var deletedIDs;
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
      // Remove only those files that have been removed from disk
      if (deletedIDs.contains(file.localID)) {
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
    SyncService.instance.syncWithRemote(silently: true);
  }
}

Future<void> deleteFilesOnDeviceOnly(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  final localIDs = List<String>();
  for (final file in files) {
    if (file.localID != null) {
      localIDs.add(file.localID);
    }
  }
  var deletedIDs;
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  final List<File> deletedFiles = [];
  for (final file in files) {
    // Remove only those files that have been removed from disk
    if (deletedIDs.contains(file.localID)) {
      deletedFiles.add(file);
      file.localID = null;
      FilesDB.instance.update(file);
    }
  }
  if (deletedFiles.isNotEmpty) {
    Bus.instance
        .fire(LocalPhotosUpdatedEvent(deletedFiles, type: EventType.deleted));
  }
  await dialog.hide();
}
