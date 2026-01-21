import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/settings/about/about_us_page.dart";
import "package:photos/ui/settings/account/account_settings_page.dart";
import "package:photos/ui/settings/appearance/appearance_settings_page.dart";
import "package:photos/ui/settings/backup/backup_settings_page.dart";
import "package:photos/ui/settings/backup/free_space_options.dart";
import "package:photos/ui/settings/gallery_settings_screen.dart";
import "package:photos/ui/settings/ml/machine_learning_settings_page.dart";
import "package:photos/ui/settings/search/settings_search_item.dart";
import "package:photos/ui/settings/security/security_settings_page.dart";
import "package:photos/ui/settings/support/help_support_page.dart";

/// Registry that provides all searchable settings items
class SettingsSearchRegistry {
  static List<SettingsSearchItem> getSearchableItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLoggedIn = Configuration.instance.isLoggedIn();
    final items = <SettingsSearchItem>[];

    // Account settings
    if (hasLoggedIn) {
      items.add(
        SettingsSearchItem(
          title: l10n.account,
          sectionPath: l10n.account,
          icon: HugeIcons.strokeRoundedUser,
          routeBuilder: (_) => const AccountSettingsPage(),
          keywords: ["email", "password", "delete", "subscription"],
        ),
      );
    }

    // Backup settings
    if (hasLoggedIn) {
      items.add(
        SettingsSearchItem(
          title: l10n.backup,
          sectionPath: l10n.backup,
          icon: HugeIcons.strokeRoundedCloudUpload,
          routeBuilder: (_) => const BackupSettingsPage(),
          keywords: ["sync", "upload", "photos", "videos"],
        ),
      );
    }

    // Security settings
    items.add(
      SettingsSearchItem(
        title: l10n.security,
        sectionPath: l10n.security,
        icon: HugeIcons.strokeRoundedSecurityCheck,
        routeBuilder: (_) => const SecuritySettingsPage(),
        keywords: [
          "lock",
          "pin",
          "biometric",
          "fingerprint",
          "face id",
          "2fa",
          "two factor",
          "authentication",
          "recovery key",
        ],
      ),
    );

    // Appearance settings
    items.add(
      SettingsSearchItem(
        title: l10n.appearance,
        sectionPath: l10n.appearance,
        icon: HugeIcons.strokeRoundedPaintBoard,
        routeBuilder: (_) => const AppearanceSettingsPage(),
        keywords: ["theme", "dark mode", "light mode", "app icon"],
      ),
    );

    // Gallery settings (under Appearance)
    items.add(
      SettingsSearchItem(
        title: l10n.gallery,
        subtitle: l10n.appearance,
        sectionPath: "${l10n.appearance} > ${l10n.gallery}",
        icon: HugeIcons.strokeRoundedDashboardSquare02,
        routeBuilder: (_) => const GallerySettingsScreen(
          fromGalleryLayoutSettingsCTA: false,
        ),
        isSubPage: true,
        keywords: ["grid size", "group by", "layout"],
      ),
    );

    // Grid Size setting
    items.add(
      SettingsSearchItem(
        title: l10n.photoGridSize,
        subtitle: l10n.gallery,
        sectionPath: "${l10n.appearance} > ${l10n.gallery}",
        icon: HugeIcons.strokeRoundedDashboardSquare02,
        routeBuilder: (_) => const GallerySettingsScreen(
          fromGalleryLayoutSettingsCTA: false,
        ),
        isSubPage: true,
        keywords: ["grid", "size", "columns", "thumbnail"],
      ),
    );

    // Group By setting
    items.add(
      SettingsSearchItem(
        title: l10n.groupBy,
        subtitle: l10n.gallery,
        sectionPath: "${l10n.appearance} > ${l10n.gallery}",
        icon: HugeIcons.strokeRoundedDashboardSquare02,
        routeBuilder: (_) => const GallerySettingsScreen(
          fromGalleryLayoutSettingsCTA: false,
        ),
        isSubPage: true,
        keywords: ["group", "day", "month", "year"],
      ),
    );

