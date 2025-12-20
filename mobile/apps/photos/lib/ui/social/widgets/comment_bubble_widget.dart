import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/social/widgets/comment_actions_capsule.dart";
import "package:photos/ui/social/widgets/comment_actions_popup.dart";
import "package:photos/ui/social/widgets/delete_comment_confirmation_dialog.dart";
import "package:photos/utils/social/relative_time_formatter.dart";

final _logger = Logger("CommentBubbleWidget");

class CommentBubbleWidget extends StatefulWidget {
  final Comment comment;
  final User user;
  final bool isOwnComment;
  final int currentUserID;
  final int collectionID;
  final Future<Comment?> Function()? onFetchParent;
  final Future<List<Reaction>> Function() onFetchReactions;
  final VoidCallback onReplyTap;
  final User Function(Comment) userResolver;
  final VoidCallback? onCommentDeleted;

  const CommentBubbleWidget({
    required this.comment,
    required this.user,
    required this.isOwnComment,
    required this.currentUserID,
    required this.collectionID,
    this.onFetchParent,
    required this.onFetchReactions,
    required this.onReplyTap,
    required this.userResolver,
    this.onCommentDeleted,
    super.key,
  });

  @override
  State<CommentBubbleWidget> createState() => _CommentBubbleWidgetState();
}

