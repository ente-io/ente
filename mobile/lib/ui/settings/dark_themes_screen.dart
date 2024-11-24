import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';

class DarkThemesScreen extends StatefulWidget {
  const DarkThemesScreen({Key? key}) : super(key: key);

  @override
  State<DarkThemesScreen> createState() => _DarkThemesScreenState();
}

class _DarkThemesScreenState extends State<DarkThemesScreen> {
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
        title: const Text('Dark Themes'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.dark, 'Default Dark'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.greenDark, 'Green Dark'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.redDark, 'Red Dark'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.blueDark, 'Blue Dark'),
          sectionOptionSpacing,
          _menuItem(context, ThemeOptions.yellowDark, 'Yellow Dark'),
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