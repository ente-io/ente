import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/colors.dart';
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

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ExpandableMenuItemWidget(
        title: S.of(context).theme,
        selectionOptionsWidget: _getSectionOptions(context),
        leadingIcon: Theme.of(context).brightness == Brightness.light
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        _buildSystemThemeOption(context),
        sectionOptionSpacing,
        _buildThemeNavigationOption(
          context,
          'Light Themes',
          Icons.light_mode,
          () async => _navigateToThemeScreen(context, const LightThemesScreen()),
          ThemeOptions.light,
        ),
        sectionOptionSpacing,
        _buildThemeNavigationOption(
          context,
          'Dark Themes',
          Icons.dark_mode,
          () async => _navigateToThemeScreen(context, const DarkThemesScreen()),
          ThemeOptions.dark,
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Widget _buildSystemThemeOption(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: S.of(context).systemTheme,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: colorScheme.fillFaint,
      isExpandable: false,
      trailingIcon: context.watch<ThemeProvider>().currentTheme == ThemeOptions.system 
          ? Icons.check 
          : null,
      leadingIcon: Icons.brightness_auto,
      onTap: () async {
        final themeProvider = context.read<ThemeProvider>();
        if (!themeProvider.isChangingTheme) {
          _controller.reverse();
          await Future.delayed(const Duration(milliseconds: 150));
          await themeProvider.setTheme(ThemeOptions.system, context);
          _controller.forward();
        }
      },
    );
  }

  Widget _buildThemeNavigationOption(
    BuildContext context,
    String title,
    IconData icon,
    Future<void> Function() onTap,
    ThemeOptions previewTheme,
  ) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: title,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: Icons.chevron_right,
      leadingIcon: icon,
      onTap: onTap,
    );
  }

  Color _getPreviewColor(ThemeOptions theme) {
    final colorScheme = _getPreviewColorScheme(theme);
    return colorScheme.primary500;
  }

  EnteColorScheme _getPreviewColorScheme(ThemeOptions theme) {
    switch (theme) {
      case ThemeOptions.system:
        return Theme.of(context).brightness == Brightness.light 
            ? getEnteColorScheme(context) 
            : getEnteColorScheme(context, inverse: true);
      case ThemeOptions.light:
        return getEnteColorScheme(context);
      case ThemeOptions.dark:
        return getEnteColorScheme(context, inverse: true);
      default:
        return getEnteColorScheme(context);
    }
  }

  Future<void> _navigateToThemeScreen(BuildContext context, Widget screen) async {
    if (!context.read<ThemeProvider>().isChangingTheme) {
      _controller.reverse();
      await Future.delayed(const Duration(milliseconds: 150));
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
      _controller.forward();
    }
  }
}