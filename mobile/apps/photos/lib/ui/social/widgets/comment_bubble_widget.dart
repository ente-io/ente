import "package:flutter/material.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/social/widgets/comment_actions_capsule.dart";
import "package:photos/utils/social/relative_time_formatter.dart";

class CommentBubbleWidget extends StatefulWidget {
  final Comment comment;
  final bool isOwnComment;
  final int currentUserID;
  final int collectionID;
  final Future<Comment?> Function()? onFetchParent;
  final Future<List<Reaction>> Function() onFetchReactions;
  final VoidCallback onReplyTap;

  const CommentBubbleWidget({
    required this.comment,
    required this.isOwnComment,
    required this.currentUserID,
    required this.collectionID,
    this.onFetchParent,
    required this.onFetchReactions,
    required this.onReplyTap,
    super.key,
  });

  @override
  State<CommentBubbleWidget> createState() => _CommentBubbleWidgetState();
}

class _CommentBubbleWidgetState extends State<CommentBubbleWidget> {
  Comment? _parentComment;
  List<Reaction> _reactions = [];
  bool _isLiked = false;
  bool _isLoadingParent = false;
  bool _isLoadingReactions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(CommentBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comment.id != oldWidget.comment.id) {
      _parentComment = null;
      _reactions = [];
      _isLiked = false;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // Load parent if reply
    if (widget.comment.isReply && widget.onFetchParent != null) {
      setState(() => _isLoadingParent = true);
      _parentComment = await widget.onFetchParent!();
      if (mounted) setState(() => _isLoadingParent = false);
    }

    // Load reactions
    setState(() => _isLoadingReactions = true);
    _reactions = await widget.onFetchReactions();
    _isLiked = _reactions.any(
      (r) => r.userID == widget.currentUserID && !r.isDeleted,
    );
    if (mounted) setState(() => _isLoadingReactions = false);
  }

  Future<void> _toggleLike() async {
    // Optimistic update
    setState(() => _isLiked = !_isLiked);

    await SocialDataProvider.instance.toggleReaction(
      userID: widget.currentUserID,
      collectionID: widget.collectionID,
      commentID: widget.comment.id,
    );

    // Refresh reactions
    _reactions = await widget.onFetchReactions();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final bubbleTextColor =
        widget.isOwnComment ? colorScheme.backgroundBase : colorScheme.textBase;
    final bubbleBackgroundColor =
        widget.isOwnComment ? colorScheme.primary500 : colorScheme.fillBaseGrey;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isOwnComment ? 48 : 20,
        right: widget.isOwnComment ? 20 : 48,
        top: 12,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: widget.isOwnComment
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              formatRelativeTime(widget.comment.createdAt),
              style: textTheme.mini.copyWith(color: colorScheme.textMuted),
            ),
          ),
          _buildBubble(
            colorScheme: colorScheme,
            textTheme: textTheme,
            textColor: bubbleTextColor,
            bubbleColor: bubbleBackgroundColor,
          ),
          if (!_isLoadingReactions) ...[
            const SizedBox(height: 2),
            Transform.translate(
              offset: const Offset(0, -12),
              child: Align(
                alignment: widget.isOwnComment
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: CommentActionsCapsule(
                  isLiked: _isLiked,
                  likeCount: _reactions.where((r) => !r.isDeleted).length,
                  onLikeTap: _toggleLike,
                  onReplyTap: widget.onReplyTap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble({
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
    required Color textColor,
    required Color bubbleColor,
  }) {
    final bubbleBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(widget.isOwnComment ? 18 : 10),
      bottomRight: Radius.circular(widget.isOwnComment ? 10 : 18),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: bubbleBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.comment.isReply)
            _buildInlineParent(
              colorScheme: colorScheme,
              textTheme: textTheme,
              textColor: textColor,
            ),
          Text(
            widget.comment.data,
            style: textTheme.body.copyWith(
              color: textColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineParent({
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
    required Color textColor,
  }) {
    if (_isLoadingParent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 16,
        width: 16,
        alignment: Alignment.centerLeft,
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final parentText = _parentComment?.data ?? "Original comment unavailable";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: widget.isOwnComment
                ? colorScheme.backgroundBase.withValues(alpha: 0.6)
                : colorScheme.strokeMuted,
            width: 2,
          ),
        ),
      ),
      child: Text(
        parentText,
        style: textTheme.small.copyWith(
          color: widget.isOwnComment
              ? colorScheme.backgroundBase.withValues(alpha: 0.9)
              : colorScheme.textMuted,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
