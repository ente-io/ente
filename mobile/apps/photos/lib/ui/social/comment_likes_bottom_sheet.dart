import "package:flutter/material.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";

const _shrinkWrapThreshold = 30;

/// Shows the likes bottom sheet for a comment
Future<void> showCommentLikesBottomSheet(
  BuildContext context, {
  required List<Reaction> reactions,
  required int collectionID,
  required int currentUserID,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentLikesBottomSheet(
      reactions: reactions,
      collectionID: collectionID,
      currentUserID: currentUserID,
    ),
  );
}

class CommentLikesBottomSheet extends StatefulWidget {
  final List<Reaction> reactions;
  final int collectionID;
  final int currentUserID;

  const CommentLikesBottomSheet({
    required this.reactions,
    required this.collectionID,
    required this.currentUserID,
    super.key,
  });

  @override
  State<CommentLikesBottomSheet> createState() =>
      _CommentLikesBottomSheetState();
}

class _CommentLikesBottomSheetState extends State<CommentLikesBottomSheet> {
  static const _maxHeightFraction = 0.7;

  Map<String, String> _anonDisplayNames = {};
  bool _isLoading = true;

  List<Reaction> get _likes =>
      widget.reactions.where((r) => !r.isDeleted).toList();

  @override
  void initState() {
    super.initState();
    _loadAnonDisplayNames();
  }

  Future<void> _loadAnonDisplayNames() async {
    try {
      final anonNames = await SocialDataProvider.instance
          .getAnonDisplayNamesForCollection(widget.collectionID);
      if (mounted) {
        setState(() {
          _anonDisplayNames = anonNames;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  User _getUserForReaction(Reaction reaction) {
    if (reaction.isAnonymous) {
      final anonID = reaction.anonUserID;
      final displayName =
          anonID != null ? (_anonDisplayNames[anonID] ?? anonID) : "Anonymous";
      return User(
        id: reaction.userID,
        email: "${anonID ?? "anonymous"}@unknown.com",
        name: displayName,
      );
    }

    return CollectionsService.instance
        .getFileOwner(reaction.userID, widget.collectionID);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * _maxHeightFraction,
      ),
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_likes.length} ${_likes.length == 1 ? 'like' : 'likes'}",
                    style: textTheme.bodyBold,
                  ),
                  IconButtonWidget(
                    iconButtonType: IconButtonType.rounded,
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: EnteLoadingWidget(size: 24),
              )
            else if (_likes.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Text(
                  "No likes yet",
                  style: textTheme.smallMuted,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: _likes.length <= _shrinkWrapThreshold,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    final reaction = _likes[index];
                    final user = _getUserForReaction(reaction);
                    return _CommentLikeListItem(
                      user: user,
                      currentUserID: widget.currentUserID,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommentLikeListItem extends StatelessWidget {
  final User user;
  final int currentUserID;

  const _CommentLikeListItem({
    required this.user,
    required this.currentUserID,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          UserAvatarWidget(
            user,
            currentUserID: currentUserID,
            type: AvatarType.lg,
            addStroke: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.id == currentUserID
                  ? "You"
                  : (user.displayName ?? user.email),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: 14 * -0.02,
                color: colorScheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.favorite,
            color: Color(0xFF08C225),
            size: 20,
          ),
        ],
      ),
    );
  }
}
