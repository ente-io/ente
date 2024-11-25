import 'package:flutter/material.dart';
// import 'package:photos/generated/l10n.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';

class LightThemesScreen extends StatelessWidget {
  const LightThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Themes'),
      ),
      body: ListView(
        children: [
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.light),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.slateLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.greenLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.emeraldLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.redLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.blueLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.yellowLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.purpleLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.orangeLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.tealLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.roseLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.indigoLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.mochaLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.aquaLight),
          sectionOptionSpacing,
          _buildThemeOption(context, ThemeOptions.lilacLight),
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
      case ThemeOptions.light:
        return 'Default Light';
      case ThemeOptions.greenLight:
        return 'Green Light';
      case ThemeOptions.redLight:
        return 'Red Light';
      case ThemeOptions.blueLight:
        return 'Blue Light';
      case ThemeOptions.yellowLight:
        return 'Yellow Light';
      case ThemeOptions.purpleLight:
        return 'Purple Light';
      case ThemeOptions.orangeLight:
        return 'Orange Light';
      case ThemeOptions.tealLight:
        return 'Teal Light';
      case ThemeOptions.roseLight:
        return 'Rose Light';
      case ThemeOptions.indigoLight:
        return 'Indigo Light';
      case ThemeOptions.mochaLight:
        return 'Mocha Light';
      case ThemeOptions.aquaLight:
        return 'Aqua Light';
      case ThemeOptions.lilacLight:
        return 'Lilac Light';
      case ThemeOptions.emeraldLight:
        return 'Emerald Light';
      case ThemeOptions.slateLight:
        return 'Slate Light';
      default:
        return '';
    }
  }
} 