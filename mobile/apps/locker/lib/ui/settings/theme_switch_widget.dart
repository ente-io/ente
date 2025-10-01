import "package:adaptive_theme/adaptive_theme.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/ente_theme_data.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/settings/common_settings.dart";

class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({super.key});

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> {
  AdaptiveThemeMode? currentThemeMode;

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
    super.dispose();
  }

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
        AdaptiveTheme.of(context).setThemeMode(themeMode);
        currentThemeMode = themeMode;
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
