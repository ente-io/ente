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

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isOwnComment ? 48 : 16,
        right: widget.isOwnComment ? 16 : 48,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: widget.isOwnComment
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Parent quote (if reply)
          if (widget.comment.isReply) _buildParentQuote(colorScheme, textTheme),

          // Comment bubble
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isOwnComment
                  ? colorScheme.primary500.withValues(alpha: 0.15)
                  : colorScheme.fillFaint,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.isOwnComment ? 16 : 4),
                bottomRight: Radius.circular(widget.isOwnComment ? 4 : 16),
              ),
            ),
            child: Text(
              widget.comment.data,
              style: textTheme.body,
            ),
          ),

          const SizedBox(height: 4),

          // Timestamp and actions row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatRelativeTime(widget.comment.createdAt),
                style: textTheme.mini.copyWith(color: colorScheme.textMuted),
              ),
              const SizedBox(width: 8),
              if (!_isLoadingReactions)
                CommentActionsCapsule(
                  isLiked: _isLiked,
                  likeCount: _reactions.where((r) => !r.isDeleted).length,
                  onLikeTap: _toggleLike,
                  onReplyTap: widget.onReplyTap,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentQuote(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    if (_isLoadingParent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final parentText = _parentComment?.data ?? "Original comment unavailable";

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary500,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Text(
        parentText,
        style: textTheme.small.copyWith(color: colorScheme.textMuted),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
