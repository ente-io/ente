import "package:ente_icons/ente_icons.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class AlbumListItemWidget extends StatelessWidget {
  static const _thumbSize = 52.0;
  static const _cornerRadius = 12.0;
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;
  static const _padding = 8.0;

  static final double _trailingWidth =
      getAvatarSize(AvatarType.medium) + getOverlapPadding(AvatarType.medium);

  final Collection collection;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;
  final SelectedAlbums? selectedAlbums;

  const AlbumListItemWidget(
    this.collection, {
    super.key,
    this.onTapCallback,
    this.onLongPressCallback,
    this.selectedAlbums,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bool isOwner =
        collection.isOwner(Configuration.instance.getUserID()!);
    final bool isOutgoing = isOwner && collection.hasSharees;
    final bool isIncoming = !isOwner;
    final bool showSharingIndicator = isOutgoing || isIncoming;
    final bool isFavoriteAlbum = collection.type == CollectionType.favorites;
    final bool showPin =
        isOwner ? collection.isPinned : collection.hasShareePinned();
    final bool showArchive =
        isOwner ? collection.isArchived() : collection.hasShareeArchived();
    final bool hasAnyStatus = isFavoriteAlbum || showPin || showArchive;

    final albumWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: _thumbSize,
            width: _thumbSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_cornerRadius),
                  child: SizedBox(
                    height: _thumbSize,
                    width: _thumbSize,
                    child: FutureBuilder<EnteFile?>(
                      future: CollectionsService.instance.getCover(collection),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final thumbnail = snapshot.data!;
                          return ThumbnailWidget(
                            thumbnail,
                            shouldShowFavoriteIcon: false,
                            shouldShowOwnerAvatar: false,
                          );
                        } else {
                          return const NoThumbnailWidget(
                            addBorder: false,
                          );
                        }
                      },
                    ),
                  ),
                ),
                if (showSharingIndicator)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.fill,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.greenBase,
                          width: 1.25,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: HugeIcon(
                        icon: isOutgoing
                            ? HugeIcons.strokeRoundedArrowUpRight01
                            : HugeIcons.strokeRoundedArrowDownLeft01,
                        strokeWidth: 3.0,
                        color: colorScheme.greenBase,
                        size: 10.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collection.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: CollectionsService.instance.getFileCount(collection),
                  builder: (context, snapshot) {
                    String countText = "";
                    if (snapshot.hasData) {
                      countText = AppLocalizations.of(context).itemCount(
                        count: snapshot.data!,
                      );
                    } else if (snapshot.hasError) {
                      Logger("AlbumListItemWidget").severe(
                        "Failed to fetch file count of collection",
                        snapshot.error,
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(countText, style: textTheme.smallMuted),
                        if (hasAnyStatus) ...[
                          Text(" • ", style: textTheme.smallMuted),
                          if (showPin)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedPin,
                              size: 12,
                              color: colorScheme.textMuted,
                              strokeWidth: 2.0,
                            ),
                          if (showArchive)
                            Icon(
                              Icons.archive_outlined,
                              size: 12,
                              color: colorScheme.textMuted,
                            ),
                          if (isFavoriteAlbum)
                            Icon(
                              EnteIcons.favoriteFilled,
                              size: 12,
                              color: colorScheme.greenBase,
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => onTapCallback?.call(collection),
      onLongPress: () => onLongPressCallback?.call(collection),
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: selectedAlbums!,
        builder: (context, _) {
          final isSelected =
              selectedAlbums?.isAlbumSelected(collection) ?? false;

          return AnimatedContainer(
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
            height: _rowHeight,
            padding: const EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.greenLight : colorScheme.fill,
              borderRadius:
                  const BorderRadius.all(Radius.circular(_cardRadius)),
              border: Border.all(
                color: isSelected ? colorScheme.greenStroke : colorScheme.fill,
              ),
            ),
            child: Row(
              children: [
                albumWidget,
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: _trailingWidth,
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _buildTrailingIndicator(
                        isSelected: isSelected,
                        isOwner: isOwner,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailingIndicator({
    required bool isSelected,
    required bool isOwner,
    required EnteColorScheme colorScheme,
  }) {
    final double avatarSize = getAvatarSize(AvatarType.medium);
    final double slotOverlap = getOverlapPadding(AvatarType.medium);

    if (isSelected) {
      return Container(
        key: const ValueKey("selected"),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: colorScheme.primary700,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(2),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedTick02,
          size: 12,
          color: Colors.white,
          strokeWidth: 2.0,
        ),
      );
    }
    if (!isOwner) {
      return UserAvatarWidget(
        key: const ValueKey("owner"),
        collection.owner,
        type: AvatarType.medium,
        thumbnailView: true,
      );
    }
    if (collection.hasSharees) {
      final sharees = collection.getSharees();
      final int total = sharees.length;
      final int limit = total > 2 ? 1 : 2;
      final int displayCount = total.clamp(1, limit);
      final bool hasMore = total > limit;
      final double contentWidth =
          avatarSize + (displayCount - 1 + (hasMore ? 1 : 0)) * slotOverlap;
      return SizedBox(
        key: const ValueKey("sharees"),
        width: contentWidth,
        height: avatarSize,
        child: AlbumSharesIcons(
          sharees: sharees,
          type: AvatarType.medium,
          limitCountTo: limit,
          padding: EdgeInsets.zero,
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey("unselected"));
  }
}
