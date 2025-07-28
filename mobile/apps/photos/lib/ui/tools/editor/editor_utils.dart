import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/db/local/table/upload_queue_table.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/sync/sync_service.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/utils/navigation_util.dart';

Future<void> saveAsset({
  required BuildContext context,
  required EnteFile originalFile,
  required DetailPageConfiguration detailPageConfig,
  required Future<AssetEntity?> Function() saveAction,
  required String fileExtension,
  required Logger logger,
  required VoidCallback onSaveFinished,
}) async {
  try {
    //Disabling notifications for assets changing to insert the file into
    //files db before triggering a sync.
    await PhotoManager.stopChangeNotify();
    final newAsset = await saveAction();
    if (newAsset == null) {
      throw Exception("Failed to save asset");
    }

    final newFile = await EnteFile.fromAsset(
      originalFile.deviceFolder ?? '',
      newAsset,
    );
    newFile.creationTime = originalFile.creationTime;
    newFile.collectionID = originalFile.collectionID;
    newFile.location = originalFile.location;
    await localDB.trackEdit(
      newAsset.id,
      originalFile.creationTime!,
      originalFile.modificationTime!,
      originalFile.location?.latitude,
      originalFile.location?.longitude,
    );
    if (originalFile.collectionID != null) {
      await localDB.insertOrUpdateQueue(
        {newAsset.id},
        originalFile.collectionID!,
        Configuration.instance.getUserID()!,
      );
    }

    Bus.instance.fire(LocalPhotosUpdatedEvent([newFile], source: "editSave"));
    showShortToast(context, S.of(context).editsSaved);
    logger.info("Original file " + originalFile.toString());
    logger.info("Saved edits to file " + newFile.toString());
    final files = detailPageConfig.files;
    // the index could be -1 if the files fetched doesn't contain the newly
    // edited files
    int selectionIndex = files.indexWhere((file) =>
        originalFile.localID != null && file.localID == newFile.localID);
    if (selectionIndex == -1) {
      files.add(newFile);
      selectionIndex = files.length - 1;
    }
    onSaveFinished();
    replacePage(
      context,
      DetailPage(
        detailPageConfig.copyWith(
          files: files,
          selectedIndex: min(selectionIndex, files.length - 1),
        ),
      ),
    );
  } catch (e, s) {
    onSaveFinished();
    showToast(context, S.of(context).oopsCouldNotSaveEdits);
    logger.severe(e, s);
  } finally {
    await PhotoManager.startChangeNotify();
    Future.delayed(
      const Duration(seconds: 2),
      () => SyncService.instance.sync().ignore(),
    );
  }
}
