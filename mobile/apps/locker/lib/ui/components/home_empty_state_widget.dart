import "package:dotted_border/dotted_border.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import 'package:locker/l10n/l10n.dart';

class HomeEmptyStateWidget extends StatelessWidget {
  const HomeEmptyStateWidget({
    super.key,
    this.isSyncing = false,
  });

  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final title =
        isSyncing ? context.l10n.syncing : context.l10n.homeLockerEmptyTitle;
    final subtitle = isSyncing ? null : context.l10n.homeLockerEmptySubtitle;
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        strokeWidth: 1,
        color: colorScheme.textFaint,
        dashPattern: const [5, 5],
        radius: const Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isSyncing
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary700,
                    ),
                  )
                : Image.asset(
                    'assets/upload_file.png',
                  ),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.h3Bold.copyWith(
                color: colorScheme.textBase,
              ),
            ),
            if (subtitle != null) const SizedBox(height: 8),
            if (subtitle != null)
              Text(
                subtitle,
                style: textTheme.small.copyWith(
                  color: colorScheme.primary700,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
