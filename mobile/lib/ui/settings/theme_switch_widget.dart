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
  ThemeOptions? currentThemeOption;

  @override
  void initState() {
    super.initState();
    currentThemeOption = context.read<ThemeProvider>().currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        currentThemeOption = themeProvider.currentTheme;  // Update current theme
        return ExpandableMenuItemWidget(
          title: S.of(context).theme,
          selectionOptionsWidget: _getSectionOptions(context),
          leadingIcon: Theme.of(context).brightness == Brightness.light
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        );
      },
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        _menuItem(
          context, 
          ThemeOptions.system, 
          S.of(context).systemTheme,
          Icons.brightness_auto,
        ),
        sectionOptionSpacing,
        _navigationItem(
          context, 
          'Light Themes', 
          Icons.light_mode,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LightThemesScreen()),
            );
          },
        ),
        sectionOptionSpacing,
        _navigationItem(
          context, 
          'Dark Themes',
          Icons.dark_mode,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DarkThemesScreen()),
            );
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Widget _navigationItem(
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

  Widget _menuItem(
    BuildContext context, 
    ThemeOptions themeOption, 
    String themeName,
    [IconData? leadingIcon,]
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isSelected = themeOption == currentThemeOption && 
                      (themeOption == ThemeOptions.system || 
                       !_isCustomTheme(currentThemeOption!));
    
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: themeName,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: isSelected ? Icons.check : null,
      trailingExtraMargin: 4,
      leadingIcon: leadingIcon,
      onTap: () async {
        await themeProvider.setTheme(themeOption, context);
        setState(() {
          currentThemeOption = themeOption;
        });
      },
    );
  }

  bool _isCustomTheme(ThemeOptions theme) {
    return theme != ThemeOptions.system && 
           theme != ThemeOptions.light && 
           theme != ThemeOptions.dark;
  }
}