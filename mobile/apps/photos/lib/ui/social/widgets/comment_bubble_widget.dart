import "package:flutter/material.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/social/widgets/comment_actions_capsule.dart";
import "package:photos/utils/social/relative_time_formatter.dart";

class CommentBubbleWidget extends StatefulWidget {
  final Comment comment;
  final User user;
  final bool isOwnComment;
  final int currentUserID;
  final int collectionID;
  final Future<Comment?> Function()? onFetchParent;
  final Future<List<Reaction>> Function() onFetchReactions;
  final VoidCallback onReplyTap;

  const CommentBubbleWidget({
    required this.comment,
    required this.user,
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
    return Padding(
      padding: EdgeInsets.only(
        right: widget.isOwnComment ? 24 : 0,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: widget.isOwnComment
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _Header(
            isOwnComment: widget.isOwnComment,
            user: widget.user,
            createdAt: widget.comment.createdAt,
            currentUserID: widget.currentUserID,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(left: widget.isOwnComment ? 0 : 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _CommentBubble(
                  comment: widget.comment,
                  isOwnComment: widget.isOwnComment,
                  isLoadingParent: _isLoadingParent,
                  parentComment: _parentComment,
                ),
                if (!_isLoadingReactions)
                  Positioned(
                    right: -16,
                    bottom: -17,
                    child: CommentActionsCapsule(
                      isLiked: _isLiked,
                      onLikeTap: _toggleLike,
                      onReplyTap: widget.onReplyTap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineParentQuote extends StatelessWidget {
  final bool isLoading;
  final Comment? parentComment;
  final bool isOwnComment;

  const _InlineParentQuote({
    required this.isLoading,
    required this.parentComment,
    required this.isOwnComment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    if (isLoading) {
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

    final parentText = parentComment?.data ?? "Original comment unavailable";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isOwnComment
                ? textBaseDark.withValues(alpha: 0.6)
                : colorScheme.strokeMuted,
            width: 2,
          ),
        ),
      ),
      child: Text(
        parentText,
        style: textTheme.tiny.copyWith(
          height: 1.7,
          color: isOwnComment
              ? textBaseDark.withValues(alpha: 0.9)
              : colorScheme.textMuted,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isOwnComment;
  final bool isLoadingParent;
  final Comment? parentComment;

  const _CommentBubble({
    required this.comment,
    required this.isOwnComment,
    required this.isLoadingParent,
    required this.parentComment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final textColor = isOwnComment ? textBaseDark : colorScheme.textBase;
    final bubbleColor =
        isOwnComment ? const Color(0xFF0DAF35) : colorScheme.fillBaseGrey;

    final bubbleBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(isOwnComment ? 20 : 6),
      topRight: Radius.circular(isOwnComment ? 6 : 20),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: bubbleBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comment.isReply)
            _InlineParentQuote(
              isLoading: isLoadingParent,
              parentComment: parentComment,
              isOwnComment: isOwnComment,
            ),
          Text(
            comment.data,
            style: textTheme.small.copyWith(
              color: textColor,
              height: 22 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isOwnComment;
  final User user;
  final int createdAt;
  final int currentUserID;

  const _Header({
    required this.isOwnComment,
    required this.user,
    required this.createdAt,
    required this.currentUserID,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final name = user.displayName ?? user.email;
    final timestamp = formatRelativeTime(createdAt);

    if (isOwnComment) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          timestamp,
          style: textTheme.tiny.copyWith(
            color: colorScheme.textMuted,
            height: 14 / 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final baseNameStyle = textTheme.small.copyWith(
      color: colorScheme.textMuted,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
    );

    final headerText = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: name, style: baseNameStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '•',
                style: baseNameStyle.copyWith(
                  fontSize: (baseNameStyle.fontSize ?? 14) * 0.65,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextSpan(
            text: timestamp,
            style: textTheme.tiny.copyWith(
              color: colorScheme.textMuted,
              height: 14 / 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );

    return Row(
      mainAxisAlignment:
          isOwnComment ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        if (!isOwnComment) ...[
          UserAvatarWidget(
            user,
            currentUserID: currentUserID,
            type: AvatarType.small,
          ),
          const SizedBox(width: 10),
          Flexible(child: headerText),
        ] else ...[
          Flexible(child: headerText),
          const SizedBox(width: 10),
          UserAvatarWidget(
            user,
            currentUserID: currentUserID,
            type: AvatarType.small,
          ),
        ],
      ],
    );
  }
}
