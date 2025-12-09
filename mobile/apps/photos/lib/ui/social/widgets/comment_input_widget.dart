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
            TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Say something nice!",
                hintStyle: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: colorScheme.fillFaint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: onSend,
                    child: Icon(
                      Icons.send,
                      color: colorScheme.textMuted,
                      size: 22,
                    ),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 36),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.strokeFaint),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.strokeMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
