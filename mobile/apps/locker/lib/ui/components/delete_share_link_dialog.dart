import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/utils/snack_bar_utils.dart";

Future<void> deleteShareLink(BuildContext context, int fileID) async {
  final result = await showChoiceDialog(
    context,
    title: context.l10n.deleteShareLinkDialogTitle,
    body: context.l10n.deleteShareLinkConfirmation,
    firstButtonLabel: context.l10n.delete,
    secondButtonLabel: context.l10n.cancel,
    firstButtonType: ButtonType.critical,
    isCritical: true,
  );
  if (result?.action == ButtonAction.first && context.mounted) {
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
        SnackBarUtils.showInfoSnackBar(
          context,
          context.l10n.shareLinkDeletedSuccessfully,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          '${context.l10n.failedToDeleteShareLink}: ${e.toString()}',
        );
      }
    }
  }
}
