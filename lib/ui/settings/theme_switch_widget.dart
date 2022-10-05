// @dart=2.9

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';

class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({Key key}) : super(key: key);

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> {
  AdaptiveThemeMode currentThemeMode;
  final expandableController = ExpandableController(initialExpanded: false);

  @override
  void initState() {
    super.initState();
    AdaptiveTheme.getThemeMode().then(
      (value) {
        currentThemeMode = value ?? AdaptiveThemeMode.system;
        debugPrint('theme value $value');
        if (mounted) {
          setState(() => {});
        }
      },
    );
  }

  @override
  void dispose() {
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          text: "Theme",
          makeTextBold: true,
        ),
        isHeaderOfExpansion: true,
        leadingIcon: Theme.of(context).brightness == Brightness.light
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
        trailingIcon: Icons.expand_more,
        menuItemColor:
            Theme.of(context).colorScheme.enteTheme.colorScheme.fillFaint,
        expandableController: expandableController,
      ),
      collapsed: const SizedBox.shrink(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(context),
      controller: expandableController,
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

  Widget _menuItem(BuildContext context, AdaptiveThemeMode themeMode) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        text: toBeginningOfSentenceCase(themeMode.name),
        textStyle: Theme.of(context).colorScheme.enteTheme.textTheme.body,
      ),
      isHeaderOfExpansion: false,
      trailingIcon: currentThemeMode == themeMode ? Icons.check : null,
      onTap: () async {
        AdaptiveTheme.of(context).setThemeMode(themeMode);
        currentThemeMode = themeMode;
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
