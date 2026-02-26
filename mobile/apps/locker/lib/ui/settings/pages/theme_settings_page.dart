import "package:adaptive_theme/adaptive_theme.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  AdaptiveThemeMode? currentThemeMode;

  @override
  void initState() {
    super.initState();
    AdaptiveTheme.getThemeMode().then((value) {
      currentThemeMode = value ?? AdaptiveThemeMode.system;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleBarTitleWidget(title: l10n.theme),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.systemTheme,
                showChevron: false,
                trailing: currentThemeMode == AdaptiveThemeMode.system
                    ? Icon(Icons.check, color: colorScheme.primary700)
                    : null,
                onTap: () => _setTheme(AdaptiveThemeMode.system),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.lightTheme,
                showChevron: false,
                trailing: currentThemeMode == AdaptiveThemeMode.light
                    ? Icon(Icons.check, color: colorScheme.primary700)
                    : null,
                onTap: () => _setTheme(AdaptiveThemeMode.light),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.darkTheme,
                showChevron: false,
                trailing: currentThemeMode == AdaptiveThemeMode.dark
                    ? Icon(Icons.check, color: colorScheme.primary700)
                    : null,
                onTap: () => _setTheme(AdaptiveThemeMode.dark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setTheme(AdaptiveThemeMode themeMode) async {
    AdaptiveTheme.of(context).setThemeMode(themeMode);
    currentThemeMode = themeMode;
    if (mounted) {
      setState(() {});
    }
  }
}
