import "package:adaptive_theme/adaptive_theme.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";

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
        debugPrint("theme value $value");
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
      leadingIcon: HugeIcons.strokeRoundedSun01,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        _menuItem(context, AdaptiveThemeMode.system),
        _menuItem(context, AdaptiveThemeMode.dark),
        _menuItem(context, AdaptiveThemeMode.light),
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
    final colorScheme = getEnteColorScheme(context);
    return ExpandableChildItem(
      title: _name(context, themeMode),
      trailingIcon: currentThemeMode == themeMode ? Icons.check : null,
      trailingIconColor: colorScheme.primary500,
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
