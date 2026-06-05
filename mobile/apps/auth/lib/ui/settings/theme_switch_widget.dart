import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/auth_theme_preferences.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:flutter/material.dart';

class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({super.key});

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: context.l10n.theme,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Theme.of(context).brightness == Brightness.light
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        _menuItem(context, AdaptiveThemeMode.light),
        sectionOptionSpacing,
        _menuItem(context, AdaptiveThemeMode.dark),
        sectionOptionSpacing,
        _menuItem(context, AdaptiveThemeMode.system),
        sectionOptionSpacing,
      ],
    );
  }

  String _name(BuildContext ctx, AdaptiveThemeMode mode) {
    switch (mode) {
      case AdaptiveThemeMode.light:
        return ctx.l10n.lightTheme;
      case AdaptiveThemeMode.dark:
        return ctx.l10n.darkTheme;
      case AdaptiveThemeMode.system:
        return ctx.l10n.systemTheme;
    }
  }

  Widget _menuItem(BuildContext context, AdaptiveThemeMode themeMode) {
    final currentThemeMode = AdaptiveTheme.of(context).mode;
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: _name(context, themeMode),
        textStyle: Theme.of(context).colorScheme.enteTheme.textTheme.body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: currentThemeMode == themeMode ? Icons.check : null,
      trailingExtraMargin: 4,
      onTap: () async {
        final adaptiveTheme = AdaptiveTheme.of(context);
        final appLock = AppLock.of(context);
        await AuthThemePreferences.setThemeMode(adaptiveTheme, themeMode);
        appLock?.setThemeMode(_themeMode(themeMode));
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  ThemeMode _themeMode(AdaptiveThemeMode themeMode) {
    if (themeMode.isLight) return ThemeMode.light;
    if (themeMode.isDark) return ThemeMode.dark;
    return ThemeMode.system;
  }
}
