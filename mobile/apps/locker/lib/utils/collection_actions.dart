import "dart:async";

import "package:ente_accounts/services/user_service.dart";
import "package:ente_sharing/models/user.dart";
import "package:ente_ui/components/action_sheet_widget.dart";
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import "package:ente_ui/components/dialog_widget.dart";
import "package:ente_ui/components/progress_dialog.dart";
import "package:ente_ui/components/user_dialogs.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/email_util.dart";
import "package:ente_utils/share_utils.dart";
import 'package:flutter/material.dart';
import "package:locker/core/errors.dart";
import "package:locker/extensions/user_extension.dart";
import 'package:locker/l10n/l10n.dart';
import "package:locker/services/collections/collections_api_client.dart";
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/configuration.dart";
import "package:locker/services/trash/trash_service.dart";
import "package:locker/ui/components/delete_confirmation_dialog.dart";
import "package:locker/ui/components/input_dialog_sheet.dart";
import 'package:logging/logging.dart';

/// Utility class for common collection actions like edit and delete
class CollectionActions {
  static final _logger = Logger('CollectionActions');

  /// Shows a dialog sheet to create a new collection
  static Future<Collection?> createCollection(
    BuildContext context, {
    bool autoSelectInParent = false,
  }) async {
    Collection? createdCollection;

    final result = await showInputDialogSheet(
      context,
      title: context.l10n.createCollection,
      hintText: context.l10n.documentsHint,
      submitButtonLabel: context.l10n.create,
      onSubmit: (String text) async {
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
    await showInputDialogSheet(
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

          showToast(
            context,
            context.l10n.collectionRenamedSuccessfully,
          );

          // Update the collection name locally
          collection.setName(newName);

          // Call success callback if provided
          onSuccess?.call();
        } catch (error) {
          await progressDialog.hide();

          showToast(
            context,
            context.l10n.failedToRenameCollection(error.toString()),
          );
        }
      },
    );
  }

  static Future<void> deleteMultipleCollections(
    BuildContext context,
    List<Collection> collections, {
    VoidCallback? onSuccess,
  }) async {
    if (collections.isEmpty) return;

    final dialogChoice = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body:
          context.l10n.deleteMultipleCollectionsDialogBody(collections.length),
      deleteButtonLabel: context.l10n.yesDeleteCollections(collections.length),
      assetPath: "assets/collection_delete_icon.png",
      showDeleteFromAllCollectionsOption: true,
    );

    if (dialogChoice?.buttonResult.action != ButtonAction.first) return;

    final progressDialog =
        createProgressDialog(context, context.l10n.pleaseWait);
    await progressDialog.show();

    bool isFavoriteCollection = false;
    final bool keepFiles = !(dialogChoice?.deleteFromAllCollections ?? false);
    final List<Collection> emptyCollections = [];
    final List<Collection> nonEmptyCollections = [];
    final List<dynamic> errors = [];

