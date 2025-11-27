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
/// [flowType] determines how permissions are handled.
Future<void> handleBackupEntryFlow(
  BuildContext context, {
  bool isFirstBackup = false,
  BackupFlowType flowType = BackupFlowType.fullPermission,
}) async {
  // New flow only for skipped permission users when flag is enabled
  final shouldUseNewFlow = flagService.enableOnlyBackupFuturePhotos &&
      backupPreferenceService.hasSkippedOnboardingPermission;

  if (shouldUseNewFlow) {
    await _handleSkippedPermissionFlow(context);
    return;
  }

  // Otherwise use standard flow based on flowType
  await _handleStandardFlow(context, isFirstBackup: isFirstBackup, flowType: flowType);
}

/// New flow for users who skipped permission during onboarding.
/// Shows LoadingPhotosWidget after granting permissions.
Future<void> _handleSkippedPermissionFlow(BuildContext context) async {
  final state = await _requestPermissions();
  if (state == null || !context.mounted) return;

  if (!_hasMinimalPermission(state)) {
    await _showPermissionDeniedDialog(context);
    return;
  }

  if (state == PermissionState.limited && Platform.isIOS) {
    await _showLimitedPermissionSheet(context, hasGrantedLimit: true);
    if (!context.mounted) return;
  }

  // LoadingPhotosWidget handles navigation to folder selection internally
  await routeToPage(context, const LoadingPhotosWidget(isOnboardingFlow: false));
}

/// Standard backup flow based on flowType.
Future<void> _handleStandardFlow(
  BuildContext context, {
  required bool isFirstBackup,
  required BackupFlowType flowType,
}) async {
  switch (flowType) {
    case BackupFlowType.folderSelectionOnly:
      await _navigateToFolderSelection(context, isFirstBackup: isFirstBackup);

    case BackupFlowType.limitedOrFolderSelection:
      if (permissionService.hasGrantedLimitedPermissions()) {
        unawaited(PhotoManager.presentLimited());
      } else {
        unawaited(_navigateToFolderSelection(context, isFirstBackup: isFirstBackup));
      }

    case BackupFlowType.fullPermission:
      await _requestPermissions();
      if (!context.mounted) return;

      if (permissionService.hasGrantedFullPermission()) {
        unawaited(_navigateToFolderSelection(context, isFirstBackup: isFirstBackup));
      } else if (Platform.isAndroid) {
        await PhotoManager.openSetting();
      } else {
        // ignore: unawaited_futures
        _showLimitedPermissionSheet(
          context,
          hasGrantedLimit: permissionService.hasGrantedLimitedPermissions(),
        );
      }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper functions
// ─────────────────────────────────────────────────────────────────────────────

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

bool _hasMinimalPermission(PermissionState state) =>
    state == PermissionState.authorized || state == PermissionState.limited;

Future<void> _navigateToFolderSelection(
  BuildContext context, {
  required bool isFirstBackup,
}) =>
    routeToPage(context, BackupFolderSelectionPage(isFirstBackup: isFirstBackup));

Future<void> _showPermissionDeniedDialog(BuildContext context) =>
    showChoiceDialog(
      context,
      title: context.l10n.allowPermTitle,
      body: context.l10n.allowPermBody,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async => PhotoManager.openSetting(),
    );

Future<void> _showLimitedPermissionSheet(
  BuildContext context, {
  required bool hasGrantedLimit,
}) =>
    showChoiceActionSheet(
      context,
      title: context.l10n.preserveMore,
      body: context.l10n.grantFullAccessPrompt,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async => PhotoManager.openSetting(),
      secondButtonLabel:
          hasGrantedLimit ? context.l10n.selectMorePhotos : context.l10n.cancel,
      secondButtonOnTap: () async {
        if (hasGrantedLimit) await PhotoManager.presentLimited();
      },
    );
