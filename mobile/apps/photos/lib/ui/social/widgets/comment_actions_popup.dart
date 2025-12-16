import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class CommentActionsPopup extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;

  const CommentActionsPopup({
    required this.isLiked,
    required this.onLikeTap,
    required this.onReplyTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionItem(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: isLiked ? const Color(0xFFE25454) : null,
                  label: "Like",
                  onTap: onLikeTap,
                  textStyle: textTheme.body,
                  defaultIconColor: colorScheme.textBase,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.strokeFaint,
                ),
                _ActionItem(
                  icon: Icons.reply,
                  label: "Reply",
                  onTap: onReplyTap,
                  textStyle: textTheme.body,
                  defaultIconColor: colorScheme.textBase,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;
  final TextStyle textStyle;
  final Color defaultIconColor;

  const _ActionItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
    required this.textStyle,
    required this.defaultIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? defaultIconColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: textStyle.copyWith(
                color: defaultIconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
