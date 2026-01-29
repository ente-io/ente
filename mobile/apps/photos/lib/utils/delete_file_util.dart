import 'dart:async';
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
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/api/collection/trash_item_request.dart';
import "package:photos/models/backup_status.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/files_split.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/files_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/services/sync/sync_service.dart';
import 'package:photos/ui/common/linear_progress_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/utils/device_info.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';

final _logger = Logger("DeleteFileUtil");

Future<void> deleteFilesFromEverywhere(
  BuildContext context,
  List<EnteFile> files,
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
  final List<EnteFile> deletedFiles = [];
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
      await trashSyncService.trashFilesOnServer(uploadedFilesToBeTrashed);
      await FilesDB.instance.deleteMultipleUploadedFiles(fileIDs);
    } catch (e) {
      _logger.severe(e);
      await showGenericErrorDialog(context: context, error: e);
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
      showShortToast(context, AppLocalizations.of(context).filesDeleted);
    } else {
      showShortToast(context, AppLocalizations.of(context).movedToTrash);
    }
  }
  if (uploadedFilesToBeTrashed.isNotEmpty) {
    // ignore: unawaited_futures
    RemoteSyncService.instance.sync(silently: true);
  }
}

Future<void> deleteFilesFromRemoteOnly(
  BuildContext context,
  List<EnteFile> files,
) async {
  files.removeWhere((element) => element.uploadedFileID == null);
  if (files.isEmpty) {
    showToast(context, AppLocalizations.of(context).selectedFilesAreNotOnEnte);
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
    await trashSyncService.trashFilesOnServer(trashRequests);
    await FilesDB.instance.deleteMultipleUploadedFiles(uploadedFileIDs);
  } catch (e, s) {
    _logger.severe("Failed to delete files from remote", e, s);
    await showGenericErrorDialog(context: context, error: e);
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
  // ignore: unawaited_futures
  SyncService.instance.sync();
  // ignore: unawaited_futures
  RemoteSyncService.instance.sync(silently: true);
}

Future<void> deleteFilesOnDeviceOnly(
  BuildContext context,
  List<EnteFile> files,
) async {
  _logger.info("Trying to deleteFilesOnDeviceOnly" + files.toString());
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files
  final List<String?> localOnlyIDs = [];
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
      localOnlyIDs.add(file.localID);
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
  final List<EnteFile> deletedFiles = [];
  for (final file in files) {
    // Remove only those files that have been removed from disk
    if (deletedIDs.contains(file.localID) ||
        alreadyDeletedIDs.contains(file.localID)) {
      deletedFiles.add(file);
      if (hasLocalOnlyFiles && localOnlyIDs.contains(file.localID)) {
        await FilesDB.instance.deleteLocalFile(file);
      } else {
        file.localID = null;
        await FilesDB.instance.update(file);
      }
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

Future<bool> deleteFromTrash(BuildContext context, List<EnteFile> files) async {
  bool didDeletionStart = false;
  final actionResult = await showChoiceActionSheet(
    context,
    title: AppLocalizations.of(context).permanentlyDelete,
    body: AppLocalizations.of(context).thisActionCannotBeUndone,
    firstButtonLabel: AppLocalizations.of(context).delete,
    isCritical: true,
    firstButtonOnTap: () async {
      try {
        didDeletionStart = true;
        await trashSyncService.deleteFromTrash(files);
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
    await showGenericErrorDialog(
      context: context,
      error: actionResult.exception,
    );
    return false;
  } else {
    return true;
  }
}

Future<bool> emptyTrash(BuildContext context) async {
  final actionResult = await showChoiceActionSheet(
    context,
    title: AppLocalizations.of(context).emptyTrash,
    body: AppLocalizations.of(context).permDeleteWarning,
    firstButtonLabel: AppLocalizations.of(context).empty,
    isCritical: true,
    firstButtonOnTap: () async {
      try {
        await trashSyncService.emptyTrash();
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
    await showGenericErrorDialog(
      context: context,
      error: actionResult.exception,
    );
    return false;
  } else {
    return true;
  }
}

Future<bool> deleteLocalFiles(
  BuildContext context,
  List<String> localIDs,
) async {
  _logger.info("Trying to delete local files ");
  final List<String> deletedIDs = [];
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];

  const largeCountThreshold = 20000;
  final tooManyAssets = localIDs.length > largeCountThreshold;
  try {
    for (String id in localIDs) {
      if (id.startsWith(sharedMediaIdentifier)) {
        localSharedMediaIDs.add(id);
      } else {
        localAssetIDs.add(id);
      }
    }
    deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));

    final bool shouldDeleteInBatches =
        await isAndroidSDKVersionLowerThan(android11SDKINT) || tooManyAssets;
    if (shouldDeleteInBatches) {
      if (tooManyAssets) {
        _logger.info(
          "Too many assets (${localIDs.length}) to delete in one shot, deleting in batches",
        );
        await _recursivelyReduceBatchSizeAndRetryDeletion(
          batchSize: largeCountThreshold,
          context: context,
          localIDs: localIDs,
          deletedIDs: deletedIDs,
        );
      } else {
        _logger.info("Deleting in batches");
        deletedIDs
            .addAll(await deleteLocalFilesInBatches(context, localAssetIDs));
      }
    } else {
      _logger.info("Deleting in one shot");
      deletedIDs
          .addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
    }
    // In IOS, the library returns no error and fail to delete any file is
    // there's any shared file. As a stop-gap solution, we initiate deletion in
    // batches. Similar in Android, for large number of files, we have observed
    // that the library fails to delete any file. So, we initiate deletion in
    // batches.
    if (deletedIDs.isEmpty && Platform.isIOS) {
      deletedIDs.addAll(
        await _iosDeleteLocalFilesInBatchesFallback(context, localAssetIDs),
      );
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
      //On android 10, even if files were deleted, deletedIDs is empty.
      //This is a workaround so that users are not shown an error message on
      //android 10
      if (!await isAndroidSDKVersionLowerThan(android11SDKINT)) {
        return false;
      }
      return true;
    }
  } catch (e, s) {
    _logger.severe("Could not delete local files", e, s);
    return false;
  }
}

Future<bool> deleteLocalFilesAfterRemovingAlreadyDeletedIDs(
  BuildContext context,
  List<String> localIDs,
) async {
  _logger.info(
    "Trying to delete local files after removing already deleted IDs",
  );

  final List<String> deletedIDs = [];
  final List<String> localAssetIDs = [];
  final List<String> localSharedMediaIDs = [];
  final List<String> alreadyDeletedIDs = []; // to ignore already deleted files

  final dialog = createProgressDialog(context, "Loading...");
  await dialog.show();
  try {
    final files =
        await FilesDB.instance.getLocalFiles(localIDs, dedupeByLocalID: true);
    for (final file in files) {
      if (!(await _localFileExist(file))) {
        _logger.warning("Already deleted " + file.toString());
        alreadyDeletedIDs.add(file.localID!);
      } else if (file.localID!.startsWith(sharedMediaIdentifier)) {
        localSharedMediaIDs.add(file.localID!);
      } else {
        localAssetIDs.add(file.localID!);
      }
    }
    deletedIDs.addAll(alreadyDeletedIDs);
    deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));

    await dialog.hide();

    final bool shouldDeleteInBatches =
        await isAndroidSDKVersionLowerThan(android11SDKINT);
    if (shouldDeleteInBatches) {
      _logger.info("Deleting in batches");
      deletedIDs
          .addAll(await deleteLocalFilesInBatches(context, localAssetIDs));
    } else {
      _logger.info("Deleting in one shot");
      deletedIDs
          .addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
    }
    // In IOS, the library returns no error and fail to delete any file is
    // there's any shared file. As a stop-gap solution, we initiate deletion in
    // batches. Similar in Android, for large number of files, we have observed
    // that the library fails to delete any file. So, we initiate deletion in
    // batches.
    if (deletedIDs.isEmpty && Platform.isIOS) {
      deletedIDs.addAll(
        await _iosDeleteLocalFilesInBatchesFallback(context, localAssetIDs),
      );
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
      //On android 10, even if files were deleted, deletedIDs is empty.
      //This is a workaround so that users are not shown an error message on
      //android 10
      if (!await isAndroidSDKVersionLowerThan(android11SDKINT)) {
        return false;
      }
      return true;
    }
  } catch (e, s) {
    _logger.severe("Could not delete local files", e, s);
    await dialog.hide();
    return false;
  }
}

/// Only to be used on Android
Future<bool> retryFreeUpSpaceAfterRemovingAssetsNonExistingInDisk(
  BuildContext context,
) async {
  _logger.info(
    "Retrying free up space after removing assets non-existing in disk",
  );

  final dialog =
      createProgressDialog(context, context.l10n.pleaseWaitThisWillTakeAWhile);
  await dialog.show();
  try {
    final stopwatch = Stopwatch()..start();
    final res = await PhotoManager.editor.android.removeAllNoExistsAsset();
    if (res == false) {
      _logger.warning("Failed to remove non-existing assets");
    }
    _logger.info(
      "removeAllNoExistsAsset took: ${stopwatch.elapsedMilliseconds}ms",
    );
    await LocalSyncService.instance.sync();

    late final BackupStatus status;
    final List<String> deletedIDs = [];
    final List<String> localAssetIDs = [];
    final List<String> localSharedMediaIDs = [];
    status = await FilesService.instance.getBackupStatus();

    for (String localID in status.localIDs) {
      if (localID.startsWith(sharedMediaIdentifier)) {
        localSharedMediaIDs.add(localID);
      } else {
        localAssetIDs.add(localID);
      }
    }
    deletedIDs.addAll(await _tryDeleteSharedMediaFiles(localSharedMediaIDs));

    await dialog.hide();

    final bool shouldDeleteInBatches =
        await isAndroidSDKVersionLowerThan(android11SDKINT);
    if (shouldDeleteInBatches) {
      _logger.info("Deleting in batches");
      deletedIDs
          .addAll(await deleteLocalFilesInBatches(context, localAssetIDs));
    } else {
      _logger.info("Deleting in one shot");
      deletedIDs
          .addAll(await _deleteLocalFilesInOneShot(context, localAssetIDs));
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
      //On android 10, even if files were deleted, deletedIDs is empty.
      //This is a workaround so that users are not shown an error message on
      //android 10
      if (!await isAndroidSDKVersionLowerThan(android11SDKINT)) {
        return false;
      }
      return true;
    }
  } catch (e) {
    await dialog.hide();
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
  // ignore: unawaited_futures
  showDialog(
    useRootNavigator: false,
    context: context,
    builder: (context) {
      return dialog;
    },
    barrierColor: Colors.black.withValues(alpha: 0.85),
  );
  final batchSize = min(
    max(minimumBatchSize, (localIDs.length / minimumParts).round()),
    maximumBatchSize,
  );
  _logger.info("Batch size: $batchSize");
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
  Navigator.of(dialogKey.currentContext!).pop('dialog');
  return deletedIDs;
}

Future<void> _recursivelyReduceBatchSizeAndRetryDeletion({
  required int batchSize,
  required BuildContext context,
  required List<String> localIDs,
  required List<String> deletedIDs,
  int minimumBatchSizeThresholdToStopRetry = 2000,
}) async {
  if (batchSize < minimumBatchSizeThresholdToStopRetry) {
    _logger.warning(
      "Batch size is too small ($batchSize), stopping further retries.",
    );
    throw Exception(
      "Batch size is too small ($batchSize), stopping further retries.",
    );
  }
  try {
    deletedIDs.addAll(
      await deleteLocalFilesInBatches(
        context,
        localIDs,
        minimumBatchSize: 1,
        maximumBatchSize: batchSize,
        minimumParts: 1,
      ),
    );
  } catch (e) {
    _logger.warning(
      "Failed to delete local files in batches of $batchSize. Reducing batch size and retrying.",
      e,
    );
    await _recursivelyReduceBatchSizeAndRetryDeletion(
      batchSize: (batchSize / 2).floor(),
      context: context,
      localIDs: localIDs,
      deletedIDs: deletedIDs,
    );
  }
}

Future<bool> _localFileExist(EnteFile file) {
  if (file.isSharedMediaToAppSandbox) {
    final localFile = File(getSharedMediaFilePath(file));
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
        if (File(localPath).existsSync()) {
          await File(localPath).delete();
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
    title: AppLocalizations.of(context).permanentlyDeleteFromDevice,
    body: AppLocalizations.of(context).someOfTheFilesYouAreTryingToDeleteAre,
    firstButtonLabel: AppLocalizations.of(context).delete,
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
  FilesSplit filesSplit,
) async {
  if (selectedFiles.files.length != filesSplit.count) {
    throw AssertionError("Unexpected state, #{selectedFiles.files.length} != "
        "${filesSplit.count}");
  }
  final List<EnteFile> deletableFiles =
      filesSplit.ownedByCurrentUser + filesSplit.pendingUploads;
  if (deletableFiles.isEmpty && filesSplit.ownedByOtherUsers.isNotEmpty) {
    showShortToast(
      context,
      AppLocalizations.of(context).cannotDeleteSharedFiles,
    );
    return;
  }
  final containsUploadedFile = deletableFiles.any((f) => f.isUploaded);
  final containsLocalFile = deletableFiles.any((f) => f.localID != null);

  final List<ButtonWidget> buttons = [];
  final bool isBothLocalAndRemote = containsUploadedFile && containsLocalFile;
  final bool isLocalOnly = !containsUploadedFile;
  final bool isRemoteOnly = !containsLocalFile;
  final String? bodyHighlight = isBothLocalAndRemote
      ? AppLocalizations.of(context).theyWillBeDeletedFromAllAlbums
      : null;
  String body = "";
  if (isBothLocalAndRemote) {
    body = AppLocalizations.of(context).someItemsAreInBothEnteAndYourDevice;
  } else if (isRemoteOnly) {
    body = AppLocalizations.of(context)
        .selectedItemsWillBeDeletedFromAllAlbumsAndMoved;
  } else if (isLocalOnly) {
    body = AppLocalizations.of(context).theseItemsWillBeDeletedFromYourDevice;
  } else {
    throw AssertionError("Unexpected state");
  }
  // Add option to delete from ente
  if (isBothLocalAndRemote || isRemoteOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote
            ? AppLocalizations.of(context).deleteFromEnte
            : AppLocalizations.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromRemoteOnly(
            context,
            deletableFiles,
          ).then(
            (value) {
              showShortToast(
                context,
                AppLocalizations.of(context).movedToTrash,
              );
            },
            onError: (e, s) {
              showGenericErrorDialog(context: context, error: e);
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
            ? AppLocalizations.of(context).deleteFromDevice
            : AppLocalizations.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.second,
        shouldSurfaceExecutionStates: false,
        isInAlert: true,
        onTap: () async {
          await deleteFilesOnDeviceOnly(context, deletableFiles);
        },
      ),
    );
  }

  if (isBothLocalAndRemote) {
    buttons.add(
      ButtonWidget(
        labelText: AppLocalizations.of(context).deleteFromBoth,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.third,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromEverywhere(
            context,
            deletableFiles,
          );
        },
      ),
    );
  }
  buttons.add(
    ButtonWidget(
      labelText: AppLocalizations.of(context).cancel,
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
    await showGenericErrorDialog(
      context: context,
      error: actionResult.exception,
    );
  } else {
    selectedFiles.clearAll();
  }
}

Future<List<String>> _iosDeleteLocalFilesInBatchesFallback(
  BuildContext context,
  List<String> localAssetIDs,
) async {
  final List<String> deletedIDs = [];

  _logger.info(
    "Trying to delete local files in batches",
  );
  deletedIDs.addAll(
    await _deleteLocalFilesInBatchesRecursively(localAssetIDs, context),
  );
  if (deletedIDs.isEmpty) {
    _logger.warning(
      "Failed to delete local files in recursively batches",
    );
  }

  _logger.severe(
      "iOS free-space fallback, deleted ${deletedIDs.length} files with distinct localIDs"
      "in batches}");

  return deletedIDs;
}

Future<List<String>> _deleteLocalFilesInBatchesRecursively(
  List<String> localAssetIDs,
  BuildContext context,
) async {
  if (localAssetIDs.isEmpty) return [];

  final deletedIDs = await _deleteLocalFiles(localAssetIDs, context);
  if (deletedIDs.isNotEmpty) {
    return deletedIDs;
  }

  if (localAssetIDs.length == 1) {
    _logger.warning("Failed to delete file " + localAssetIDs.first);
    return [];
  }

  final midIndex = localAssetIDs.length ~/ 2;
  final left = localAssetIDs.sublist(0, midIndex);
  final right = localAssetIDs.sublist(midIndex);

  final leftDeleted =
      await _deleteLocalFilesInBatchesRecursively(left, context);
  final rightDeleted =
      await _deleteLocalFilesInBatchesRecursively(right, context);

  return [...leftDeleted, ...rightDeleted];
}

Future<List<String>> _deleteLocalFiles(
  List<String> localIDs,
  BuildContext context,
) async {
  _logger.info(
    "Trying to delete batch of size " +
        localIDs.length.toString() +
        "  :  " +
        localIDs.toString(),
  );

  final dialog = createProgressDialog(
    context,
    "Deleting " + localIDs.length.toString() + " backed up files...",
  );
  await dialog.show();

  final List<String> deletedIDs = [];
  try {
    deletedIDs.addAll(await PhotoManager.editor.deleteWithIds(localIDs));
    _logger.info("Deleted " + localIDs.toString());
  } catch (e, s) {
    _logger.severe("Could not delete batch " + localIDs.toString(), e, s);
    await showGenericErrorDialog(context: context, error: e);
  }

  await dialog.hide();

  return deletedIDs;
}
