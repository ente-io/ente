import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/ui/settings/pages/settings_search_page.dart";

class DrawerTitleBarWidget extends StatelessWidget {
  const DrawerTitleBarWidget({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onPressed: () {
                scaffoldKey.currentState?.closeDrawer();
              },
              icon: const Icon(Icons.keyboard_double_arrow_left_outlined),
            ),
            IconButton(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onPressed: () => _openSearch(context),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: colorScheme.textBase,
                size: 20,
                strokeWidth: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsSearchPage()),
    );
  }
}
