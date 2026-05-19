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
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/thumbnail_list_item.dart";
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class AlbumListItemWidget extends StatelessWidget {
  static final double _trailingWidth =
      getAvatarSize(AvatarType.md) + getOverlapPadding(AvatarType.md);

  final Collection collection;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;
  final SelectedAlbums? selectedAlbums;
  final bool isSelected;

  const AlbumListItemWidget(
    this.collection, {
    super.key,
    this.onTapCallback,
    this.onLongPressCallback,
    this.selectedAlbums,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedAlbums == null) {
      return _buildItem(context, isSelected: isSelected);
    }
    return ListenableBuilder(
      listenable: selectedAlbums!,
      builder: (context, _) {
        return _buildItem(
          context,
          isSelected: selectedAlbums!.isAlbumSelected(collection),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required bool isSelected,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bool isOwner = collection.isOwner(
      Configuration.instance.getUserID() ?? -1,
    );
    final bool isOutgoing = isOwner && collection.hasSharees;
    final bool isIncoming = !isOwner;
    final bool showSharingIndicator = isOutgoing || isIncoming;
    final bool isFavoriteAlbum = collection.type == CollectionType.favorites;
    final bool showPin = isOwner
        ? collection.isPinned
        : collection.hasShareePinned();
    final bool showArchive = isOwner
        ? collection.isArchived()
        : collection.hasShareeArchived();
    final bool hasAnyStatus = isFavoriteAlbum || showPin || showArchive;

    return ThumbnailListItem(
      backgroundColor: thumbnailListItemBackgroundColor(context),
      isSelected: isSelected,
      onTap: onTapCallback == null ? null : () => onTapCallback!(collection),
      onLongPress: onLongPressCallback == null
          ? null
          : () => onLongPressCallback!(collection),
      leading: _AlbumListItemCover(
        collection: collection,
        showSharingIndicator: showSharingIndicator,
        isOutgoing: isOutgoing,
      ),
      title: Text(
        collection.displayName,
        style: textTheme.body,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: FutureBuilder<int>(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  countText,
                  style: textTheme.smallMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasAnyStatus) ...[
                Text(" \u2022 ", style: textTheme.smallMuted),
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
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: _trailingWidth,
          height: getAvatarSize(AvatarType.md),
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
              context,
              isSelected: isSelected,
              isOwner: isOwner,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingIndicator(
    BuildContext context, {
    required bool isSelected,
    required bool isOwner,
  }) {
    final double avatarSize = getAvatarSize(AvatarType.md);
    final double slotOverlap = getOverlapPadding(AvatarType.md);

    if (isSelected) {
      return const _CollectionSelectedBadge(
        key: ValueKey("selected"),
      );
    }
    if (!isOwner) {
      return UserAvatarWidget(
        key: const ValueKey("owner"),
        collection.owner,
        type: AvatarType.md,
        thumbnailView: true,
      );
    }
    if (collection.hasSharees) {
      final sharees = collection.getSharees();
      final int total = sharees.length;
      final int limit = total > 2 ? 1 : 2;
      final int displayCount = total.clamp(1, limit).toInt();
      final bool hasMore = total > limit;
      final double contentWidth =
          avatarSize + (displayCount - 1 + (hasMore ? 1 : 0)) * slotOverlap;
      return SizedBox(
        key: const ValueKey("sharees"),
        width: contentWidth,
        height: avatarSize,
        child: AlbumSharesIcons(
          sharees: sharees,
          type: AvatarType.md,
          limitCountTo: limit,
          padding: EdgeInsets.zero,
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey("unselected"));
  }
}

class _AlbumListItemCover extends StatelessWidget {
  final Collection collection;
  final bool showSharingIndicator;
  final bool isOutgoing;

  const _AlbumListItemCover({
    required this.collection,
    required this.showSharingIndicator,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            ThumbnailListItem.defaultLeadingRadius,
          ),
          child: SizedBox.expand(
            child: FutureBuilder<EnteFile?>(
              future: CollectionsService.instance.getCover(collection),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ThumbnailWidget(
                    snapshot.data!,
                    shouldShowFavoriteIcon: false,
                    shouldShowOwnerAvatar: false,
                  );
                }
                return const NoThumbnailWidget(
                  borderRadius: ThumbnailListItem.defaultLeadingRadius,
                  addBorder: false,
                );
              },
            ),
          ),
        ),
        if (showSharingIndicator)
          Positioned(
            right: -4,
            bottom: -4,
            child: _CollectionShareBadge(isOutgoing: isOutgoing),
          ),
      ],
    );
  }
}

class _CollectionShareBadge extends StatelessWidget {
  final bool isOutgoing;

  const _CollectionShareBadge({
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.strokeFainter),
      ),
      child: Center(
        child: Icon(
          isOutgoing
              ? Icons.person_add_alt_1_outlined
              : Icons.person_outline_rounded,
          size: 12,
          color: colorScheme.textMuted,
        ),
      ),
    );
  }
}

class _CollectionSelectedBadge extends StatelessWidget {
  const _CollectionSelectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: getAvatarSize(AvatarType.md),
      height: getAvatarSize(AvatarType.md),
      decoration: BoxDecoration(
        color: colorScheme.greenBase,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
