import 'package:flutter/material.dart';
// import 'package:photos/generated/l10n.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';

class DarkThemesScreen extends StatelessWidget {
  const DarkThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dark Themes'),
      ),
      body: ListView(
        children: [
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.dark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.slateDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.greenDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.emeraldDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.redDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.blueDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.yellowDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.purpleDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.orangeDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.tealDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.roseDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.indigoDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.mochaDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.aquaDark),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.lilacDark),
          sectionOptionSpacing,
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeOptions theme) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: _getThemeName(theme),
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: context.watch<ThemeProvider>().currentTheme == theme 
          ? Icons.check 
          : null,
      onTap: () async {
        final themeProvider = context.read<ThemeProvider>();
        if (!themeProvider.isChangingTheme) {
          await themeProvider.setTheme(theme, context);
        }
      },
    );
  }

  String _getThemeName(ThemeOptions theme) {
    switch (theme) {
      case ThemeOptions.dark:
        return 'Default Dark';
      case ThemeOptions.greenDark:
        return 'Green Dark';
      case ThemeOptions.redDark:
        return 'Red Dark';
      case ThemeOptions.blueDark:
        return 'Blue Dark';
      case ThemeOptions.yellowDark:
        return 'Yellow Dark';
      case ThemeOptions.purpleDark:
        return 'Purple Dark';
      case ThemeOptions.orangeDark:
        return 'Orange Dark';
      case ThemeOptions.tealDark:
        return 'Teal Dark';
      case ThemeOptions.roseDark:
        return 'Rose Dark';
      case ThemeOptions.indigoDark:
        return 'Indigo Dark';
      case ThemeOptions.mochaDark:
        return 'Mocha Dark';
      case ThemeOptions.aquaDark:
        return 'Aqua Dark';
      case ThemeOptions.lilacDark:
        return 'Lilac Dark';
      case ThemeOptions.emeraldDark:
        return 'Emerald Dark';
      case ThemeOptions.slateDark:
        return 'Slate Dark';
      default:
        return '';
    }
  }
} 