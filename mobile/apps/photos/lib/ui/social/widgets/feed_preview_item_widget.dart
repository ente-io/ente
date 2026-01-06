import "package:flutter/material.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";

class FeedPreviewItemWidget extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;
  final Map<String, String> anonDisplayNames;
  final VoidCallback? onTap;

  const FeedPreviewItemWidget({
    required this.feedItem,
    required this.currentUserID,
    this.anonDisplayNames = const {},
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Overlapping avatars with icon badge
          _PreviewAvatarStack(
            feedItem: feedItem,
            currentUserID: currentUserID,
            anonDisplayNames: anonDisplayNames,
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: _PreviewTextContent(
              feedItem: feedItem,
              currentUserID: currentUserID,
              anonDisplayNames: anonDisplayNames,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: 8),
          // Trailing chevron
          Icon(
            Icons.chevron_right,
            color: colorScheme.strokeMuted,
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// Displays overlapping avatars with feed type icon badge.
class _PreviewAvatarStack extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;
  final Map<String, String> anonDisplayNames;

  static const double _avatarSize = 44.0;
  static const double _iconSize = 27.0;
  static const double _overlap = 12.0;

  const _PreviewAvatarStack({
    required this.feedItem,
    required this.currentUserID,
    required this.anonDisplayNames,
  });

  @override
  Widget build(BuildContext context) {
    final actors = _getActors();
    final hasMultipleActors = actors.length > 1;
    final colorScheme = getEnteColorScheme(context);

    // Calculate total width needed
    final totalWidth = hasMultipleActors ? _avatarSize + _overlap : _avatarSize;
    final totalHeight =
        hasMultipleActors ? _avatarSize + _overlap : _avatarSize;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // First (top-left) avatar
          Positioned(
            left: 0,
            top: 0,
            child: _buildAvatar(actors.first, showBorder: false),
          ),
          // Second (bottom-right) avatar - only if multiple actors
          if (hasMultipleActors)
            Positioned(
              right: 0,
              bottom: 0,
              child: _buildAvatar(actors[1], showBorder: true),
            ),
          // Icon badge at bottom-left
          Positioned(
            left: -3,
            bottom: hasMultipleActors ? _overlap - 5 : -3,
            child: _FeedTypeIconBadge(
              type: feedItem.type,
              size: _iconSize,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user, {required bool showBorder}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 1.5,
              )
            : null,
      ),
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: ClipOval(
          child: UserAvatarWidget(
            user,
            type: AvatarType.xl,
            currentUserID: currentUserID,
            addStroke: false,
          ),
        ),
      ),
    );
  }

  List<User> _getActors() {
    final users = <User>[];
    final maxActors = feedItem.actorCount.clamp(1, 2);

    for (int i = 0; i < maxActors; i++) {
      final userID = feedItem.actorUserIDs[i];
      final anonID = feedItem.actorAnonIDs[i];

      if (userID <= 0 && anonID != null) {
        final displayName = anonDisplayNames[anonID] ?? anonID;
        users.add(
          User(
            id: userID,
            email: "$anonID@unknown.com",
            name: displayName,
          ),
        );
      } else {
        final user = CollectionsService.instance
            .getFileOwner(userID, feedItem.collectionID);
        users.add(user);
      }
    }

    return users;
  }
}

/// Icon badge for feed type (comment, like, etc.)
class _FeedTypeIconBadge extends StatelessWidget {
  final FeedItemType type;
  final double size;
  final EnteColorScheme colorScheme;

  const _FeedTypeIconBadge({
    required this.type,
    required this.size,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (type) {
      case FeedItemType.photoLike:
        return const Icon(
          Icons.favorite,
          size: 16,
          color: Color(0xFF00B33C),
        );
      case FeedItemType.comment:
        return Icon(
          Icons.chat_bubble,
          size: 14,
          color: colorScheme.textMuted,
        );
      case FeedItemType.reply:
        return Icon(
          Icons.reply,
          size: 16,
          color: colorScheme.textMuted,
        );
      case FeedItemType.commentLike:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.chat_bubble,
              size: 14,
              color: colorScheme.textMuted,
            ),
            const Positioned(
              right: -3,
              bottom: -3,
              child: Icon(
                Icons.favorite,
                size: 8,
                color: Color(0xFF00B33C),
              ),
            ),
          ],
        );
      case FeedItemType.replyLike:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.reply,
              size: 14,
              color: colorScheme.textMuted,
            ),
            const Positioned(
              right: -3,
              bottom: -3,
              child: Icon(
                Icons.favorite,
                size: 8,
                color: Color(0xFF00B33C),
              ),
            ),
          ],
        );
    }
  }
}

/// Text content for feed preview.
class _PreviewTextContent extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;
  final Map<String, String> anonDisplayNames;
  final EnteTextTheme textTheme;
  final EnteColorScheme colorScheme;

  const _PreviewTextContent({
    required this.feedItem,
    required this.currentUserID,
    required this.anonDisplayNames,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final primaryUser = _getPrimaryUser();
    final primaryName = primaryUser.displayName ?? primaryUser.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username row with "and X other(s)"
        _buildUsernameRow(context, primaryName),
        const SizedBox(height: 2),
        // Action description
        Text(
          _getActionDescription(context),
          style: textTheme.small.copyWith(
            color: colorScheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUsernameRow(BuildContext context, String primaryName) {
    if (!feedItem.hasMultipleActors) {
      return Text(
        primaryName,
        style: textTheme.small.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.textBase,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final othersCount = feedItem.additionalActorCount;
    final othersText = othersCount == 1
        ? AppLocalizations.of(context).and1Other
        : AppLocalizations.of(context).andXOthers(count: othersCount);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: primaryName,
            style: textTheme.small.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.textBase,
            ),
          ),
          TextSpan(
            text: " $othersText",
            style: textTheme.small.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.textMuted,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getActionDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (feedItem.type) {
      case FeedItemType.photoLike:
        return l10n.likedYourPhoto;
      case FeedItemType.comment:
        return l10n.commentedOnYourPhoto;
      case FeedItemType.reply:
        return l10n.repliedToYourComment;
      case FeedItemType.commentLike:
        return l10n.likedYourComment;
      case FeedItemType.replyLike:
        return l10n.likedYourReply;
    }
  }

  User _getPrimaryUser() {
    final userID = feedItem.primaryActorUserID;
    final anonID = feedItem.primaryActorAnonID;

    if (userID <= 0 && anonID != null) {
      final displayName = anonDisplayNames[anonID] ?? anonID;
      return User(
        id: userID,
        email: "$anonID@unknown.com",
        name: displayName,
      );
    }

    return CollectionsService.instance
        .getFileOwner(userID, feedItem.collectionID);
  }
}
