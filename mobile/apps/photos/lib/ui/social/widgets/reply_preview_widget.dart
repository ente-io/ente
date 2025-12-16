import "package:flutter/material.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/theme/ente_theme.dart";

class ReplyPreviewWidget extends StatelessWidget {
  final Comment replyingTo;
  final User replyingToUser;
  final VoidCallback onDismiss;

  const ReplyPreviewWidget({
    required this.replyingTo,
    required this.replyingToUser,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF8C8C8C),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Replying to ${replyingToUser.displayName ?? replyingToUser.email}",
                  style: textTheme.small.copyWith(color: colorScheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  replyingTo.data,
                  style: textTheme.mini.copyWith(color: colorScheme.textFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// GestureDetector(
//             onTap: onDismiss,
//             child: Icon(
//               Icons.close,
//               size: 18,
//               color: colorScheme.textMuted,
//             ),
//           ),
