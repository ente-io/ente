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

/// Full permission flow - request permissions, show dialogs if denied/limited.
/// Used by: home_header_widget
Future<void> handleFullPermissionBackupFlow(BuildContext context) async {
  if (await _handleSkippedPermissionFlow(context)) return;

  await _requestPermissions();
  if (!context.mounted) return;

  if (permissionService.hasGrantedFullPermission()) {
    unawaited(_navigateToFolderSelection(context, isFirstBackup: false));
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

/// If limited permission, show presentLimited; else go to folder selection.
/// Used by: start_backup_hook_widget
Future<void> handleLimitedOrFolderBackupFlow(
  BuildContext context, {
  bool isFirstBackup = true,
}) async {
  if (await _handleSkippedPermissionFlow(context)) return;

  if (permissionService.hasGrantedLimitedPermissions()) {
    unawaited(PhotoManager.presentLimited());
  } else {
    unawaited(_navigateToFolderSelection(context, isFirstBackup: isFirstBackup));
  }
}

/// Just navigate to folder selection without permission handling.
/// Used by: tab_empty_state, backup_section_widget
Future<void> handleFolderSelectionBackupFlow(
  BuildContext context, {
  bool isFirstBackup = false,
}) async {
  if (await _handleSkippedPermissionFlow(context)) return;

  await _navigateToFolderSelection(context, isFirstBackup: isFirstBackup);
}

/// Handles skipped permission flow if user skipped during onboarding.
/// Returns true if handled (caller should return), false otherwise.
Future<bool> _handleSkippedPermissionFlow(BuildContext context) async {
  if (!backupPreferenceService.hasSkippedOnboardingPermission) {
    return false;
  }

  final state = await _requestPermissions();
  if (state == null || !context.mounted) return true;

  if (!_hasMinimalPermission(state)) {
    await _showPermissionDeniedDialog(context);
    return true;
  }

  if (state == PermissionState.limited && Platform.isIOS) {
    await _showLimitedPermissionSheet(context, hasGrantedLimit: true);
    if (!context.mounted) return true;
  }

  // LoadingPhotosWidget handles navigation to folder selection internally
  await routeToPage(
    context,
    const LoadingPhotosWidget(isOnboardingFlow: false),
  );
  return true;
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
    routeToPage(
      context,
      BackupFolderSelectionPage(isFirstBackup: isFirstBackup),
    );

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
