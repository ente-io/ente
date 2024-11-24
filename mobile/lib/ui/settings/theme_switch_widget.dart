import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/dark_themes_screen.dart';
import 'package:photos/ui/settings/light_themes_screen.dart';
import 'package:provider/provider.dart';

class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({Key? key}) : super(key: key);

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> {
  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, ThemeOptions>(
      selector: (_, provider) => provider.currentTheme,
      builder: (context, currentTheme, _) {
        return ExpandableMenuItemWidget(
          title: S.of(context).theme,
          selectionOptionsWidget: _getSectionOptions(context, currentTheme),
          leadingIcon: Theme.of(context).brightness == Brightness.light
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        );
      },
    );
  }

  Widget _getSectionOptions(BuildContext context, ThemeOptions currentTheme) {
    return Column(
      children: [
        sectionOptionSpacing,
        _buildSystemThemeOption(context, currentTheme),
        sectionOptionSpacing,
        _buildThemeNavigationOption(
          context,
          'Light Themes',
          Icons.light_mode,
          () async => _navigateToThemeScreen(context, const LightThemesScreen()),
        ),
        sectionOptionSpacing,
        _buildThemeNavigationOption(
          context,
          'Dark Themes',
          Icons.dark_mode,
          () async => _navigateToThemeScreen(context, const DarkThemesScreen()),
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Widget _buildSystemThemeOption(BuildContext context, ThemeOptions currentTheme) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: S.of(context).systemTheme,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: currentTheme == ThemeOptions.system ? Icons.check : null,
      trailingExtraMargin: 4,
      leadingIcon: Icons.brightness_auto,
      onTap: () async {
        final themeProvider = context.read<ThemeProvider>();
        if (!themeProvider.isChangingTheme) {
          await themeProvider.setTheme(ThemeOptions.system, context);
        }
      },
    );
  }

  Widget _buildThemeNavigationOption(
    BuildContext context,
    String title,
    IconData icon,
    Future<void> Function() onTap,
  ) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: title,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: Icons.chevron_right,
      trailingExtraMargin: 4,
      leadingIcon: icon,
      onTap: onTap,
    );
  }

  Future<void> _navigateToThemeScreen(BuildContext context, Widget screen) async {
    if (!context.read<ThemeProvider>().isChangingTheme) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
}