import "package:flutter/material.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/permission_granted_event.dart";
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
  final state = await permissionService.requestPhotoMangerPermissions();
  if (state == PermissionState.authorized || state == PermissionState.limited) {
    await permissionService.onUpdatePermission(state);
    SyncService.instance.onPermissionGranted().ignore();
    // Note: Don't fire PermissionGrantedEvent before navigation - it causes
    // home_widget to show its own LoadingPhotosWidget while we navigate to ours,
    // resulting in duplicate BackupFolderSelectionPage navigations.
    if (context.mounted) {
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
      // Fire event after backup flow completes to refresh home_widget
      Bus.instance.fire(PermissionGrantedEvent());
    }
  } else {
    if (context.mounted) {
      await showChoiceDialog(
        context,
        title: context.l10n.allowPermTitle,
        body: context.l10n.allowPermBody,
        firstButtonLabel: context.l10n.openSettings,
        firstButtonOnTap: () async {
          await PhotoManager.openSetting();
        },
      );
    }
  }
}
