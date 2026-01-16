import "dart:io";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/services/sync/sync_service.dart";
import "package:photos/services/wake_lock_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/backup_flow_helper.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/utils/dialog_util.dart";

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  static final Debouncer _onlyNewToggleDebouncer = Debouncer(
    const Duration(milliseconds: 500),
    leading: true,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).backupSettings,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenuItemWidgetNew(
                        title:
                            AppLocalizations.of(context).backupOverMobileData,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => Configuration.instance
                              .shouldBackupOverMobileData(),
                          onChanged: () async {
                            await Configuration.instance
                                .setBackupOverMobileData(
                              !Configuration.instance
                                  .shouldBackupOverMobileData(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).backupVideos,
                        trailingWidget: ToggleSwitchWidget(
                          value: () =>
                              Configuration.instance.shouldBackupVideos(),
                          onChanged: () =>
                              Configuration.instance.setShouldBackupVideos(
                            !Configuration.instance.shouldBackupVideos(),
                          ),
                        ),
                      ),
                      if (_shouldShowOnlyNewToggle()) ...[
                        const SizedBox(height: 8),
                        _BackupOnlyNewPhotosToggle(
                          debouncer: _onlyNewToggleDebouncer,
                        ),
                      ],
                      if (flagService.enableMobMultiPart) ...[
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).resumableUploads,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => localSettings.userEnabledMultiplePart,
                            onChanged: () async {
                              await localSettings.setUserEnabledMultiplePart(
                                !localSettings.userEnabledMultiplePart,
                              );
                            },
                          ),
                        ),
                      ],
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 24),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).disableAutoLock,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => EnteWakeLockService
                                .instance.shouldKeepAppAwakeAcrossSessions,
                            onChanged: () async {
                              EnteWakeLockService.instance.updateWakeLock(
                                enable: !EnteWakeLockService
                                    .instance.shouldKeepAppAwakeAcrossSessions,
                                wakeLockFor: WakeLockFor
                                    .fasterBackupsOniOSByKeepingScreenAwake,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 16,
                          ),
                          child: Text(
                            AppLocalizations.of(context).deviceLockExplanation,
                            style: textTheme.mini
                                .copyWith(color: colorScheme.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowOnlyNewToggle() {
    return flagService.enableOnlyBackupFuturePhotos;
  }
}

class _BackupOnlyNewPhotosToggle extends StatelessWidget {
  final Debouncer debouncer;

  const _BackupOnlyNewPhotosToggle({required this.debouncer});

  @override
  Widget build(BuildContext context) {
    return MenuItemWidgetNew(
      title: context.l10n.backupOnlyNewPhotos,
      trailingWidget: ToggleSwitchWidget(
        value: () => backupPreferenceService.isOnlyNewBackupEnabled,
        onChanged: () async {
          final hasPermission = await _ensurePhotoPermissions(context);
          if (!hasPermission) {
            return;
          }
          final shouldProceed = await _maybeHandleFolderSelection(
            context: context,
          );
          if (!shouldProceed) {
            return;
          }
          final isEnabled = backupPreferenceService.isOnlyNewBackupEnabled;
          if (!isEnabled) {
            await backupPreferenceService.setOnlyNewSinceNow();
          } else {
            await backupPreferenceService.clearOnlyNewSinceEpoch();
          }
          debouncer.run(() async {
            await SyncService.instance.sync();
          });
          if (backupPreferenceService.hasSkippedOnboardingPermission) {
            await backupPreferenceService.setOnboardingPermissionSkipped(
              false,
            );
          }
        },
      ),
    );
  }

  Future<bool> _ensurePhotoPermissions(BuildContext context) async {
    final state = await permissionService.requestPhotoMangerPermissions();
    if (state == PermissionState.authorized ||
        state == PermissionState.limited) {
      await permissionService.onUpdatePermission(state);
      SyncService.instance.onPermissionGranted().ignore();
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    await showChoiceDialog(
      context,
      title: context.l10n.allowPermTitle,
      body: context.l10n.allowPermBody,
      firstButtonLabel: context.l10n.openSettings,
      secondButtonLabel: context.l10n.cancel,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
    );
    return false;
  }

  Future<bool> _maybeHandleFolderSelection({
    required BuildContext context,
  }) async {
    final needsFolderPrompt =
        !backupPreferenceService.hasManualFolderSelection &&
            (backupPreferenceService.hasSelectedAllFoldersForBackup ||
                !backupPreferenceService.hasSelectedAnyBackupFolder);
    if (!needsFolderPrompt) {
      return true;
    }

    final hasAllFoldersSelected =
        backupPreferenceService.hasSelectedAllFoldersForBackup;

    // Hide "Continue anyway" if user skipped permission and first import not done
    final allowContinueAnyway =
        !backupPreferenceService.hasSkippedOnboardingPermission ||
            LocalSyncService.instance.hasCompletedFirstImport();

    final result = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: context.l10n.selectFolders,
          buttonType: ButtonType.primary,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: false,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
        if (allowContinueAnyway)
          ButtonWidget(
            labelText: context.l10n.continueLabel,
            buttonType: ButtonType.neutral,
            buttonAction: ButtonAction.second,
            shouldSurfaceExecutionStates: false,
            shouldStickToDarkTheme: true,
            isInAlert: true,
          ),
        ButtonWidget(
          labelText: context.l10n.cancel,
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          shouldSurfaceExecutionStates: false,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      title: context.l10n.backupOnlyNewPhotos,
      body: hasAllFoldersSelected
          ? context.l10n.backupOnlyNewPhotosAllFoldersSelected
          : allowContinueAnyway
              ? context.l10n.backupOnlyNewPhotosNoFoldersSelectedContinue
              : context.l10n.backupOnlyNewPhotosNoFoldersSelectedRequire,
    );

    if (result?.action == null || result!.action == ButtonAction.cancel) {
      return false;
    }

    if (result.action == ButtonAction.first) {
      final bool? selected = await handleFolderSelectionBackupFlow(
        context,
        fromOnlyNewPhotosToggle: true,
      );
      if (selected != true) {
        return false;
      }
    } else if (result.action == ButtonAction.second) {
      await backupPreferenceService.setHasManualFolderSelection(true);
    }

    return true;
  }
}