class _CommentBubbleWidgetState extends State<CommentBubbleWidget>
    with TickerProviderStateMixin {
  Comment? _parentComment;
  List<Reaction> _reactions = [];
  bool _isLiked = false;
  bool _isLoadingParent = false;
  bool _isLoadingReactions = false;

  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _contentKey = GlobalKey();

  late final AnimationController _overlayAnimationController;
  late final Animation<double> _overlayAnimation;
  late final AnimationController _capsuleAnimationController;
  late final Animation<double> _capsuleAnimation;

  @override
  void initState() {
    super.initState();
    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _capsuleAnimationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 200),
    );
    _capsuleAnimation = CurvedAnimation(
      parent: _capsuleAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _overlayAnimationController.addStatusListener(_onOverlayAnimationStatus);
    _loadData();
  }

  void _onOverlayAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _capsuleAnimationController.forward();
    }
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

  @override
  void dispose() {
    _overlayAnimationController.removeStatusListener(_onOverlayAnimationStatus);
    _overlayAnimationController.dispose();
    _capsuleAnimationController.dispose();
    super.dispose();
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

  void _showHighlight() {
    HapticFeedback.mediumImpact();
    _capsuleAnimationController.value = 0;
    _overlayController.show();
    _overlayAnimationController.forward();
  }

  Future<void> _hideHighlight() async {
    await _overlayAnimationController.reverse();
    if (mounted) _overlayController.hide();
  }

  Future<void> _handleDelete() async {
    await _hideHighlight();
    if (!mounted) return;

    final confirmed = await showDeleteCommentConfirmationDialog(context);

    if (confirmed == true) {
      try {
        await SocialDataProvider.instance.deleteComment(widget.comment.id);
        if (mounted) {
          showShortToast(context, "Comment deleted");
          widget.onCommentDeleted?.call();
        }
      } catch (e) {
        _logger.severe("Failed to delete comment", e);
        if (mounted) {
          showShortToast(context, "Failed to delete comment");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlayContent,
        child: GestureDetector(
          onLongPress: _showHighlight,
          child: AnimatedBuilder(
            animation: _capsuleAnimation,
            builder: (context, _) {
              return KeyedSubtree(
                key: _contentKey,
                child: _buildCommentContent(
                  showActionsCapsule: true,
                  capsuleOpacity: _capsuleAnimation.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    // Get original widget size for perfect alignment
    final renderBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;

    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, _) {
        final value = _overlayAnimation.value;
        final isReversing =
            _overlayAnimationController.status == AnimationStatus.reverse;
        return Stack(
          children: [
            // Full-screen barrier with black opacity 0.7
            GestureDetector(
              onTap: _hideHighlight,
              child: Container(
                color: Colors.black.withValues(alpha: 0.7 * value),
              ),
            ),
            // Highlighted comment + popup menu
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              child: SizedBox(
                width: size?.width,
                child: Opacity(
                  opacity: isReversing ? 1.0 : value,
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: widget.isOwnComment ? 16 : 0),
                    child: _buildCommentContent(
                      showActionsCapsule: false,
                      showActionsPopup: true,
                      showHeader: false,
                      bubbleScale: 1 + (0.025 * value),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentContent({
    required bool showActionsCapsule,
    bool showActionsPopup = false,
    bool includePadding = true,
    bool showHeader = true,
    double bubbleScale = 1.0,
    double capsuleOpacity = 1.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        right: widget.isOwnComment ? 6 : 0,
        top: includePadding ? 8 : 0,
        bottom: includePadding ? 8 : 0,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: widget.isOwnComment
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: showHeader ? 1 : 0,
              child: Padding(
                padding: EdgeInsets.only(
                  right: widget.isOwnComment ? 18 : 0,
                ),
                child: _Header(
                  isOwnComment: widget.isOwnComment,
                  user: widget.user,
                  createdAt: widget.comment.createdAt,
                  currentUserID: widget.currentUserID,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: widget.isOwnComment ? 0 : 24),
              child: Transform.scale(
                scale: bubbleScale,
                alignment: widget.isOwnComment
                    ? Alignment.topRight
                    : Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Padding(
                          padding: showActionsCapsule
                              ? const EdgeInsets.only(right: 16, bottom: 17)
                              : EdgeInsets.zero,
                          child: _CommentBubble(
                            comment: widget.comment,
                            isOwnComment: widget.isOwnComment,
                            isLoadingParent: _isLoadingParent,
                            parentComment: _parentComment,
                            currentUserID: widget.currentUserID,
                            userResolver: widget.userResolver,
                          ),
                        ),
                        if (!_isLoadingReactions && showActionsCapsule)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: capsuleOpacity,
                              child: CommentActionsCapsule(
                                isLiked: _isLiked,
                                onLikeTap: _toggleLike,
                                onReplyTap: widget.onReplyTap,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (showActionsPopup)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: CommentActionsPopup(
                          isLiked: _isLiked,
                          onLikeTap: () {
                            _hideHighlight();
                            _toggleLike();
                          },
                          onReplyTap: () {
                            _hideHighlight();
                            widget.onReplyTap();
                          },
                          onDeleteTap: _handleDelete,
                          showDelete: widget.isOwnComment,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineParentQuote extends StatelessWidget {
  final bool isLoading;
  final Comment? parentComment;
  final bool isOwnComment;
  final int currentUserID;
  final User Function(Comment) userResolver;

  const _InlineParentQuote({
    required this.isLoading,
    required this.parentComment,
    required this.isOwnComment,
    required this.currentUserID,
    required this.userResolver,
  });

  @override
  Widget build(BuildContext context) {
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
    final parentUser =
        parentComment != null ? userResolver(parentComment!) : null;
    final parentAuthor = parentComment != null
        ? (parentUser!.id == currentUserID
            ? 'You'
            : (parentUser.displayName ?? parentUser.email))
        : null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lineColor = isOwnComment
        ? (isDarkMode ? const Color(0x33000000) : const Color(0xFF08571C))
        : const Color(0xFF8C8C8C);

    final parentAuthorTextColor = isOwnComment
        ? textBaseDark
        : isDarkMode
            ? const Color(0xCCFFFFFF)
            : const Color(0xCC000000);

    final parentTextColor = isOwnComment
        ? const Color(0xCCFFFFFF)
        : isDarkMode
            ? const Color(0xB3FFFFFF)
            : const Color(0xB3000000);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (parentAuthor != null)
                    Text(
                      parentAuthor,
                      style: textTheme.mini.copyWith(
                        color: parentAuthorTextColor,
                        height: 20 / 12,
                        letterSpacing: -0.24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    parentText,
                    style: textTheme.tiny.copyWith(
                      height: 17 / 10,
                      letterSpacing: -0.3,
                      color: parentTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isOwnComment;
  final bool isLoadingParent;
  final Comment? parentComment;
  final int currentUserID;
  final User Function(Comment) userResolver;

  const _CommentBubble({
    required this.comment,
    required this.isOwnComment,
    required this.isLoadingParent,
    required this.parentComment,
    required this.currentUserID,
    required this.userResolver,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final textColor = isOwnComment ? textBaseDark : colorScheme.textBase;
    final bubbleColor = isOwnComment
        ? (isDarkMode ? const Color(0xFF056C1F) : const Color(0xFF0DAF35))
        : isDarkMode
            ? const Color(0xFF212121)
            : const Color(0xFFF0F0F0);

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
              currentUserID: currentUserID,
              userResolver: userResolver,
            ),
          Text(
            comment.data,
            style: textTheme.small.copyWith(
              color: textColor,
              height: 22 / 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.28,
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
            type: AvatarType.lg,
            thumbnailView: true,
            addStroke: false,
          ),
          const SizedBox(width: 10),
          Flexible(child: headerText),
        ] else ...[
          Flexible(child: headerText),
          const SizedBox(width: 10),
          UserAvatarWidget(
            user,
            currentUserID: currentUserID,
            type: AvatarType.lg,
            thumbnailView: true,
            addStroke: false,
          ),
        ],
      ],
    );
  }
}
