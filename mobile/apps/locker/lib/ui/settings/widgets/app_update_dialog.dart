import "dart:async";

import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/update_service.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:url_launcher/url_launcher_string.dart";

Future<void> showAppUpdateBottomSheet(
  BuildContext context, {
  required LatestVersionInfo latestVersionInfo,
}) async {
  final navigator = Navigator.of(context);
  final l10n = context.l10n;
  final shouldForceUpdate =
      UpdateService.instance.shouldForceUpdate(latestVersionInfo);
  final updateMessage = l10n.aNewVersionOfEnteLockerIsAvailable;
  final title =
      shouldForceUpdate ? l10n.criticalUpdateAvailable : l10n.updateAvailable;

  await showAlertBottomSheet<void>(
    context,
    title: title,
    message: updateMessage,
    assetPath: "assets/warning-blue.png",
    isDismissible: !shouldForceUpdate,
    showCloseButton: !shouldForceUpdate,
    buttons: [
      GradientButton(
        text: l10n.downloadUpdate,
        onTap: () {
          unawaited(
            launchUrlString(
              latestVersionInfo.url,
              mode: LaunchMode.externalApplication,
            ),
          );
          if (!shouldForceUpdate) {
            navigator.pop();
          }
        },
      ),
    ],
  );
}
