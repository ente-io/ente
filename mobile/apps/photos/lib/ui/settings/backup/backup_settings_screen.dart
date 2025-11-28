import "dart:io";

import 'package:flutter/material.dart';
import "package:photo_manager/photo_manager.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/sync/sync_service.dart';
import 'package:photos/services/wake_lock_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/backup_flow_helper.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/standalone/debouncer.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});
  static final Debouncer _onlyNewToggleDebouncer = Debouncer(
    const Duration(milliseconds: 500),
    leading: true,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).backupSettings,
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: AppLocalizations.of(context)
                                    .backupOverMobileData,
                              ),
                              menuItemColor: colorScheme.fillFaint,
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
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isBottomBorderRadiusRemoved: true,
                              isGestureDetectorDisabled: true,
                            ),
                            DividerWidget(
                              dividerType: DividerType.menuNoIcon,
                              bgColor: colorScheme.fillFaint,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title:
                                    AppLocalizations.of(context).backupVideos,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () =>
                                    Configuration.instance.shouldBackupVideos(),
                                onChanged: () => Configuration.instance
                                    .setShouldBackupVideos(
                                  !Configuration.instance.shouldBackupVideos(),
                                ),
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isTopBorderRadiusRemoved: true,
                              isGestureDetectorDisabled: true,
                              isBottomBorderRadiusRemoved:
                                  flagService.enableMobMultiPart ||
                                      _shouldShowOnlyNewToggle(),
                            ),
                            if (_shouldShowOnlyNewToggle())
                              ..._buildOnlyNewToggleSection(
                                context,
                                colorScheme,
                              ),
                            if (flagService.enableMobMultiPart)
                              DividerWidget(
                                dividerType: DividerType.menuNoIcon,
                                bgColor: colorScheme.fillFaint,
                              ),
                            if (flagService.enableMobMultiPart)
                              MenuItemWidget(
                                captionedTextWidget: CaptionedTextWidget(
                                  title: AppLocalizations.of(context)
                                      .resumableUploads,
                                ),
                                menuItemColor: colorScheme.fillFaint,
                                singleBorderRadius: 8,
                                trailingWidget: ToggleSwitchWidget(
                                  value: () =>
                                      localSettings.userEnabledMultiplePart,
                                  onChanged: () async {
                                    await localSettings
                                        .setUserEnabledMultiplePart(
                                      !localSettings.userEnabledMultiplePart,
                                    );
                                  },
                                ),
                                alignCaptionedTextToLeft: true,
                                isTopBorderRadiusRemoved: true,
                                isGestureDetectorDisabled: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Platform.isIOS
                            ? Column(
                                children: [
                                  MenuItemWidget(
                                    captionedTextWidget: CaptionedTextWidget(
                                      title: AppLocalizations.of(context)
                                          .disableAutoLock,
                                    ),
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingWidget: ToggleSwitchWidget(
                                      value: () => EnteWakeLockService.instance
                                          .shouldKeepAppAwakeAcrossSessions,
                                      onChanged: () async {
                                        EnteWakeLockService.instance
                                            .updateWakeLock(
                                          enable: !EnteWakeLockService.instance
                                              .shouldKeepAppAwakeAcrossSessions,
                                          wakeLockFor: WakeLockFor
                                              .fasterBackupsOniOSByKeepingScreenAwake,
                                        );
                                      },
                                    ),
                                    singleBorderRadius: 8,
                                    alignCaptionedTextToLeft: true,
                                    isGestureDetectorDisabled: true,
                                  ),
                                  MenuSectionDescriptionWidget(
                                    content: AppLocalizations.of(context)
                                        .deviceLockExplanation,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowOnlyNewToggle() {
    return flagService.enableOnlyBackupFuturePhotos;
  }

  List<Widget> _buildOnlyNewToggleSection(
    BuildContext context,
    dynamic colorScheme,
  ) {
    return [
      DividerWidget(
        dividerType: DividerType.menuNoIcon,
        bgColor: colorScheme.fillFaint,
      ),
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Backup only new photos",
        ),
        menuItemColor: colorScheme.fillFaint,
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
              _onlyNewToggleDebouncer.run(() async {
                await SyncService.instance.sync();
              });
            } else {
              await backupPreferenceService.clearOnlyNewSinceEpoch();
              _onlyNewToggleDebouncer.run(() async {
                await SyncService.instance.sync();
              });
            }
            if (backupPreferenceService.hasSkippedOnboardingPermission) {
              await backupPreferenceService.setOnboardingPermissionSkipped(
                false,
              );
            }
          },
        ),
        singleBorderRadius: 8,
        alignCaptionedTextToLeft: true,
        isTopBorderRadiusRemoved: true,
        isGestureDetectorDisabled: true,
      ),
    ];
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
    final result = await showActionSheet(
      context: context,
      buttons: [
        const ButtonWidget(
          labelText: "Select folders",
          buttonType: ButtonType.primary,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: false,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
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
      title: "Only backup new photos",
      body: hasAllFoldersSelected
          ? "All folders are currently selected for backup.\nYou can manually select folders you want to backup or continue for now, and change your folder selection later."
          : "No folders are currently selected for backup.\nYou can manually select folders you want to backup or continue for now, and change your folder selection later.",
    );

    if (result?.action == null || result!.action == ButtonAction.cancel) {
      return false;
    }

    if (result.action == ButtonAction.first) {
      final bool? selected = await handleFolderSelectionBackupFlow(context);
      if (selected != true) {
        return false;
      }
    } else if (result.action == ButtonAction.second) {
      await backupPreferenceService.setHasManualFolderSelection(true);
    }

    return true;
  }
}
