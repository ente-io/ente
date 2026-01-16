import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class SettingsItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;
  final Color? iconColor;
  final bool showChevron;

  const SettingsItem({
    this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.textColor,
    this.iconColor,
    this.showChevron = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              HugeIcon(
                icon: icon,
                color: iconColor ?? colorScheme.strokeBase,
                size: 24,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: textTheme.body.copyWith(
                  color: textColor ?? colorScheme.textBase,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && showChevron)
              Icon(
                Icons.chevron_right,
                color: colorScheme.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
