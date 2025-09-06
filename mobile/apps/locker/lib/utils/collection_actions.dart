import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/utils/snack_bar_utils.dart';
import 'package:logging/logging.dart';

/// Utility class for common collection actions like edit and delete
class CollectionActions {
  static final _logger = Logger('CollectionActions');

  /// Shows a dialog to create a new collection
  static Future<Collection?> createCollection(
    BuildContext context, {
    bool autoSelectInParent = false,
  }) async {
    Collection? createdCollection;

    final nameSuggestion =
        await CollectionService.instance.getRandomUnusedCollectionName();

    final result = await showTextInputDialog(
      context,
      title: context.l10n.createNewCollection,
      submitButtonLabel: context.l10n.create,
      hintText: nameSuggestion,
      alwaysShowSuccessState: true,
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        // indicates user cancelled the creation request
        if (text.trim().isEmpty) {
          return;
        }

        try {
          createdCollection =
              await CollectionService.instance.createCollection(text.trim());
        } catch (e, s) {
          _logger.severe('Failed to create collection', e, s);
          rethrow;
        }
      },
    );

    if (result is Exception) {
      if (context.mounted) {
        await showGenericErrorDialog(
          context: context,
          error: result,
        );
      }
      return null;
    } else if (createdCollection != null) {
      return createdCollection;
    }

    return null;
  }

  // Shows a dialog to edit/rename a collection
  static Future<void> editCollection(
    BuildContext context,
    Collection collection, {
    VoidCallback? onSuccess,
  }) async {
    await showTextInputDialog(
      context,
      title: context.l10n.renameCollection,
      initialValue: collection.name ?? '',
      hintText: context.l10n.documentsHint,
      submitButtonLabel: context.l10n.save,
      onSubmit: (String newName) async {
        if (newName.isEmpty || newName == collection.name) return;

        final progressDialog =
            createProgressDialog(context, context.l10n.pleaseWait);
        await progressDialog.show();

        try {
          await CollectionService.instance.rename(collection, newName);
          await progressDialog.hide();

          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.collectionRenamedSuccessfully,
          );

          // Update the collection name locally
          collection.setName(newName);

          // Call success callback if provided
          onSuccess?.call();
        } catch (error) {
          await progressDialog.hide();

          SnackBarUtils.showWarningSnackBar(
            context,
            context.l10n.failedToRenameCollection(error.toString()),
          );
        }
      },
    );
  }

  /// Shows a confirmation dialog and deletes a collection
  static Future<void> deleteCollection(
    BuildContext context,
    Collection collection, {
    VoidCallback? onSuccess,
  }) async {
    if (!collection.type.canDelete) {
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.collectionCannotBeDeleted,
      );
      return;
    }

    final collectionName = collection.name ?? 'this collection';

    final dialogChoice = await showChoiceDialog(
      context,
      title: context.l10n.deleteCollection,
      body: context.l10n.deleteCollectionConfirmation(collectionName),
      firstButtonLabel: context.l10n.delete,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );

    if (dialogChoice?.action != ButtonAction.first) return;

    final progressDialog =
        createProgressDialog(context, context.l10n.pleaseWait);
    await progressDialog.show();

    try {
      await CollectionService.instance.trashCollection(collection);
      await progressDialog.hide();

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.collectionDeletedSuccessfully,
      );

      // Call success callback if provided
      onSuccess?.call();
    } catch (error) {
      await progressDialog.hide();

      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToDeleteCollection(error.toString()),
      );
    }
  }
}
