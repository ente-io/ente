import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';

class LightThemesScreen extends StatefulWidget {
  const LightThemesScreen({Key? key}) : super(key: key);

  @override
  State<LightThemesScreen> createState() => _LightThemesScreenState();
}

class _LightThemesScreenState extends State<LightThemesScreen> {
  ThemeOptions? currentThemeOption;

  @override
  void initState() {
    super.initState();
    currentThemeOption = context.read<ThemeProvider>().currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Themes'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.light, 'Default Light'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.greenLight, 'Green Light'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.redLight, 'Red Light'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.blueLight, 'Blue Light'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.yellowLight, 'Yellow Light'),
          sectionOptionSpacing,
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, ThemeOptions themeOption, String themeName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: themeName,
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: currentThemeOption == themeOption ? Icons.check : null,
      trailingExtraMargin: 4,
      onTap: () async {
        await themeProvider.setTheme(themeOption, context);
        setState(() {
          currentThemeOption = themeOption;
        });
      },
    );
  }
} 