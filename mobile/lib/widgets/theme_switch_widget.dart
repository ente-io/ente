// import 'package:adaptive_theme/adapt adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
    return ExpandableMenuItemWidget(
      title: S.of(context).theme,
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
        _menuItem(context, ThemeOptions.system, S.of(context).systemTheme),
        sectionOptionSpacing,
        _menuItem(context, ThemeOptions.light, S.of(context).lightTheme),
        sectionOptionSpacing,
        _menuItem(context, ThemeOptions.dark, S.of(context).darkTheme),
        sectionOptionSpacing,
        _menuItem(context, ThemeOptions.greenLight, 'Green Light Theme'),
        sectionOptionSpacing,
        _menuItem(context, ThemeOptions.redDark, 'Red Dark Theme'),
        sectionOptionSpacing,
      ],
    );
  }

  Widget _menuItem(BuildContext context, ThemeOptions themeOption, String themeName) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: themeName,
        textStyle: Theme.of(context).colorScheme.enteTheme.textTheme.body,
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