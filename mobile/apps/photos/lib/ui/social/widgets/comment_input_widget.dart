import "package:flutter/material.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/social/widgets/reply_preview_widget.dart";

class CommentInputWidget extends StatelessWidget {
  final Comment? replyingTo;
  final VoidCallback? onDismissReply;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const CommentInputWidget({
    this.replyingTo,
    this.onDismissReply,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottomPadding > 0
            ? bottomPadding
            : MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        border: Border(top: BorderSide(color: colorScheme.strokeFaint)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              ReplyPreviewWidget(
                replyingTo: replyingTo!,
                onDismiss: onDismissReply!,
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Say something nice!",
                      hintStyle: textTheme.body.copyWith(
                        color: colorScheme.textMuted,
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: colorScheme.fillFaint,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
