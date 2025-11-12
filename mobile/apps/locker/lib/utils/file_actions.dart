import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/trash/trash_service.dart";
import "package:locker/ui/components/delete_confirmation_dialog.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/utils/collection_list_util.dart";
import "package:logging/logging.dart";

/// Utility class for common file actions like edit, share, and delete
class FileActions {
  static final _logger = Logger("FileActions");

  /// Shows edit dialog for a file to update title, caption, and collections
  static Future<void> editFile(
    BuildContext context,
    EnteFile file, {
    VoidCallback? onSuccess,
  }) async {
    final allCollections = await CollectionService.instance.getCollections();
    final dedupedCollections = uniqueCollectionsById(allCollections);

    final result = await showFileEditDialog(
      context,
      file: file,
      collections: dedupedCollections,
      snackBarContext: context,
    );

    if (result != null && context.mounted) {
      List<Collection> currentCollections;
      try {
        currentCollections =
            await CollectionService.instance.getCollectionsForFile(file);
      } catch (e) {
        currentCollections = <Collection>[];
      }

      final currentCollectionsSet = currentCollections.toSet();
      final selectedCollectionsSet = result.selectedCollections.toSet();
      final collectionsToAdd =
          selectedCollectionsSet.difference(currentCollectionsSet).toList();
      final hasCollectionAdds = collectionsToAdd.isNotEmpty;

      final currentTitle = file.displayName;
      final currentCaption = file.caption ?? '';
      final hasMetadataChanged =
          result.title != currentTitle || result.caption != currentCaption;

      if (hasMetadataChanged || hasCollectionAdds) {
        final dialog = createProgressDialog(
          context,
          context.l10n.pleaseWait,
          isDismissible: false,
        );
        await dialog.show();

        try {
          final addFutures = <Future<void>>[];
          for (final collection in collectionsToAdd) {
            addFutures.add(
              CollectionService.instance.addToCollection(
                collection,
                file,
                runSync: false,
              ),
            );
          }
          if (addFutures.isNotEmpty) {
            await Future.wait(addFutures);
          }

          final List<Future<void>> apiCalls = [];

          if (hasMetadataChanged) {
            apiCalls.add(
              MetadataUpdaterService.instance
                  .editFileNameAndCaption(file, result.title, result.caption),
            );
          }
          await Future.wait(apiCalls);

          await dialog.hide();

          if (!context.mounted) {
            return;
          }

          showToast(
            context,
            context.l10n.fileUpdatedSuccessfully,
          );

          onSuccess?.call();
        } catch (e) {
          await dialog.hide();
          if (!context.mounted) {
            return;
          }

          showToast(
            context,
            context.l10n.failedToUpdateFile(e.toString()),
          );
        }
      } else {
        if (!context.mounted) {
          return;
        }
        showToast(
          context,
          context.l10n.noChangesWereMade,
        );
      }
    }
  }

  /// Creates and shows a shareable link for a file
  static Future<void> shareFileLink(
    BuildContext context,
    EnteFile file,
  ) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.creatingShareLink,
      isDismissible: false,
    );

    try {
      await dialog.show();

      final shareableLink = await LinksService.instance.getOrCreateLink(file);

      await dialog.hide();

      if (context.mounted) {
        await showShareLinkDialog(
          context,
          shareableLink.fullURL!,
          shareableLink.linkID,
          file,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          '${context.l10n.failedToCreateShareLink}: ${e.toString()}',
        );
      }
    }
  }

  /// Deletes a single file after confirmation
  static Future<void> deleteFile(
    BuildContext context,
    EnteFile file, {
    VoidCallback? onSuccess,
  }) async {
    final confirmation = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(1),
      deleteButtonLabel: context.l10n.yesDeleteFiles(1),
      assetPath: "assets/file_delete_icon.png",
    );

    if (confirmation?.buttonResult.action != ButtonAction.first) {
      return;
    }

    final dialog = createProgressDialog(
      context,
      context.l10n.deletingFile,
      isDismissible: false,
    );

    try {
      await dialog.show();

      final collections =
          await CollectionService.instance.getCollectionsForFile(file);
      if (collections.isNotEmpty) {
        await CollectionService.instance.trashFile(file, collections.first);
      }

      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          context.l10n.fileDeletedSuccessfully,
        );
      }

      onSuccess?.call();
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          context.l10n.failedToDeleteFile(e.toString()),
        );
      }
    }
  }

  /// Deletes multiple files after confirmation
  static Future<void> deleteMultipleFiles(
    BuildContext context,
    List<EnteFile> files, {
    VoidCallback? onSuccess,
  }) async {
    if (files.isEmpty) {
      return;
    }

    final confirmation = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(files.length),
      deleteButtonLabel: context.l10n.yesDeleteFiles(files.length),
      assetPath: "assets/file_delete_icon.png",
    );

    if (confirmation?.buttonResult.action != ButtonAction.first) {
      return;
    }

    final dialog = createProgressDialog(
      context,
      context.l10n.deletingFile,
      isDismissible: false,
    );

    try {
      await dialog.show();

      for (final file in files) {
        final collections =
            await CollectionService.instance.getCollectionsForFile(file);

        if (collections.isNotEmpty) {
          await CollectionService.instance.trashFile(
            file,
            collections.first,
            runSync: false,
          );
        }
      }

      await CollectionService.instance.sync();
      await TrashService.instance.syncTrash();

      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          context.l10n.fileDeletedSuccessfully,
        );
      }

      onSuccess?.call();
    } catch (e, stackTrace) {
      await dialog.hide();

      _logger.severe(
        'Failed to delete files: $e',
        e,
        stackTrace,
      );
      if (!context.mounted) {
        return;
      }
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }
}
