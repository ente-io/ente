import "dart:async";

import 'package:flutter/cupertino.dart';
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/local/table/shared_assets.dart";
import "package:photos/db/local/table/upload_queue_table.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
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

  Future<bool> addToMultipleCollections(
    BuildContext context,
    List<Collection> collections,
    bool showProgressDialog, {
    List<EnteFile>? selectedFiles,
  }) async {
    final ProgressDialog? dialog = showProgressDialog
        ? createProgressDialog(
            context,
            S.of(context).uploadingFilesToAlbum,
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    final int currentUserID = Configuration.instance.getUserID()!;
    for (final collection in collections) {
      try {
        final List<EnteFile> uploadedFiles = [];
        final Set<String> pendingUploads = {};
        final List<EnteFile> filesPendingUpload = [];
        for (final file in selectedFiles!) {
          if (file.rAsset != null) {
            uploadedFiles.add(file.copyWith());
          } else {
            pendingUploads.add(file.lAsset!.id);
            filesPendingUpload.add(file.copyWith());
          }
        }
        if (pendingUploads.isNotEmpty) {
          await IgnoredFilesService.instance
              .removeIgnoredMappings(filesPendingUpload);
          await localDB.insertOrUpdateQueue(
            pendingUploads,
            collection.id,
            currentUserID,
            manual: true,
          );
          Bus.instance.fire(
            CollectionUpdatedEvent(
              collection.id,
              filesPendingUpload,
              "queuedForUpload",
            ),
          );
        }
        if (uploadedFiles.isNotEmpty) {
          await CollectionsService.instance
              .addOrCopyToCollection(collection.id, uploadedFiles);
        }
      } catch (e, s) {
        logger.severe("Failed to add to album", e, s);
        await dialog?.hide();
        await showGenericErrorDialog(
          context: context,
          error: e,
        );
        return false;
      } finally {
        // Syncing since successful addition to collection could have
        // happened before a failure
        unawaited(RemoteSyncService.instance.sync(silently: true));
      }
    }

    await dialog?.hide();
    return true;
  }

  Future<bool> addToCollection(
    BuildContext context,
    int collectionID,
    bool showProgressDialog, {
    List<EnteFile>? selectedFiles,
    List<SharedMediaFile>? sharedFiles,
    List<AssetEntity>? picketAssets,
  }) async {
    final ProgressDialog? dialog = showProgressDialog
        ? createProgressDialog(
            context,
            S.of(context).uploadingFilesToAlbum,
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    try {
      final List<EnteFile> uploadedFiles = [];
      final List<EnteFile> filesPendingUpload = [];
      final int currentUserID = Configuration.instance.getUserID()!;
      if (sharedFiles != null) {
        final sharedAssets = await convertIncomingSharedMediaToFile(
          sharedFiles,
          collectionID,
          Configuration.instance.getUserID()!,
        );
        await localDB.insertSharedAssets(sharedAssets);
      } else if (picketAssets != null) {
        filesPendingUpload.addAll(
          await convertPicketAssets(
            picketAssets,
            collectionID,
          ),
        );
      } else {
        for (final file in selectedFiles!) {
          if (file.rAsset != null) {
            uploadedFiles.add(file.copyWith());
          } else if (file.lAsset != null) {
            filesPendingUpload.add(file.copyWith());
          } else {
            throw Exception("File does not have rAsset or lAsset: $file");
          }
        }
      }
      if (filesPendingUpload.isNotEmpty) {
        final Set<String> pendingUploadAssetIDs = {};
        for (final file in filesPendingUpload) {
          pendingUploadAssetIDs.add(file.lAsset!.id);
        }
        await IgnoredFilesService.instance
            .removeIgnoredMappings(filesPendingUpload);
        await localDB.insertOrUpdateQueue(
            pendingUploadAssetIDs, collectionID, currentUserID,
            manual: true);
        Bus.instance.fire(
          CollectionUpdatedEvent(
            collectionID,
            filesPendingUpload,
            "queuedForUpload",
          ),
        );
      }
      if (uploadedFiles.isNotEmpty) {
        await CollectionsService.instance
            .addOrCopyToCollection(collectionID, uploadedFiles);
      }
      unawaited(RemoteSyncService.instance.sync(silently: true));
      await dialog?.hide();
      return true;
    } catch (e, s) {
      logger.severe("Failed to add to album", e, s);
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
