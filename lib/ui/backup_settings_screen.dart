import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
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
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Backup settings",
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
                              captionedTextWidget: const CaptionedTextWidget(
                                title: "Backup over mobile data",
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingSwitch: ToggleSwitchWidget(
                                value: () {
                                  return Configuration.instance
                                      .shouldBackupOverMobileData();
                                },
                                onChanged: () async {
                                  await Configuration.instance
                                      .setBackupOverMobileData(
                                    !Configuration.instance
                                        .shouldBackupOverMobileData(),
                                  );
                                },
                              ),
                              borderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isBottomBorderRadiusRemoved: true,
                              isGestureDetectorDisabled: true,
                            ),
                            DividerWidget(
                              dividerType: DividerType.menuNoIcon,
                              bgColor: colorScheme.fillFaint,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: "Backup videos",
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingSwitch: ToggleSwitchWidget(
                                value: () =>
                                    Configuration.instance.shouldBackupVideos(),
                                onChanged: () => Configuration.instance
                                    .setShouldBackupVideos(
                                  !Configuration.instance.shouldBackupVideos(),
                                ),
                              ),
                              borderRadius: 8,
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
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Disable auto lock",
                                    ),
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingSwitch: ToggleSwitchWidget(
                                      value: () => Configuration.instance
                                          .shouldKeepDeviceAwake(),
                                      onChanged: () {
                                        return Configuration.instance
                                            .setShouldKeepDeviceAwake(
                                          !Configuration.instance
                                              .shouldKeepDeviceAwake(),
                                        );
                                      },
                                    ),
                                    borderRadius: 8,
                                    alignCaptionedTextToLeft: true,
                                    isGestureDetectorDisabled: true,
                                  ),
                                  const MenuSectionDescriptionWidget(
                                    content:
                                        "Disable the device screen lock when ente is in the foreground and there is a backup in progress. This is normally not needed, but may help big uploads and initial imports of large libraries complete faster.",
                                  )
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
