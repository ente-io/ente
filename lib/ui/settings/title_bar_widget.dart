import 'package:ente_auth/l10n/l10n.dart';
import 'package:flutter/material.dart';

class SettingsTitleBarWidget extends StatelessWidget {
  const SettingsTitleBarWidget({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
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
            Text(l10n.settings),
          ],
        ),
      ),
    );
  }
}
