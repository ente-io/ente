import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";

class CollageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CollageAppBar({
    super.key,
    required this.onSave,
    this.isSaveEnabled = true,
  });

  final VoidCallback onSave;
  final bool isSaveEnabled;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: textTheme.body,
            ),
          ),
          TextButton(
            onPressed: isSaveEnabled ? onSave : null,
            child: Text(
              AppLocalizations.of(context).saveCollage,
              style: textTheme.body.copyWith(
                color: isSaveEnabled
                    ? colorScheme.primary500
                    : colorScheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
