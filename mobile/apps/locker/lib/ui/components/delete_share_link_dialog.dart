import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/ui/components/delete_confirmation_dialog.dart";

Future<void> deleteShareLink(BuildContext context, int fileID) async {
  final confirmation = await showDeleteConfirmationDialog(
    context,
    title: context.l10n.deleteShareLinkDialogTitle,
    body: context.l10n.deleteShareLinkConfirmation,
    deleteButtonLabel: context.l10n.delete,
    assetPath: 'assets/file_delete_icon.png',
    showDeleteFromAllCollectionsOption: false,
  );

  if (confirmation?.buttonResult.action == ButtonAction.first &&
      context.mounted) {
    final dialog = createProgressDialog(
      context,
      context.l10n.deletingShareLink,
      isDismissible: false,
    );

    try {
      await dialog.show();
      await LinksService.instance.deleteLink(fileID);
      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          context.l10n.shareLinkDeletedSuccessfully,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        showToast(
          context,
          '${context.l10n.failedToDeleteShareLink}: ${e.toString()}',
        );
      }
    }
  }
}
