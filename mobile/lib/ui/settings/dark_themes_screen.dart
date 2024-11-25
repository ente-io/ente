import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/settings/theme_selection_widget.dart';

class DarkThemesScreen extends StatelessWidget {
  const DarkThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dark Themes'),
      ),
      body: ThemeSelectionWidget(
        isDark: true,
        themeGroups: [
          ThemeGroup(
            name: 'Default',
            themes: [ThemeOptions.dark],
          ),
          ThemeGroup(
            name: 'Professional',
            themes: [
              ThemeOptions.slateDark,
              ThemeOptions.indigoDark,
            ],
          ),
          ThemeGroup(
            name: 'Nature',
            themes: [
              ThemeOptions.greenDark,
              ThemeOptions.emeraldDark,
              ThemeOptions.tealDark,
            ],
          ),
          ThemeGroup(
            name: 'Warm',
            themes: [
              ThemeOptions.redDark,
              ThemeOptions.orangeDark,
              ThemeOptions.yellowDark,
              ThemeOptions.mochaDark,
            ],
          ),
          ThemeGroup(
            name: 'Cool',
            themes: [
              ThemeOptions.blueDark,
              ThemeOptions.aquaDark,
            ],
          ),
          ThemeGroup(
            name: 'Elegant',
            themes: [
              ThemeOptions.purpleDark,
              ThemeOptions.roseDark,
              ThemeOptions.lilacDark,
            ],
          ),
        ],
      ),
    );
  }
} 