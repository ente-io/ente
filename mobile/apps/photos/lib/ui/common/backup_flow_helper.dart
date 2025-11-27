import "dart:async";
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

final _logger = Logger("BackupFlowHelper");

/// Defines how the backup entry flow should handle permissions.
enum BackupFlowType {
  /// Full permission flow - request permissions, show dialogs if denied/limited.
  /// Used by: home_header_widget
  fullPermission,

  /// If limited permission, show presentLimited; else go to folder selection.
  /// Used by: start_backup_hook_widget
  limitedOrFolderSelection,

  /// Just navigate to folder selection without permission handling.
  /// Used by: tab_empty_state, backup_section_widget
  folderSelectionOnly,
}

/// Helper to centralize navigation when users choose to add photos/backup.
///
/// [isFirstBackup] indicates if this is the first backup flow.
/// [flowType] determines how permissions are handled (only when onlyNewPhotos
/// flag is disabled).
Future<void> handleBackupEntryFlow(
  BuildContext context, {
  bool isFirstBackup = false,
  BackupFlowType flowType = BackupFlowType.fullPermission,
}) async {
  // When onlyNewPhotos flag is disabled, use the original simple flows
  if (!flagService.enableOnlyBackupFuturePhotos) {
    await _handleLegacyBackupFlow(
      context,
      isFirstBackup: isFirstBackup,
      flowType: flowType,
    );
    return;
  }

  final state = await _requestPermissions();
  if (state == null) return;

  // Permission denied or restricted - offer to open settings
  if (state != PermissionState.authorized && state != PermissionState.limited) {
    if (!context.mounted) return;
    await showChoiceDialog(
      context,
      title: context.l10n.allowPermTitle,
      body: context.l10n.allowPermBody,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
    );
    return;
  }

  // iOS limited permission - offer to expand access or open settings
  if (state == PermissionState.limited && Platform.isIOS) {
    if (!context.mounted) return;
    await _showLimitedPermissionSheet(context, hasGrantedLimit: true);
    // Fall through to folder selection after dialog
  }

  if (!context.mounted) return;

  // If user skipped permission onboarding, show loading screen first
  // (LoadingPhotosWidget handles navigation to folder selection internally)
  if (backupPreferenceService.hasSkippedOnboardingPermission) {
    await routeToPage(
      context,
      const LoadingPhotosWidget(isOnboardingFlow: false),
    );
    return;
  }

  await routeToPage(
    context,
    BackupFolderSelectionPage(
      isFirstBackup: isFirstBackup,
    ),
  );
}

/// Legacy backup flow (pre-onlyNewPhotos feature).
/// Handles different flow types matching original widget implementations.
Future<void> _handleLegacyBackupFlow(
  BuildContext context, {
  required bool isFirstBackup,
  required BackupFlowType flowType,
}) async {
  switch (flowType) {
    case BackupFlowType.folderSelectionOnly:
      // tab_empty_state, backup_section_widget: just navigate
      await routeToPage(
        context,
        BackupFolderSelectionPage(
          isFirstBackup: isFirstBackup,
        ),
      );

    case BackupFlowType.limitedOrFolderSelection:
      // start_backup_hook_widget: presentLimited or folder selection
      if (permissionService.hasGrantedLimitedPermissions()) {
        unawaited(PhotoManager.presentLimited());
      } else {
        // ignore: unawaited_futures
        routeToPage(
          context,
          BackupFolderSelectionPage(
            isFirstBackup: isFirstBackup,
          ),
        );
      }

    case BackupFlowType.fullPermission:
      // home_header_widget: full permission flow
      await _requestPermissions();

      if (!permissionService.hasGrantedFullPermission()) {
        if (!context.mounted) return;
        if (Platform.isAndroid) {
          await PhotoManager.openSetting();
        } else {
          final bool hasGrantedLimit =
              permissionService.hasGrantedLimitedPermissions();
          // ignore: unawaited_futures
          _showLimitedPermissionSheet(context, hasGrantedLimit: hasGrantedLimit);
        }
      } else {
        unawaited(
          routeToPage(
            context,
            BackupFolderSelectionPage(
              isFirstBackup: isFirstBackup,
            ),
          ),
        );
      }
  }
}

/// Requests photo permissions and updates the permission service.
/// Returns the fresh [PermissionState] or null if an error occurred.
Future<PermissionState?> _requestPermissions() async {
  try {
    final state = await permissionService.requestPhotoMangerPermissions();
    await permissionService.onUpdatePermission(state);
    return state;
  } catch (e, s) {
    _logger.severe("Failed to request permission", e, s);
    return null;
  }
}

/// Shows an action sheet for iOS limited permission, offering to open settings
/// or select more photos.
Future<void> _showLimitedPermissionSheet(
  BuildContext context, {
  required bool hasGrantedLimit,
}) {
  return showChoiceActionSheet(
    context,
    title: context.l10n.preserveMore,
    body: context.l10n.grantFullAccessPrompt,
    firstButtonLabel: context.l10n.openSettings,
    firstButtonOnTap: () async {
      await PhotoManager.openSetting();
    },
    secondButtonLabel:
        hasGrantedLimit ? context.l10n.selectMorePhotos : context.l10n.cancel,
    secondButtonOnTap: () async {
      if (hasGrantedLimit) {
        await PhotoManager.presentLimited();
      }
    },
  );
}
