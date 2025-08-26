import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/notification_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import "package:photos/ui/settings/common_settings.dart";

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).notifications,
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
                                    .sharedPhotoNotifications,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () =>
                                    NotificationService.instance
                                        .hasGrantedPermissions() &&
                                    NotificationService.instance
                                        .shouldShowNotificationsForSharedPhotos(),
                                onChanged: () async {
                                  await NotificationService.instance
                                      .requestPermissions();
                                  await NotificationService.instance
                                      .setShouldShowNotificationsForSharedPhotos(
                                    !NotificationService.instance
                                        .shouldShowNotificationsForSharedPhotos(),
                                  );
                                },
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isGestureDetectorDisabled: true,
                            ),
                            MenuSectionDescriptionWidget(
                              content: AppLocalizations.of(context)
                                  .sharedPhotoNotificationsExplanation,
                            ),
                            sectionOptionSpacing,
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: AppLocalizations.of(context)
                                    .onThisDayMemories,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () =>
                                    NotificationService.instance
                                        .hasGrantedPermissions() &&
                                    localSettings
                                        .isOnThisDayNotificationsEnabled,
                                onChanged: () async {
                                  await NotificationService.instance
                                      .requestPermissions();
                                  await memoriesCacheService
                                      .toggleOnThisDayNotifications();
                                },
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isGestureDetectorDisabled: true,
                            ),
                            MenuSectionDescriptionWidget(
                              content: AppLocalizations.of(context)
                                  .onThisDayNotificationExplanation,
                            ),
                            sectionOptionSpacing,
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: AppLocalizations.of(context).birthdays,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: ToggleSwitchWidget(
                                value: () =>
                                    NotificationService.instance
                                        .hasGrantedPermissions() &&
                                    localSettings.birthdayNotificationsEnabled,
                                onChanged: () async {
                                  await NotificationService.instance
                                      .requestPermissions();
                                  await memoriesCacheService
                                      .toggleBirthdayNotifications();
                                },
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              isGestureDetectorDisabled: true,
                            ),
                            MenuSectionDescriptionWidget(
                              content: AppLocalizations.of(context)
                                  .receiveRemindersOnBirthdays,
                            ),
                          ],
                        ),
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
