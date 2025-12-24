import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";

Future<void> showSubscriptionRequiredSheet(BuildContext context) async {
  final l10n = context.l10n;

  await showAlertBottomSheet(
    context,
    title: l10n.sorry,
    message: l10n.subscriptionRequiredForSharing,
    assetPath: 'assets/warning-blue.png',
  );
}
