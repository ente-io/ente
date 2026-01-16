import "dart:io";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/app.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/settings/app_icon_selection_screen.dart";
import "package:photos/ui/settings/gallery_settings_screen.dart";
import "package:photos/ui/settings/language_picker.dart";

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  AdaptiveThemeMode? _currentThemeMode;

  @override
  void initState() {
    super.initState();
    AdaptiveTheme.getThemeMode().then((value) {
      _currentThemeMode = value ?? AdaptiveThemeMode.system;
      if (mounted) {
        setState(() {});
      }
    });
  }

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
                AppLocalizations.of(context).appearance,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (Platform.isAndroid || kDebugMode) ...[
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).theme,
                          leadingIconWidget: _buildIconWidget(
                            context,
                            isDarkMode
                                ? HugeIcons.strokeRoundedMoon02
                                : HugeIcons.strokeRoundedSun03,
                          ),
                          trailingIcon: Icons.chevron_right_outlined,
                          trailingIconIsMuted: true,
                          onTap: () async => _showThemePicker(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                      MenuItemWidgetNew(
                        title: context.l10n.appIcon,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedImage02,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const AppIconSelectionScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).language,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedTranslation,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => _onLanguageTap(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).gallery,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedImage01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const GallerySettingsScreen(
                              fromGalleryLayoutSettingsCTA: false,
                            ),
                          );
                        },
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

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.strokeBase,
      size: 20,
    );
  }

  Future<void> _showThemePicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ThemePickerSheet(
        currentThemeMode: _currentThemeMode,
        onThemeChanged: (themeMode) {
          AdaptiveTheme.of(context).setThemeMode(themeMode);
          setState(() {
            _currentThemeMode = themeMode;
          });
        },
      ),
    );
  }

  Future<void> _onLanguageTap(BuildContext context) async {
    final locale = (await getLocale())!;
    await routeToPage(
      context,
      LanguageSelectorPage(
        appSupportedLocales,
        (locale) async {
          await setLocale(locale);
          EnteApp.setLocale(context, locale);
        },
        locale,
      ),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  final AdaptiveThemeMode? currentThemeMode;
  final Function(AdaptiveThemeMode) onThemeChanged;

  const _ThemePickerSheet({
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final sheetColor =
        isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.strokeMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).theme,
            style: textTheme.largeBold,
          ),
          const SizedBox(height: 16),
          _ThemeOption(
            title: AppLocalizations.of(context).lightTheme,
            isSelected: currentThemeMode == AdaptiveThemeMode.light,
            onTap: () {
              onThemeChanged(AdaptiveThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            title: AppLocalizations.of(context).darkTheme,
            isSelected: currentThemeMode == AdaptiveThemeMode.dark,
            onTap: () {
              onThemeChanged(AdaptiveThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            title: AppLocalizations.of(context).systemTheme,
            isSelected: currentThemeMode == AdaptiveThemeMode.system,
            onTap: () {
              onThemeChanged(AdaptiveThemeMode.system);
              Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return ListTile(
      title: Text(
        title,
        style: textTheme.body,
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: colorScheme.primary500,
            )
          : null,
      onTap: onTap,
    );
  }
}
