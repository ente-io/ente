import 'package:flutter/material.dart';
// import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/ente_theme_provider.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:provider/provider.dart';

class ThemeSelectionWidget extends StatefulWidget {
  final List<ThemeGroup> themeGroups;
  final bool isDark;

  const ThemeSelectionWidget({
    required this.themeGroups,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  State<ThemeSelectionWidget> createState() => _ThemeSelectionWidgetState();
}

class _ThemeSelectionWidgetState extends State<ThemeSelectionWidget> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: widget.themeGroups.length,
            itemBuilder: (context, index) {
              final group = widget.themeGroups[index];
              final filteredThemes = group.themes.where((theme) => 
                _getThemeName(theme).toLowerCase().contains(_searchQuery.toLowerCase()),
              ).toList();
              
              if (filteredThemes.isEmpty) return const SizedBox.shrink();
              
              return _buildThemeGroup(group.name, filteredThemes);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search themes',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: getEnteColorScheme(context).fillFaint,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildThemeGroup(String title, List<ThemeOptions> themes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title,
            style: getEnteTextTheme(context).small.copyWith(
              color: getEnteColorScheme(context).textMuted,
            ),
          ),
        ),
        ...themes.map((theme) => _buildThemeOption(context, theme)),
        sectionOptionSpacing,
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeOptions theme) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: _getThemeName(theme),
        textStyle: getEnteTextTheme(context).body,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      isExpandable: false,
      trailingIcon: context.watch<ThemeProvider>().currentTheme == theme 
          ? Icons.check 
          : null,
      leadingIcon: Icons.palette,
      onTap: () async {
        final themeProvider = context.read<ThemeProvider>();
        if (!themeProvider.isChangingTheme) {
          await themeProvider.setTheme(theme, context);
        }
      },
    );
  }

  Color _getPreviewColor(ThemeOptions theme) {
    if (widget.isDark) {
      return getEnteColorScheme(context, inverse: true).primary500;
    }
    return getEnteColorScheme(context).primary500;
  }

  String _getThemeName(ThemeOptions theme) {
    switch (theme) {
      case ThemeOptions.light:
        return 'Default Light';
      case ThemeOptions.dark:
        return 'Default Dark';
      case ThemeOptions.greenLight:
        return 'Green Light';
      case ThemeOptions.greenDark:
        return 'Green Dark';
      case ThemeOptions.redLight:
        return 'Red Light';
      case ThemeOptions.redDark:
        return 'Red Dark';
      case ThemeOptions.blueLight:
        return 'Blue Light';
      case ThemeOptions.blueDark:
        return 'Blue Dark';
      case ThemeOptions.yellowLight:
        return 'Yellow Light';
      case ThemeOptions.yellowDark:
        return 'Yellow Dark';
      case ThemeOptions.purpleLight:
        return 'Purple Light';
      case ThemeOptions.purpleDark:
        return 'Purple Dark';
      case ThemeOptions.orangeLight:
        return 'Orange Light';
      case ThemeOptions.orangeDark:
        return 'Orange Dark';
      case ThemeOptions.tealLight:
        return 'Teal Light';
      case ThemeOptions.tealDark:
        return 'Teal Dark';
      case ThemeOptions.roseLight:
        return 'Rose Light';
      case ThemeOptions.roseDark:
        return 'Rose Dark';
      case ThemeOptions.indigoLight:
        return 'Indigo Light';
      case ThemeOptions.indigoDark:
        return 'Indigo Dark';
      case ThemeOptions.mochaLight:
        return 'Mocha Light';
      case ThemeOptions.mochaDark:
        return 'Mocha Dark';
      case ThemeOptions.aquaLight:
        return 'Aqua Light';
      case ThemeOptions.aquaDark:
        return 'Aqua Dark';
      case ThemeOptions.lilacLight:
        return 'Lilac Light';
      case ThemeOptions.lilacDark:
        return 'Lilac Dark';
      case ThemeOptions.emeraldLight:
        return 'Emerald Light';
      case ThemeOptions.emeraldDark:
        return 'Emerald Dark';
      case ThemeOptions.slateLight:
        return 'Slate Light';
      case ThemeOptions.slateDark:
        return 'Slate Dark';
      default:
        return '';
    }
  }
}

class ThemeGroup {
  final String name;
  final List<ThemeOptions> themes;

  const ThemeGroup({
    required this.name,
    required this.themes,
  });
} 