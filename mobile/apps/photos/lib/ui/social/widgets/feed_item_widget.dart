import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

/// Widget that displays a single feed item.
class FeedItemWidget extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;

  /// Called when the user taps anywhere on the feed item.
  final VoidCallback? onTap;

  /// Map of anonUserID -> decrypted display name for the collection.
  final Map<String, String> anonDisplayNames;

  /// Whether this is the last item in the feed (hides timeline line).
  final bool isLastItem;

  const FeedItemWidget({
    required this.feedItem,
    required this.currentUserID,
    this.onTap,
    this.anonDisplayNames = const {},
    this.isLastItem = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - tappable for comments
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row: Icon with timeline + Avatars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Feed type icon with timeline line
                      _FeedTypeIconWithTimeline(
                        type: feedItem.type,
                        showTimeline: !isLastItem,
                      ),
                      const SizedBox(width: 10),
                      // Stacked avatars
                      _StackedAvatars(
                        feedItem: feedItem,
                        currentUserID: currentUserID,
                        anonDisplayNames: anonDisplayNames,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Second row: Text content with left padding
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: _FeedTextContent(
                      feedItem: feedItem,
                      currentUserID: currentUserID,
                      anonDisplayNames: anonDisplayNames,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Photo thumbnail
          if (feedItem.fileID != null)
            GestureDetector(
              onTap: onTap,
              child: _FeedThumbnail(
                fileID: feedItem.fileID!,
                collectionID: feedItem.collectionID,
              ),
            )
          else
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(7.792),
              ),
            ),
        ],
      ),
    );
  }
}

/// Displays the feed type icon with optional timeline line passing through center.
///
/// The timeline line connects feed items vertically, passing through the icon center.
class _FeedTypeIconWithTimeline extends StatelessWidget {
  final FeedItemType type;
  final bool showTimeline;

  /// Height of the timeline line extending below the icon.
  /// Extends from icon center through text content and padding to next item's icon.
  static const double _timelineExtensionHeight = 95;

  /// Width of the dashed timeline line.
  static const double _timelineWidth = 1.5;

  const _FeedTypeIconWithTimeline({
    required this.type,
    required this.showTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    // Timeline color: black with 8% opacity for light, white with 20% for dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timelineColor =
        isDarkMode ? const Color(0x33FFFFFF) : const Color(0x14000000);

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline line (behind the icon) - dashed
          if (showTimeline)
            Positioned(
              left: (32 - _timelineWidth) / 2, // Center the line
              top: 16, // Start from icon center
              child: CustomPaint(
                size: const Size(_timelineWidth, _timelineExtensionHeight),
                painter: _DashedLinePainter(color: timelineColor),
              ),
            ),
          // Icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _buildIcon(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    switch (type) {
      case FeedItemType.photoLike:
        return const Icon(
          Icons.favorite,
          size: 18,
          color: Color(0xFF00B33C),
        );
      case FeedItemType.comment:
        return Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: getEnteColorScheme(context).textMuted,
        );
      case FeedItemType.reply:
        return Icon(
          Icons.reply,
          size: 18,
          color: getEnteColorScheme(context).textMuted,
        );
      case FeedItemType.commentLike:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: getEnteColorScheme(context).textMuted,
            ),
            const Positioned(
              right: -4,
              bottom: -4,
              child: Icon(
                Icons.favorite,
                size: 10,
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
              size: 18,
              color: getEnteColorScheme(context).textMuted,
            ),
            const Positioned(
              right: -4,
              bottom: -4,
              child: Icon(
                Icons.favorite,
                size: 10,
                color: Color(0xFF00B33C),
              ),
            ),
          ],
        );
    }
  }
}

