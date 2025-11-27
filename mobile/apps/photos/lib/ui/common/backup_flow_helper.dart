import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/services/sync/sync_service.dart";
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
  Widget Function()? onFirstImportComplete,
}) async {
  try {
    final PermissionState state =
        await permissionService.requestPhotoMangerPermissions();
    await permissionService.onUpdatePermission(state);
  } on Exception catch (e, s) {
    Logger("BackupEntryFlow").severe(
      "Failed to request permission: ${e.toString()}",
      e,
      s,
    );
    return;
  }

  if (!permissionService.hasGrantedFullPermission()) {
    if (!context.mounted) {
      return;
    }
    if (Platform.isAndroid) {
      await PhotoManager.openSetting();
      return;
    }
    final bool hasGrantedLimit =
        permissionService.hasGrantedLimitedPermissions();
    await showChoiceActionSheet(
      context,
      title: context.l10n.preserveMore,
      body: context.l10n.grantFullAccessPrompt,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
      secondButtonLabel:
          hasGrantedLimit ? context.l10n.selectMorePhotos : context.l10n.cancel,
      secondButtonOnTap: hasGrantedLimit
          ? () async {
              await PhotoManager.presentLimited();
            }
          : null,
    );
    return;
  }

  SyncService.instance.onPermissionGranted().ignore();
  // Note: Don't fire PermissionGrantedEvent before navigation - it causes
  // home_widget to show its own LoadingPhotosWidget while we navigate to ours,
  // resulting in duplicate BackupFolderSelectionPage navigations.
  if (!context.mounted) {
    return;
  }
  final Widget Function() targetBuilder = onFirstImportComplete ??
      () => const BackupFolderSelectionPage(
            isFirstBackup: false,
          );
  final shouldWaitForFirstImport =
      !LocalSyncService.instance.hasCompletedFirstImport();
  if (shouldWaitForFirstImport) {
    // Wait for initial sync, then proceed to folder selection
    await routeToPage(
      context,
      const LoadingPhotosWidget(isOnboardingFlow: false),
    );
  } else {
    await routeToPage(
      context,
      targetBuilder(),
    );
  }

  // Refresh home UI state without firing PermissionGrantedEvent to avoid
  // duplicate navigation to folder selection.
  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
