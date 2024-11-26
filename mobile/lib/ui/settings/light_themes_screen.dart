import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/settings/theme_selection_widget.dart';
import 'package:provider/provider.dart';

class LightThemesScreen extends StatelessWidget {
  const LightThemesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Light Themes'),
          ),
          body: Stack(
            children: [
              const ThemeSelectionWidget(
                isDark: false,
                themeGroups: [
                  ThemeGroup(
                    name: 'Default',
                    themes: [ThemeOptions.light],
                  ),
                  ThemeGroup(
                    name: 'Professional',
                    themes: [
                      ThemeOptions.slateLight,
                      ThemeOptions.indigoLight,
                    ],
                  ),
                  ThemeGroup(
                    name: 'Nature',
                    themes: [
                      ThemeOptions.greenLight,
                      ThemeOptions.emeraldLight,
                      ThemeOptions.tealLight,
                    ],
                  ),
                  ThemeGroup(
                    name: 'Warm',
                    themes: [
                      ThemeOptions.redLight,
                      ThemeOptions.orangeLight,
                      ThemeOptions.yellowLight,
                      ThemeOptions.mochaLight,
                    ],
                  ),
                  ThemeGroup(
                    name: 'Cool',
                    themes: [
                      ThemeOptions.blueLight,
                      ThemeOptions.aquaLight,
                    ],
                  ),
                  ThemeGroup(
                    name: 'Elegant',
                    themes: [
                      ThemeOptions.purpleLight,
                      ThemeOptions.roseLight,
                      ThemeOptions.lilacLight,
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