    try {
      for (final collection in collections) {
        if (collection.type == CollectionType.favorites) {
          isFavoriteCollection = true;
          continue;
        }
        if (!collection.type.canDelete) {
          continue;
        }

        final fileCount =
            await CollectionService.instance.getFileCount(collection);

        if (fileCount == 0) {
          emptyCollections.add(collection);
        } else {
          nonEmptyCollections.add(collection);
        }
      }

      for (final collection in emptyCollections) {
        try {
          await CollectionService.instance.trashEmptyCollection(
            collection,
            isBulkDelete: true,
          );
        } catch (e, s) {
          _logger.severe("Failed to trash empty collection", e, s);
          errors.add(e);
        }
      }

      if (emptyCollections.isNotEmpty) {
        await CollectionService.instance.sync();
        await TrashService.instance.syncTrash();
      }

      for (final collection in nonEmptyCollections) {
        try {
          await CollectionService.instance.trashCollection(
            context,
            collection,
            keepFiles: keepFiles,
          );
        } catch (e, s) {
          _logger.severe("Failed to trash collection", e, s);
          errors.add(e);
        }
      }

      await progressDialog.hide();

      if (errors.isNotEmpty) {
        await showGenericErrorDialog(
          context: context,
          error: errors.first,
        );
      }

      showToast(
        context,
        "${collections.length} collections deleted successfully",
      );

      if (isFavoriteCollection) {
        showToast(
          context,
          "Action not supported on Favourites album",
        );
      }

      onSuccess?.call();
    } catch (error) {
      await progressDialog.hide();

      showToast(
        context,
        context.l10n.failedToDeleteCollection(error.toString()),
      );
    }
  }

  /// Shows a confirmation dialog and deletes a collection
  static Future<void> deleteCollection(
    BuildContext context,
    Collection collection, {
    VoidCallback? onSuccess,
  }) async {
    final l10n = context.l10n;
    if (!collection.type.canDelete) {
      showToast(
        context,
        l10n.collectionCannotBeDeleted,
      );
      return;
    }

    final fileCount = await CollectionService.instance.getFileCount(collection);

    if (fileCount == 0) {
      final progressDialog = createProgressDialog(context, l10n.pleaseWait);
      await progressDialog.show();

      try {
        await CollectionService.instance.trashEmptyCollection(collection);

        await progressDialog.hide();

        if (context.mounted) {
          showToast(
            context,
            l10n.collectionDeletedSuccessfully,
          );
        }

        // Call success callback if provided
        onSuccess?.call();
      } catch (error) {
        await progressDialog.hide();

        if (context.mounted) {
          showToast(
            context,
            l10n.failedToDeleteCollection(error.toString()),
          );
        }
      }
      return;
    }

    final collectionName = collection.name ?? 'this collection';

    final result = await showDeleteConfirmationDialog(
      context,
      title: l10n.areYouSure,
      body: l10n.deleteCollectionDialogBody(collectionName),
      deleteButtonLabel: l10n.yesDeleteCollections(1),
      assetPath: "assets/collection_delete_icon.png",
      showDeleteFromAllCollectionsOption: true,
    );

    if (result?.buttonResult.action != ButtonAction.first && context.mounted) {
      return;
    }

    final progressDialog = createProgressDialog(context, l10n.pleaseWait);
    await progressDialog.show();

    try {
      // If deleteFromAllCollections is true → keepFiles should be false (move files to trash)
      // If deleteFromAllCollections is false → keepFiles should be true (keep files in other collections)
      await CollectionService.instance.trashCollection(
        context,
        collection,
        keepFiles: !(result?.deleteFromAllCollections ?? false),
      );

      await progressDialog.hide();

      if (context.mounted) {
        showToast(
          context,
          l10n.collectionDeletedSuccessfully,
        );
      }

      // Call success callback if provided
      onSuccess?.call();
    } catch (error) {
      await progressDialog.hide();

      if (context.mounted) {
        showToast(
          context,
          l10n.failedToDeleteCollection(error.toString()),
        );
      }
    }
  }

  static Future<void> leaveCollection(
    BuildContext context,
    Collection collection, {
    VoidCallback? onSuccess,
  }) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: context.l10n.leaveCollection,
          onTap: () async {
            await CollectionApiClient.instance.leaveCollection(collection);
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: context.l10n.cancel,
        ),
      ],
      title: context.l10n.leaveCollection,
      body: context.l10n.filesAddedByYouWillBeRemovedFromTheCollection,
    );
    if (actionResult?.action != null && context.mounted) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      } else if (actionResult.action == ButtonAction.first) {
        onSuccess?.call();
        Navigator.of(context).pop();
        showToast(
          context,
          "Leave collection successfully",
        );
      }
    }
  }

  static Future<void> leaveMultipleCollection(
    BuildContext context,
    List<Collection> collections, {
    VoidCallback? onSuccess,
  }) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: context.l10n.leaveCollection,
          onTap: () async {
            for (final col in collections) {
              await CollectionApiClient.instance.leaveCollection(col);
            }
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: context.l10n.cancel,
        ),
      ],
      title: context.l10n.leaveCollection,
      body: context.l10n.filesAddedByYouWillBeRemovedFromTheCollection,
    );
    if (actionResult?.action != null && context.mounted) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      } else if (actionResult.action == ButtonAction.first) {
        onSuccess?.call();
        Navigator.of(context).pop();
        showToast(
          context,
          "Leave collection successfully",
        );
      }
    }
  }

  static Future<bool> enableUrl(
    BuildContext context,
    Collection collection, {
    bool enableCollect = false,
  }) async {
    try {
      await CollectionApiClient.instance.createShareUrl(
        collection,
        enableCollect: enableCollect,
      );
      return true;
    } catch (e) {
      if (e is SharingNotPermittedForFreeAccountsError) {
        await _showUnSupportedAlert(context);
      } else {
        _logger.severe("Failed to update shareUrl collection", e);
        await showGenericErrorDialog(context: context, error: e);
      }
      return false;
    }
  }

  static Future<bool> disableUrl(
    BuildContext context,
    Collection collection,
  ) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: "Yes, remove",
          onTap: () async {
            await CollectionApiClient.instance.disableShareUrl(collection);
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: context.l10n.cancel,
        ),
      ],
      title: "Remove public link",
      body:
          "This will remove the public link for accessing \"${collection.name}\".",
    );
    if (actionResult?.action != null) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      }
      return actionResult.action == ButtonAction.first;
    } else {
      return false;
    }
  }

  static Future<void> _showUnSupportedAlert(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      title: const Text("Sorry"),
      content: const Text(
        "You need an active paid subscription to enable sharing.",
      ),
      actions: [
        ButtonWidget(
          buttonType: ButtonType.primary,
          isInAlert: true,
          shouldStickToDarkTheme: false,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: "Subscribe",
          onTap: () async {
            // TODO: If we are having subscriptions for locker
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (BuildContext context) {
            //       return getSubscriptionPage();
            //     },
            //   ),
            // ).ignore();
            Navigator.of(context).pop();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ButtonWidget(
            buttonType: ButtonType.secondary,
            buttonAction: ButtonAction.cancel,
            isInAlert: true,
            shouldStickToDarkTheme: false,
            labelText: context.l10n.ok,
          ),
        ),
      ],
    );

    return showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
      barrierDismissible: true,
    );
  }

  Future<bool> doesEmailHaveAccount(
    BuildContext context,
    String email, {
    bool showProgress = false,
  }) async {
    ProgressDialog? dialog;
    String? publicKey;
    if (showProgress) {
      dialog = createProgressDialog(
        context,
        context.l10n.sharing,
        isDismissible: true,
      );
      await dialog.show();
    }
    try {
      publicKey = await UserService.instance.getPublicKey(email);
    } catch (e) {
      await dialog?.hide();
      _logger.severe("Failed to get public key", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    // getPublicKey can return null when no user is associated with given
    // email id
    if (publicKey == null || publicKey == '') {
      // todo: neeraj replace this as per the design where a new screen
      // is used for error. Do this change along with handling of network errors
      await showInviteDialog(context, email);
      return false;
    } else {
      return true;
    }
  }

  // addEmailToCollection returns true if add operation was successful
  Future<bool> addEmailToCollection(
    BuildContext context,
    Collection collection,
    String email,
    CollectionParticipantRole role, {
    bool showProgress = false,
  }) async {
    if (!isValidEmail(email)) {
      await showErrorDialog(
        context,
        context.l10n.invalidEmailAddress,
        context.l10n.enterValidEmail,
      );
      return false;
    } else if (email.trim() == Configuration.instance.getEmail()) {
      await showErrorDialog(
        context,
        context.l10n.oops,
        context.l10n.youCannotShareWithYourself,
      );
      return false;
    }

    ProgressDialog? dialog;
    String? publicKey;
    if (showProgress) {
      dialog = createProgressDialog(
        context,
        context.l10n.sharing,
        isDismissible: true,
      );
      await dialog.show();
    }

    try {
      publicKey = await UserService.instance.getPublicKey(email);
    } catch (e) {
      await dialog?.hide();
      _logger.severe("Failed to get public key", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    // getPublicKey can return null when no user is associated with given
    // email id
    if (publicKey == null || publicKey == '') {
      // todo: neeraj replace this as per the design where a new screen
      // is used for error. Do this change along with handling of network errors
      await showDialogWidget(
        context: context,
        title: context.l10n.inviteToEnte,
        icon: Icons.info_outline,
        body: context.l10n.emailNoEnteAccount(email),
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            icon: Icons.adaptive.share,
            labelText: context.l10n.sendInvite,
            isInAlert: true,
            onTap: () async {
              unawaited(
                shareText(
                  context.l10n.shareTextRecommendUsingEnte,
                ),
              );
            },
          ),
        ],
      );
      return false;
    } else {
      try {
        final newSharees = await CollectionApiClient.instance
            .share(collection.id, email, publicKey, role);
        await dialog?.hide();
        collection.updateSharees(newSharees);
        return true;
      } catch (e) {
        await dialog?.hide();
        if (e is SharingNotPermittedForFreeAccountsError) {
          await _showUnSupportedAlert(context);
        } else {
          _logger.severe("failed to share collection", e);
          await showGenericErrorDialog(context: context, error: e);
        }
        return false;
      }
    }
  }

  // removeParticipant remove the user from a share album
  Future<bool> removeParticipant(
    BuildContext context,
    Collection collection,
    User user,
  ) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: context.l10n.yesRemove,
          onTap: () async {
            final newSharees = await CollectionApiClient.instance
                .unshare(collection.id, user.email);
            collection.updateSharees(newSharees);
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: context.l10n.cancel,
        ),
      ],
      title: context.l10n.removeWithQuestionMark,
      body: context.l10n.removeParticipantBody(user.displayName ?? user.email),
    );
    if (actionResult?.action != null) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      }
      return actionResult.action == ButtonAction.first;
    }
    return false;
  }
}
