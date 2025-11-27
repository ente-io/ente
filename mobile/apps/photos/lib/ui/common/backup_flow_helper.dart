import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/home/loading_photos_widget.dart";
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

/// Helper to centralize navigation when users choose to add photos/backup.
/// [onFirstImportComplete] lets callers override the destination screen once
/// permissions are granted and initial import is done. Defaults to folder
/// selection.
Future<void> handleBackupEntryFlow(
  BuildContext context, {
  bool isFirstBackup = false,
}) async {
  PermissionState state;
  try {
    // Always fetch fresh permission state from the platform instead of relying
    // on cached prefs; this avoids stale reads when users change OS settings.
    state = await permissionService.requestPhotoMangerPermissions();
    await permissionService.onUpdatePermission(state);
  } catch (e, s) {
    Logger("BackupEntryFlow").severe(
      "Failed to request permission",
      e,
      s,
    );
    return;
  }

  if (state != PermissionState.authorized && state != PermissionState.limited) {
    if (!context.mounted) {
      return;
    }

    if (Platform.isAndroid) {
      // On Android, we can only direct users to system settings for upgrades.
      await PhotoManager.openSetting();
      return;
    }

    // On iOS, offer a path to either open settings or expand limited access.
    final bool hasLimited = state == PermissionState.limited;
    await showChoiceActionSheet(
      context,
      title: context.l10n.preserveMore,
      body: context.l10n.grantFullAccessPrompt,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
      secondButtonLabel:
          hasLimited ? context.l10n.selectMorePhotos : context.l10n.cancel,
      secondButtonOnTap: () async {
        if (hasLimited) {
          await PhotoManager.presentLimited();
        }
      },
    );
    return;
  }

  if (!context.mounted) {
    return;
  }

  final bool didSkipPermissionOnboarding =
      backupPreferenceService.hasSkippedOnboardingPermission;
  // If the user skipped permission onboarding, still show the loading screen
  // before navigating to folder selection; otherwise proceed directly.
  if (didSkipPermissionOnboarding) {
    await routeToPage(
      context,
      const LoadingPhotosWidget(isOnboardingFlow: false),
    );
  }

  await routeToPage(
    context,
    BackupFolderSelectionPage(
      isFirstBackup: isFirstBackup,
    ),
  );
}