    // Machine Learning settings
    if (hasLoggedIn) {
      items.add(
        SettingsSearchItem(
          title: l10n.machineLearning,
          sectionPath: l10n.machineLearning,
          icon: HugeIcons.strokeRoundedMagicWand01,
          routeBuilder: (_) => const MachineLearningSettingsPage(),
          keywords: [
            "ml",
            "ai",
            "faces",
            "people",
            "magic search",
            "similar images",
            "duplicates",
          ],
        ),
      );
    }

    // Free up space
    if (hasLoggedIn) {
      items.add(
        SettingsSearchItem(
          title: l10n.freeUpSpace,
          sectionPath: l10n.freeUpSpace,
          icon: HugeIcons.strokeRoundedRocket01,
          routeBuilder: (_) => const FreeUpSpaceOptionsScreen(),
          keywords: [
            "storage",
            "space",
            "clean",
            "delete",
            "local",
            "device",
          ],
        ),
      );

      // Remove duplicates (under Free up space)
      items.add(
        SettingsSearchItem(
          title: l10n.removeDuplicates,
          subtitle: l10n.freeUpSpace,
          sectionPath: l10n.freeUpSpace,
          icon: HugeIcons.strokeRoundedRocket01,
          routeBuilder: (_) => const FreeUpSpaceOptionsScreen(),
          isSubPage: true,
          keywords: [
            "duplicate",
            "duplicates",
            "same",
            "identical",
            "copy",
            "copies",
          ],
        ),
      );

      // Similar images (under Free up space)
      items.add(
        SettingsSearchItem(
          title: l10n.similarImages,
          subtitle: l10n.freeUpSpace,
          sectionPath: l10n.freeUpSpace,
          icon: HugeIcons.strokeRoundedRocket01,
          routeBuilder: (_) => const FreeUpSpaceOptionsScreen(),
          isSubPage: true,
          keywords: [
            "similar",
            "alike",
            "resembling",
            "cleanup",
          ],
        ),
      );
    }

    // Help & Support
    items.add(
      SettingsSearchItem(
        title: l10n.support,
        sectionPath: l10n.support,
        icon: HugeIcons.strokeRoundedHelpCircle,
        routeBuilder: (_) => const HelpSupportPage(),
        keywords: ["help", "faq", "contact", "feedback", "bug"],
      ),
    );

    // About
    items.add(
      SettingsSearchItem(
        title: l10n.about,
        sectionPath: l10n.about,
        icon: HugeIcons.strokeRoundedInformationCircle,
        routeBuilder: (_) => const AboutUsPage(),
        keywords: ["version", "privacy", "terms", "license"],
      ),
    );

    return items;
  }

  /// Get suggestions shown when search is empty
  static List<SettingsSearchSuggestion> getSuggestions(
    BuildContext context,
    void Function(Widget Function(BuildContext) routeBuilder) onNavigate,
  ) {
    final l10n = AppLocalizations.of(context);
    final hasLoggedIn = Configuration.instance.isLoggedIn();

    return [
      // Gallery suggestion
      SettingsSearchSuggestion(
        title: l10n.gallery,
        onTap: () => onNavigate(
          (_) => const GallerySettingsScreen(
            fromGalleryLayoutSettingsCTA: false,
          ),
        ),
      ),
      // App lock suggestion
      SettingsSearchSuggestion(
        title: l10n.appLock,
        onTap: () => onNavigate((_) => const SecuritySettingsPage()),
      ),
      // Free up device space suggestion
      if (hasLoggedIn)
        SettingsSearchSuggestion(
          title: l10n.freeUpDeviceSpace,
          onTap: () => onNavigate((_) => const FreeUpSpaceOptionsScreen()),
        ),
      // Backup settings suggestion
      if (hasLoggedIn)
        SettingsSearchSuggestion(
          title: l10n.backupSettings,
          onTap: () => onNavigate((_) => const BackupSettingsPage()),
        ),
    ];
  }
}
