import "package:flutter/material.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/social/widgets/reply_preview_widget.dart";

class CommentInputWidget extends StatelessWidget {
  final Comment? replyingTo;
  final User? replyingToUser;
  final VoidCallback? onDismissReply;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const CommentInputWidget({
    this.replyingTo,
    this.replyingToUser,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textFieldFillColor =
        isDarkMode ? const Color(0xFF212121) : const Color(0xFFF3F3F3);
    final textFieldBorderColor = isDarkMode
        ? colorScheme.backgroundBase
        : const Color(0xFF000000).withValues(alpha: 0.02);

    return Container(
      padding: const EdgeInsets.only(
        bottom: 20,
        left: 18,
        right: 18,
        top: 20,
      ),
      color: colorScheme.backgroundBase,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: textFieldFillColor,
            border: Border.all(
              color: textFieldBorderColor,
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyingTo != null && replyingToUser != null)
                ReplyPreviewWidget(
                  replyingTo: replyingTo!,
                  replyingToUser: replyingToUser!,
                  onDismiss: onDismissReply!,
                ),
              TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                textAlignVertical: TextAlignVertical.center,
                style: textTheme.body.copyWith(
                  height: 15 / 16,
                  letterSpacing: -0.32,
                  color: colorScheme.textBase.withValues(alpha: 0.8),
                ),
                decoration: InputDecoration(
                  hintText: "Say something nice!",
                  hintStyle: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: onSend,
                      child: Icon(
                        Icons.send_rounded,
                        color: colorScheme.textBase.withValues(alpha: 0.8),
                        size: 24,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
