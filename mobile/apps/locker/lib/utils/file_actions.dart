import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:locker/core/errors.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/info/info_item.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/favorites_service.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/info_file_service.dart";
import "package:locker/services/trash/trash_service.dart";
import "package:locker/ui/components/delete_confirmation_sheet.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/ui/components/subscription_required_dialog.dart";
import "package:locker/ui/pages/account_credentials_page.dart";
import "package:locker/ui/pages/base_info_page.dart";
import "package:locker/ui/pages/emergency_contact_page.dart";
import "package:locker/ui/pages/personal_note_page.dart";
import "package:locker/ui/pages/physical_records_page.dart";
import "package:logging/logging.dart";

/// Utility class for common file actions like edit, share, and delete
class FileActions {
  static final _logger = Logger("FileActions");

  /// Shows edit dialog for a file to update title
  static Future<void> editFile(
    BuildContext context,
    EnteFile file, {
    VoidCallback? onSuccess,
  }) async {
    if (InfoFileService.instance.isInfoFile(file)) {
      await _editInfoFile(context, file);
      return;
    }

    _logger.info(
      'Opening edit dialog for file ${file.uploadedFileID}',
    );

    final int currentUserID = Configuration.instance.getUserID()!;
    if (file.ownerID != currentUserID) {
      showToast(context, "Edit feature coming soon");
      return;
    }

    final editableCollections =
        await CollectionService.instance.getCollectionsForUI();

    final currentCollections =
        await CollectionService.instance.getCollectionsForFile(file);

    final favoriteCollection =
        await CollectionService.instance.getOrCreateImportantCollection();

    final currentCollectionIds = currentCollections.map((c) => c.id).toSet();

    final result = await showFileEditDialog(
      context,
      file: file,
      collections: editableCollections,
    );

    if (result == null || !context.mounted) {
      return;
    }

    // Fetch collections in case new ones were created during file edit dialog
    final updatedAllCollections =
        await CollectionService.instance.getCollections();

    final dialog = createProgressDialog(
      context,
      context.l10n.pleaseWait,
      isDismissible: false,
    );
    await dialog.show();

    try {
      final currentTitle = file.displayName;
      final hasMetadataChanged = result.title != currentTitle;

      if (hasMetadataChanged) {
        _logger.info('Updating file metadata: title changed');
        final metadataUpdateSuccess = await MetadataUpdaterService.instance
            .editFileName(file, result.title);

        if (!metadataUpdateSuccess) {
          await dialog.hide();
          if (!context.mounted) {
            return;
          }
          showToast(
            context,
            context.l10n.failedToUpdateFile('Metadata update failed'),
          );
          return;
        }
      }
      final selectedCollectionIds =
          result.selectedCollections.map((c) => c.id).toSet();

      final wasFavorite = currentCollectionIds.contains(favoriteCollection.id);
      final isFavoriteNow =
          selectedCollectionIds.contains(favoriteCollection.id);

      if (wasFavorite && !isFavoriteNow) {
        await FavoritesService.instance.removeFromFavorites(context, file);
      } else if (!wasFavorite && isFavoriteNow) {
        await FavoritesService.instance.addToFavorites(context, file);
      }

      final regularCurrentIds = currentCollectionIds
          .where((id) => id != favoriteCollection.id)
          .toSet();
      final regularSelectedIds = selectedCollectionIds
          .where((id) => id != favoriteCollection.id)
          .toSet();

      final collectionsToRemove =
          regularCurrentIds.difference(regularSelectedIds);

      final collectionsToAdd = regularSelectedIds.difference(regularCurrentIds);

      if (regularSelectedIds.isEmpty && collectionsToRemove.isNotEmpty) {
        _logger.info('All collections deselected, moving to uncategorized');

        for (final collectionId in collectionsToRemove) {
          try {
            final collection =
                updatedAllCollections.firstWhere((c) => c.id == collectionId);
            await CollectionService.instance.moveFilesFromCurrentCollection(
              context,
              collection,
              [file],
            );
          } catch (e) {
            final collection =
                updatedAllCollections.firstWhere((c) => c.id == collectionId);
            _logger.severe(
              'Failed to remove file from collection (ID: ${collection.id}): $e',
            );
          }
        }
      } else {
        for (final collectionId in collectionsToAdd) {
          final collection =
              updatedAllCollections.firstWhere((c) => c.id == collectionId);

          try {
            await CollectionService.instance.addToCollection(
              collection,
              file,
              runSync: false,
            );
          } catch (e) {
            _logger.severe(
              'Failed to move file to collection (ID: ${collection.id}): $e',
            );
          }
        }

        for (final collectionId in collectionsToRemove) {
          final collection =
              updatedAllCollections.firstWhere((c) => c.id == collectionId);
          await CollectionService.instance
              .moveFilesFromCurrentCollection(context, collection, [file]);
        }
      }

      showToast(context, context.l10n.fileUpdatedSuccessfully);

      await CollectionService.instance.sync();

      await dialog.hide();

      onSuccess?.call();
    } catch (e) {
      await dialog.hide();
      _logger.severe('Failed to update file collections: $e');

      if (!context.mounted) {
        return;
      }
      showToast(context, context.l10n.failedToUpdateFile(e.toString()));
    }
  }

  static Future<void> _editInfoFile(
    BuildContext context,
    EnteFile file,
  ) async {
    Widget page;
    final infoItem = InfoFileService.instance.extractInfoFromFile(file);

    if (infoItem == null) {
      _logger.warning(
        'File ${file.uploadedFileID} marked as info file but no info payload found',
      );
      return;
    }

    switch (infoItem.type) {
      case InfoType.note:
        page = PersonalNotePage(
          mode: InfoPageMode.edit,
          existingFile: file,
        );
        break;
      case InfoType.accountCredential:
        page = AccountCredentialsPage(
          mode: InfoPageMode.edit,
          existingFile: file,
        );
        break;
      case InfoType.physicalRecord:
        page = PhysicalRecordsPage(
          mode: InfoPageMode.edit,
          existingFile: file,
        );
        break;
      case InfoType.emergencyContact:
        page = EmergencyContactPage(
          mode: InfoPageMode.edit,
          existingFile: file,
        );
        break;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
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
        await showShareLinkSheet(
          context,
          shareableLink.fullURL!,
          shareableLink.linkID,
          file,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        if (e is SharingNotPermittedForFreeAccountsError) {
          await showSubscriptionRequiredSheet(context);
        } else {
          showToast(
            context,
            context.l10n.failedToCreateShareLink,
          );
        }
      }
    }
  }

  /// Deletes a single file after confirmation
  static Future<void> deleteFile(
    BuildContext context,
    EnteFile file, {
    VoidCallback? onSuccess,
  }) async {
    final confirmation = await showDeleteConfirmationSheet(
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

    final confirmation = await showDeleteConfirmationSheet(
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
