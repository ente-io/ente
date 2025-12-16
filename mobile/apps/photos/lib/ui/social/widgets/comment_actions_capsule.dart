import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class CommentActionsCapsule extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;

  const CommentActionsCapsule({
    required this.isLiked,
    required this.onLikeTap,
    required this.onReplyTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F7);
    final iconColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF131313);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: colorScheme.backgroundBase,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(42),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onLikeTap,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isLiked ? const Color(0xFF08C225) : iconColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReplyTap,
            child: Icon(
              Icons.reply,
              size: 18,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
