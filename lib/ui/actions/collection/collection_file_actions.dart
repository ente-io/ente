import 'package:flutter/cupertino.dart';
import "package:image_picker/image_picker.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/services/favorites_service.dart';
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/remote_sync_service.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/share_util.dart";
import 'package:photos/utils/toast_util.dart';
import "package:receive_sharing_intent/receive_sharing_intent.dart";

extension CollectionFileActions on CollectionActions {
  Future<void> showRemoveFromCollectionSheetV2(
    BuildContext bContext,
    Collection collection,
    SelectedFiles selectedFiles,
    bool removingOthersFile,
  ) async {
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
      showGenericErrorDialog(context: bContext);
    } else {
      selectedFiles.clearAll();
    }
  }

  Future<bool> addToCollection(
    BuildContext context,
    int collectionID,
    bool showProgressDialog, {
    List<File>? selectedFiles,
    List<SharedMediaFile>? sharedFiles,
    List<XFile>? pickedFiles,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(
            context,
            S.of(context).uploadingFilesToAlbum,
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    try {
      final List<File> files = [];
      final List<File> filesPendingUpload = [];
      final int currentUserID = Configuration.instance.getUserID()!;
      if (sharedFiles != null) {
        filesPendingUpload.addAll(
          await convertIncomingSharedMediaToFile(
            sharedFiles,
            collectionID,
          ),
        );
      } else if (pickedFiles != null) {
        filesPendingUpload.addAll(
          await convertPickedFiles(
            pickedFiles,
            collectionID,
          ),
        );
      } else {
        for (final file in selectedFiles!) {
          File? currentFile;
          if (file.uploadedFileID != null) {
            currentFile = file;
          } else if (file.generatedID != null) {
            // when file is not uploaded, refresh the state from the db to
            // ensure we have latest upload status for given file before
            // queueing it up as pending upload
            currentFile = await (FilesDB.instance.getFile(file.generatedID!));
          } else if (file.generatedID == null) {
            logger.severe("generated id should not be null");
          }
          if (currentFile == null) {
            logger.severe("Failed to find fileBy genID");
            continue;
          }
          if (currentFile.uploadedFileID == null) {
            currentFile.collectionID = collectionID;
            filesPendingUpload.add(currentFile);
          } else {
            files.add(currentFile);
          }
        }
      }
      if (filesPendingUpload.isNotEmpty) {
        // Newly created collection might not be cached
        final Collection? c =
            CollectionsService.instance.getCollectionByID(collectionID);
        if (c != null && c.owner!.id != currentUserID) {
          showToast(context, S.of(context).canNotUploadToAlbumsOwnedByOthers);
          await dialog?.hide();
          return false;
        } else {
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
        await CollectionsService.instance.addToCollection(collectionID, files);
      }
      RemoteSyncService.instance.sync(silently: true);
      await dialog?.hide();
      return true;
    } catch (e, s) {
      logger.severe("Failed to add to album", e, s);
      await dialog?.hide();
      showGenericErrorDialog(context: context);
      rethrow;
    }
  }

  Future<bool> updateFavorites(
    BuildContext context,
    List<File> files,
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
