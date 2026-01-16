import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/notification_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import 'package:photos/ui/components/toggle_switch_widget.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

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
                AppLocalizations.of(context).notifications,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context)
                            .sharedPhotoNotifications,
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                              .sharedPhotoNotificationsExplanation,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).onThisDayMemories,
                        trailingWidget: ToggleSwitchWidget(
                          value: () =>
                              NotificationService.instance
                                  .hasGrantedPermissions() &&
                              localSettings.isOnThisDayNotificationsEnabled,
                          onChanged: () async {
                            await NotificationService.instance
                                .requestPermissions();
                            await memoriesCacheService
                                .toggleOnThisDayNotifications();
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
                          AppLocalizations.of(context)
                              .onThisDayNotificationExplanation,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).birthdays,
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                              .receiveRemindersOnBirthdays,
                          style: textTheme.mini
                              .copyWith(color: colorScheme.textMuted),
                        ),
                      ),
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
}
