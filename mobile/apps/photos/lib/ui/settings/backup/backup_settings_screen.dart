import "dart:io";

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wake_lock_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

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
                                  flagService.enableMobMultiPart,
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
}
