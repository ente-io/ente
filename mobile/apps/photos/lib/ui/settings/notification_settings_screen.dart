import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/notification_service.dart";
import "package:photos/ui/settings/components/settings_item.dart";
import "package:photos/ui/settings/components/settings_page_scaffold.dart";

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showOnlyOnThisDay = isLocalGalleryMode;

    return SettingsPageScaffold(
      title: l10n.notifications,
      children: [
        if (!showOnlyOnThisDay) ...[
          _buildNotificationToggleItem(
            context,
            title: l10n.sharedPhotoNotifications,
            subtitle: l10n.sharedPhotoNotificationsExplanation,
            value: () =>
                NotificationService.instance.hasGrantedPermissions() &&
                NotificationService.instance
                    .shouldShowNotificationsForSharedPhotosAndAlbums(),
            onChanged: () async {
              await NotificationService.instance.requestPermissions();
              await NotificationService.instance
                  .setShouldShowNotificationsForSharedPhotosAndAlbums(
                    !NotificationService.instance
                        .shouldShowNotificationsForSharedPhotosAndAlbums(),
                  );
            },
          ),
          const SizedBox(height: 8),
          _buildNotificationToggleItem(
            context,
            title: l10n.socialNotifications,
            subtitle: l10n.socialNotificationsExplanation,
            value: () =>
                NotificationService.instance.hasGrantedPermissions() &&
                NotificationService.instance.shouldShowSocialNotifications(),
            onChanged: () async {
              await NotificationService.instance.requestPermissions();
              await NotificationService.instance
                  .setShouldShowSocialNotifications(
                    !NotificationService.instance
                        .shouldShowSocialNotifications(),
                  );
            },
          ),
          const SizedBox(height: 8),
        ],
        _buildNotificationToggleItem(
          context,
          title: l10n.onThisDayMemories,
          subtitle: l10n.onThisDayNotificationExplanation,
          value: () =>
              NotificationService.instance.hasGrantedPermissions() &&
              localSettings.isOnThisDayNotificationsEnabled,
          onChanged: () async {
            await NotificationService.instance.requestPermissions();
            await memoriesCacheService.toggleOnThisDayNotifications();
          },
        ),
        if (!showOnlyOnThisDay) ...[
          const SizedBox(height: 8),
          _buildNotificationToggleItem(
            context,
            title: l10n.birthdays,
            subtitle: l10n.receiveRemindersOnBirthdays,
            value: () =>
                NotificationService.instance.hasGrantedPermissions() &&
                localSettings.birthdayNotificationsEnabled,
            onChanged: () async {
              await NotificationService.instance.requestPermissions();
              await memoriesCacheService.toggleBirthdayNotifications();
            },
          ),
        ],
      ],
    );
  }

  SettingsItem _buildNotificationToggleItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool Function() value,
    required Future<void> Function() onChanged,
  }) {
    return SettingsItem(
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 2,
      showChevron: false,
      trailing: ToggleSwitchComponent.async(
        value: value,
        onChanged: onChanged,
        showStateIcon: false,
      ),
    );
  }
}