/// Displays stacked user avatars (max 2, overlapping).
class _StackedAvatars extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;
  final Map<String, String> anonDisplayNames;

  const _StackedAvatars({
    required this.feedItem,
    required this.currentUserID,
    required this.anonDisplayNames,
  });

  @override
  Widget build(BuildContext context) {
    final actors = _getActors();
    final displayCount = actors.length.clamp(1, 2);

    if (displayCount == 1) {
      return _buildSingleAvatar(actors.first);
    }

    // Stacked avatars with overlap
    return SizedBox(
      width: 28 + 21, // First avatar + second avatar offset
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // First (front) avatar
          Positioned(
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.167,
                ),
              ),
              child: UserAvatarWidget(
                actors.first,
                type: AvatarType.lg,
                currentUserID: currentUserID,
                addStroke: false,
              ),
            ),
          ),
          // Second (back) avatar
          Positioned(
            left: 21, // Overlap by 7px (28 - 21 = 7)
            child: UserAvatarWidget(
              actors[1],
              type: AvatarType.lg,
              currentUserID: currentUserID,
              addStroke: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAvatar(User user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.167,
        ),
      ),
      child: UserAvatarWidget(
        user,
        type: AvatarType.lg,
        currentUserID: currentUserID,
        addStroke: false,
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
        // Anonymous user - use decrypted display name if available
        final displayName = anonDisplayNames[anonID] ?? anonID;
        users.add(
          User(
            id: userID,
            email: "$anonID@unknown.com",
            name: displayName,
          ),
        );
      } else {
        // Get user from collections service
        final user = CollectionsService.instance
            .getFileOwner(userID, feedItem.collectionID);
        users.add(user);
      }
    }

    return users;
  }
}

/// Displays the text content: usernames and action description.
class _FeedTextContent extends StatelessWidget {
  final FeedItem feedItem;
  final int currentUserID;
  final Map<String, String> anonDisplayNames;

  const _FeedTextContent({
    required this.feedItem,
    required this.currentUserID,
    required this.anonDisplayNames,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final primaryUser = _getPrimaryUser();
    final primaryName = primaryUser.displayName ?? primaryUser.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username row
        _buildUsernameRow(context, primaryName, textTheme, colorScheme),
        const SizedBox(height: 2),
        // Action description
        Text(
          _getActionDescription(context),
          style: textTheme.mini.copyWith(
            color: colorScheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUsernameRow(
    BuildContext context,
    String primaryName,
    EnteTextTheme textTheme,
    EnteColorScheme colorScheme,
  ) {
    if (!feedItem.hasMultipleActors) {
      // Single user
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

    // Multiple users: "Username and X others"
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
      // Anonymous user - use decrypted display name if available
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

/// Displays the photo thumbnail for the feed item.
class _FeedThumbnail extends StatefulWidget {
  final int fileID;
  final int collectionID;

  const _FeedThumbnail({
    required this.fileID,
    required this.collectionID,
  });

  @override
  State<_FeedThumbnail> createState() => _FeedThumbnailState();
}

class _FeedThumbnailState extends State<_FeedThumbnail> {
  EnteFile? _file;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(_FeedThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileID != widget.fileID ||
        oldWidget.collectionID != widget.collectionID) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() => _isLoading = true);
    final file = await FilesDB.instance.getUploadedFile(
      widget.fileID,
      widget.collectionID,
    );
    if (mounted) {
      setState(() {
        _file = file;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    if (_isLoading) {
      return Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(7.792),
        ),
      );
    }

    if (_file == null) {
      return Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(7.792),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.strokeMuted,
          size: 24,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7.792),
      child: SizedBox(
        width: 66,
        height: 66,
        child: ThumbnailWidget(
          _file!,
          fit: BoxFit.cover,
          rawThumbnail: true,
        ),
      ),
    );
  }
}

/// Custom painter for drawing a dashed vertical line.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  /// Dash length per Figma spec: 7.5px
  static const double _dashHeight = 7.5;

  /// Gap between dashes per Figma spec: 4.5px
  static const double _dashGap = 4.5;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, (startY + _dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += _dashHeight + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
