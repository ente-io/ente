import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/theme/ente_theme.dart';

class DeviceFoldersEmptyState extends StatelessWidget {
  const DeviceFoldersEmptyState({super.key});

  static const Color _selectFoldersGreen = Color(0xFF08C225);

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/ducky_folders.png",
              width: 138,
              height: 120,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context).selectFolders,
                      style: textTheme.small.copyWith(
                        color: _selectFoldersGreen,
                      ),
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context).toViewAndBackupOnEnte,
                      style: textTheme.smallMuted,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
