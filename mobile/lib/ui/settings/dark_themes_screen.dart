import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/settings/theme_selection_widget.dart';
import 'package:provider/provider.dart';

class DarkThemesScreen extends StatelessWidget {
  const DarkThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dark Themes'),
          ),
          body: Stack(
            children: [
              const ThemeSelectionWidget(
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
              if (themeProvider.isChangingTheme)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 