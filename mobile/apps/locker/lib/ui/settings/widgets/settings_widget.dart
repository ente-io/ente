import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildChildrenWithSpacing(),
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];
    if (children.length == 1) return children;

    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}

class SettingsOptionWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;
  final bool showChevron;

  const SettingsOptionWidget({
    required this.title,
    this.onTap,
    this.trailing,
    this.textColor,
    this.showChevron = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final borderRadius = BorderRadius.circular(20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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

class SettingsItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;
  final Color? iconColor;
  final bool showChevron;

  const SettingsItem({
    required this.icon,
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
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: iconColor ?? colorScheme.strokeBase,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

