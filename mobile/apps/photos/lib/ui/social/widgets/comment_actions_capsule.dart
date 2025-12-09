import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class CommentActionsCapsule extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;

  const CommentActionsCapsule({
    required this.isLiked,
    required this.likeCount,
    required this.onLikeTap,
    required this.onReplyTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
        border: Border.all(color: colorScheme.strokeFaint),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onLikeTap,
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color:
                      isLiked ? colorScheme.primary500 : colorScheme.textMuted,
                ),
                if (likeCount > 0) ...[
                  const SizedBox(width: 2),
                  Text(
                    likeCount.toString(),
                    style: textTheme.mini.copyWith(
                      color: colorScheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onReplyTap,
            child: Icon(
              Icons.reply,
              size: 18,
              color: colorScheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
