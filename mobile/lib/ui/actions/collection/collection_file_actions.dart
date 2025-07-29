import "dart:async";

import 'package:flutter/cupertino.dart';
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/services/favorites_service.dart';
import "package:photos/services/hidden_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/sync/remote_sync_service.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/file_uploader.dart";
import "package:photos/utils/share_util.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";

extension CollectionFileActions on CollectionActions {
  Future<void> showRemoveFromCollectionSheetV2(
    BuildContext bContext,
    Collection collection,
    SelectedFiles selectedFiles,
    bool removingOthersFile, {
    bool isHidden = false,
  }) async {
    final actionResult = await showActionSheet(
      context: bContext,
      buttons: [
        ButtonWidget(
          labelText: S.of(bContext).remove,
          buttonType:
              removingOthersFile ? ButtonType.critical : ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          isInAlert: true,
          onTap: () async {
            try {
              await moveFilesFromCurrentCollection(
                bContext,
                collection,
                selectedFiles.files,
                isHidden: isHidden,
              );
            } catch (e) {
              logger.severe("Failed to move files", e);
              rethrow;
            }
          },
        ),
        ButtonWidget(
          labelText: S.of(bContext).cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      title: removingOthersFile ? S.of(bContext).removeFromAlbumTitle : null,
      body: removingOthersFile
          ? S.of(bContext).removeShareItemsWarning
          : S.of(bContext).itemsWillBeRemovedFromAlbum,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    if (actionResult?.action != null &&
        actionResult!.action == ButtonAction.error) {
      await showGenericErrorDialog(
        context: bContext,
        error: actionResult.exception,
      );
    } else {
      selectedFiles.clearAll();
    }
  }

  Future<bool> addToCollection(
    BuildContext context,
    int collectionID,
    bool showProgressDialog, {
    List<EnteFile>? selectedFiles,
    List<SharedMediaFile>? sharedFiles,
    List<AssetEntity>? picketAssets,
  }) async {
    logger.info('[UPLOAD_SYNC] addToCollection called with collectionID: $collectionID, showProgressDialog: $showProgressDialog');
    logger.info('[UPLOAD_SYNC] selectedFiles: ${selectedFiles?.length ?? 0}, sharedFiles: ${sharedFiles?.length ?? 0}, picketAssets: ${picketAssets?.length ?? 0}');
    
    ProgressDialog? dialog = showProgressDialog
        ? createProgressDialog(
            context,
            S.of(context).uploadingFilesToAlbum,
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    try {
      final List<EnteFile> files = [];
      final List<EnteFile> filesPendingUpload = [];
      final int currentUserID = Configuration.instance.getUserID()!;
      logger.info('[UPLOAD_SYNC] Current user ID: $currentUserID');
      
      if (sharedFiles != null) {
        logger.info('[UPLOAD_SYNC] Processing ${sharedFiles.length} shared files');
        filesPendingUpload.addAll(
          await convertIncomingSharedMediaToFile(
            sharedFiles,
            collectionID,
          ),
        );
      } else if (picketAssets != null) {
        logger.info('[UPLOAD_SYNC] Processing ${picketAssets.length} picked assets');
        filesPendingUpload.addAll(
          await convertPicketAssets(
            picketAssets,
            collectionID,
          ),
        );
      } else if (selectedFiles != null) {
        logger.info('[UPLOAD_SYNC] Processing ${selectedFiles.length} selected files');
        for (final file in selectedFiles!) {
          EnteFile? currentFile;
          if (file.uploadedFileID != null) {
            logger.info('[UPLOAD_SYNC] File already uploaded: ${file.tag}');
            currentFile = file.copyWith();
          } else if (file.generatedID != null) {
            logger.info('[UPLOAD_SYNC] File not uploaded, refreshing from DB: ${file.tag}');
            // when file is not uploaded, refresh the state from the db to
            // ensure we have latest upload status for given file before
            // queueing it up as pending upload
            currentFile = await (FilesDB.instance.getFile(file.generatedID!));
          } else if (file.generatedID == null) {
            logger.severe('[UPLOAD_SYNC] generated id should not be null for file: ${file.tag}');
          }
          if (currentFile == null) {
            logger.severe('[UPLOAD_SYNC] Failed to find fileBy genID for file: ${file.tag}');
            continue;
          }
          if (currentFile.uploadedFileID == null) {
            logger.info('[UPLOAD_SYNC] File needs upload: ${currentFile.tag}');
            currentFile.collectionID = collectionID;
            filesPendingUpload.add(currentFile);
          } else {
            logger.info('[UPLOAD_SYNC] File already uploaded, adding to collection: ${currentFile.tag}');
            files.add(currentFile);
          }
        }
      }
      
      logger.info('[UPLOAD_SYNC] Files to add to collection: ${files.length}, files pending upload: ${filesPendingUpload.length}');
      
      if (filesPendingUpload.isNotEmpty) {
        // Newly created collection might not be cached
        final Collection? c =
            CollectionsService.instance.getCollectionByID(collectionID);
        if (c != null && c.owner.id != currentUserID) {
          logger.info('[UPLOAD_SYNC] Collection owned by different user, uploading to uncategorized first');
          if (!showProgressDialog) {
            dialog = createProgressDialog(
              context,
              S.of(context).uploadingFilesToAlbum,
              isDismissible: true,
            );
            await dialog.show();
          }
          final Collection uncat =
              await CollectionsService.instance.getUncategorizedCollection();
          for (EnteFile unuploadedFile in filesPendingUpload) {
            logger.info('[UPLOAD_SYNC] Force uploading file to uncategorized: ${unuploadedFile.tag}');
            final uploadedFile = await FileUploader.instance.forceUpload(
              unuploadedFile,
              uncat.id,
            );
            logger.info('[UPLOAD_SYNC] Force upload completed: ${uploadedFile.tag}');
            files.add(uploadedFile);
          }
        } else {
          logger.info('[UPLOAD_SYNC] Adding ${filesPendingUpload.length} files to upload queue');
          for (final file in filesPendingUpload) {
            file.collectionID = collectionID;
          }
          // filesPendingUpload might be getting ignored during auto-upload
          // because the user deleted these files from ente in the past.
          await IgnoredFilesService.instance
              .removeIgnoredMappings(filesPendingUpload);
          await FilesDB.instance.insertMultiple(filesPendingUpload);
          Bus.instance.fire(
            CollectionUpdatedEvent(
              collectionID,
              filesPendingUpload,
              "pendingFilesAdd",
            ),
          );
        }
      }
      if (files.isNotEmpty) {
        logger.info('[UPLOAD_SYNC] Adding ${files.length} already uploaded files to collection');
        await CollectionsService.instance
            .addOrCopyToCollection(collectionID, files);
      }
      logger.info('[UPLOAD_SYNC] Triggering sync');
      unawaited(RemoteSyncService.instance.sync(silently: true));
      await dialog?.hide();
      logger.info('[UPLOAD_SYNC] addToCollection completed successfully');
      return true;
    } catch (e, s) {
      logger.severe('[UPLOAD_SYNC] Failed to add to album', e, s);
      await dialog?.hide();
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }

  Future<bool> updateFavorites(
    BuildContext context,
    List<EnteFile> files,
    bool markAsFavorite,
  ) async {
    final ProgressDialog dialog = createProgressDialog(
      context,
      markAsFavorite
          ? S.of(context).addingToFavorites
          : S.of(context).removingFromFavorites,
    );
    await dialog.show();

    try {
      await FavoritesService.instance
          .updateFavorites(context, files, markAsFavorite);
      return true;
    } catch (e, s) {
      logger.severe(e, s);
      showShortToast(
        context,
        markAsFavorite
            ? S.of(context).sorryCouldNotAddToFavorites
            : S.of(context).sorryCouldNotRemoveFromFavorites,
      );
    } finally {
      await dialog.hide();
    }
    return false;
  }
}
