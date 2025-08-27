import "dart:async";

import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/components/dialog_widget.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
Future<void> showInviteDialog(BuildContext context, String email) async {
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
}
