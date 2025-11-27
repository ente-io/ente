import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/home/loading_photos_widget.dart";
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

/// Helper to centralize navigation when users choose to add photos/backup.
///
/// [isFirstBackup] indicates if this is the first backup flow.
/// [askPermission] (only when onlyNewPhotos flag is disabled) controls whether
/// to request permissions before navigating.
Future<void> handleBackupEntryFlow(
  BuildContext context, {
  bool isFirstBackup = false,
  bool askPermission = true,
}) async {
  // When onlyNewPhotos flag is disabled, use the original simple flow
  if (!flagService.enableOnlyBackupFuturePhotos) {
    await _handleLegacyBackupFlow(context, askPermission: askPermission);
    return;
  }

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
    await showChoiceActionSheet(
      context,
      title: context.l10n.preserveMore,
      body: context.l10n.grantFullAccessPrompt,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
      secondButtonLabel: context.l10n.selectMorePhotos,
      secondButtonOnTap: () async {
        await PhotoManager.presentLimited();
      },
    );
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
/// Matches the original home_header_widget inline implementation.
Future<void> _handleLegacyBackupFlow(
  BuildContext context, {
  required bool askPermission,
}) async {
  if (askPermission) {
    try {
      final PermissionState state =
          await permissionService.requestPhotoMangerPermissions();
      await permissionService.onUpdatePermission(state);
    } on Exception catch (e) {
      Logger("HomeHeaderWidget").severe(
        "Failed to request permission: ${e.toString()}",
        e,
      );
    }
  }

  if (!permissionService.hasGrantedFullPermission()) {
    if (!context.mounted) return;
    if (Platform.isAndroid) {
      await PhotoManager.openSetting();
    } else {
      final bool hasGrantedLimit =
          permissionService.hasGrantedLimitedPermissions();
      // ignore: unawaited_futures
      showChoiceActionSheet(
        context,
        title: AppLocalizations.of(context).preserveMore,
        body: AppLocalizations.of(context).grantFullAccessPrompt,
        firstButtonLabel: AppLocalizations.of(context).openSettings,
        firstButtonOnTap: () async {
          await PhotoManager.openSetting();
        },
        secondButtonLabel: hasGrantedLimit
            ? AppLocalizations.of(context).selectMorePhotos
            : AppLocalizations.of(context).cancel,
        secondButtonOnTap: () async {
          if (hasGrantedLimit) {
            await PhotoManager.presentLimited();
          }
        },
      );
    }
  } else {
    unawaited(
      routeToPage(
        context,
        const BackupFolderSelectionPage(
          isFirstBackup: false,
        ),
      ),
    );
  }
}
