import "dart:math";

import 'package:ente_icons/ente_icons.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/more_count_badge.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import 'package:photos/ui/viewer/file/file_icons_widget.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';

class AlbumRowItemWidget extends StatelessWidget {
  final Collection c;
  final double sideOfThumbnail;
  final bool showFileCount;
  final String tag;
  final bool? hasVerifiedLock;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;
  final SelectedAlbums? selectedAlbums;
  static const _cornerRadius = 20.0;
  static const _cornerSmoothing = 0.6;
  static const _overlayPadding = 8.0;
  static const _sharePillTopOffset = -12.0;
  static const _sharePillLeftOffset = 0.0;
  static const _sharePillPadding = EdgeInsets.all(4);
  static const _sharedAvatarStrokeWidth = 2.0;

  const AlbumRowItemWidget(
    this.c,
    this.sideOfThumbnail, {
    super.key,
    this.showFileCount = true,
    this.tag = "",
    this.hasVerifiedLock,
    this.onTapCallback,
    this.onLongPressCallback,
    this.selectedAlbums,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner = c.isOwner(Configuration.instance.getUserID()!);
    final String tagPrefix = (isOwner ? "collection" : "shared_collection") +
        tag +
        "_" +
        c.id.toString();
    final colorScheme = getEnteColorScheme(context);
    final enteTextTheme = getEnteTextTheme(context);
    final Widget? linkIcon = c.hasLink && isOwner
        ? HugeIcon(
            icon: HugeIcons.strokeRoundedLink02,
            color: c.publicURLs.first.isExpired
                ? warning500
                : colorScheme.textBase,
            size: 10,
            strokeWidth: 1.5,
          )
        : null;

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: sideOfThumbnail,
            width: sideOfThumbnail,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: SizedBox(
                    height: sideOfThumbnail,
                    width: sideOfThumbnail,
                    child: Stack(
                      children: [
                        FutureBuilder<EnteFile?>(
                          future: CollectionsService.instance.getCover(c),
                          builder: (context, snapshot) {
                            EnteFile? thumbnail;
                            if (snapshot.hasData) {
                              thumbnail = snapshot.data!;
                            } else {
                              //Need to use cached thumbnail so that the hero
                              //animation works as expected.
                              thumbnail =
                                  CollectionsService.instance.getCoverCache(c);
                            }
                            if (thumbnail != null) {
                              final bool isSelected =
                                  selectedAlbums?.isAlbumSelected(c) ?? false;
                              final String heroTag = tagPrefix + thumbnail.tag;
                              final thumbnailWidget = ThumbnailWidget(
                                thumbnail,
                                shouldShowFavoriteIcon: false,
                                shouldShowSyncStatus: false,
                                key: Key(heroTag),
                              );
                              return Hero(
                                tag: heroTag,
                                transitionOnUserGestures: true,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    thumbnailWidget,
                                    if (isSelected)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                color: colorScheme.backdropBase,
                                child: const NoThumbnailWidget(
                                  borderRadius: _cornerRadius,
                                  addBorder: false,
                                ),
                              );
                            }
                          },
                        ),
                        Positioned(
                          top: _overlayPadding,
                          right: _overlayPadding,
                          child: selectedAlbums == null
                              ? const SizedBox.shrink()
                              : Hero(
                                  tag: tagPrefix + "_album_selection",
                                  transitionOnUserGestures: true,
                                  child: ListenableBuilder(
                                    listenable: selectedAlbums!,
                                    builder: (context, _) {
                                      final bool isSelected =
                                          selectedAlbums!.isAlbumSelected(c);
                                      return AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: isSelected
                                            ? Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary700,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(2),
                                                child: const HugeIcon(
                                                  strokeWidth: 2.0,
                                                  size: 12,
                                                  icon: HugeIcons
                                                      .strokeRoundedTick02,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                        ),
                        if (!isOwner)
                          Positioned(
                            right: _overlayPadding,
                            bottom: _overlayPadding,
                            child: Hero(
                              tag: tagPrefix + "_owner_other",
                              transitionOnUserGestures: true,
                              child: SizedBox.square(
                                dimension: getAvatarSize(AvatarType.small) +
                                    _sharedAvatarStrokeWidth * 2,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    UserAvatarWidget(
                                      c.owner,
                                      thumbnailView: true,
                                      type: AvatarType.small,
                                    ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: _sharedAvatarStrokeWidth,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: _overlayPadding,
                          bottom: _overlayPadding,
                          child: _buildAlbumStatusChips(isOwner: isOwner),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwner && (c.hasSharees || c.hasLink))
                  Positioned(
                    top: _sharePillTopOffset,
                    left: _sharePillLeftOffset,
                    child: Hero(
                      tag: tagPrefix + "_sharees",
                      transitionOnUserGestures: true,
                      child: Container(
                        padding: _sharePillPadding,
                        decoration: BoxDecoration(
                          color: colorScheme.backgroundElevated,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: SizedBox(
                          height: getAvatarSize(AvatarType.small),
                          child: _AlbumRowSharePillContent(
                            sharees: c.getSharees(),
                            trailingWidget: linkIcon,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Hero(
            tag: tagPrefix + "_title",
            transitionOnUserGestures: true,
            child: SizedBox(
              width: sideOfThumbnail,
              child: showFileCount
                  ? FutureBuilder<int>(
                      future: CollectionsService.instance.getFileCount(c),
                      builder: (context, snapshot) {
                        int? cachedCount;
                        if (snapshot.hasData) {
                          cachedCount = snapshot.data;
                        } else {
                          //Need to use cached count so that the hero
                          //animation works as expected without flickering.
                          cachedCount =
                              CollectionsService.instance.getCachedFileCount(c);
                        }
                        if (cachedCount != null && cachedCount > 0) {
                          final String textCount =
                              AppLocalizations.of(context).itemCount(
                            count: cachedCount,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.displayName,
                                style: enteTextTheme.small,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                textCount,
                                style: enteTextTheme.miniMuted,
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            c.displayName,
                            style: enteTextTheme.small,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      },
                    )
                  : Text(
                      c.displayName,
                      style: enteTextTheme.small,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
      onTap: () async {
        if (onTapCallback != null) {
          onTapCallback!(c);
          return;
        }
        final thumbnail = await CollectionsService.instance.getCover(c);
        // ignore: unawaited_futures
        routeToPage(
          context,
          CollectionPage(
            CollectionWithThumbnail(c, thumbnail),
            tagPrefix: tagPrefix,
            hasVerifiedLock: hasVerifiedLock,
          ),
        );
      },
      onLongPress: () {
        if (onLongPressCallback != null) {
          onLongPressCallback!(c);
        }
      },
    );
  }

  Widget _buildAlbumStatusChips({required bool isOwner}) {
    final bool isFavoriteAlbum = c.type == CollectionType.favorites;
    final bool showPin = isOwner ? c.isPinned : c.hasShareePinned();
    final bool showArchive = isOwner ? c.isArchived() : c.hasShareeArchived();

    final chips = <Widget>[
      if (isFavoriteAlbum)
        const ThumbnailStatusChip(
          child: Icon(
            EnteIcons.favoriteFilled,
            size: ThumbnailStatusChip.iconSize,
            color: Colors.white,
          ),
        ),
      if (showPin)
        const ThumbnailStatusChip(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedPin,
            size: ThumbnailStatusChip.iconSize,
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        ),
      if (showArchive)
        const ThumbnailStatusChip(
          child: Icon(
            Icons.archive_outlined,
            size: ThumbnailStatusChip.iconSize,
            color: Colors.white,
          ),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          chips[i],
        ],
      ],
    );
  }
}

class _AlbumRowSharePillContent extends StatelessWidget {
  static const _trailingGap = 2.0;
  static const _limitCountTo = 2;

  final List<User> sharees;
  final Widget? trailingWidget;

  const _AlbumRowSharePillContent({
    required this.sharees,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = min(sharees.length, _limitCountTo);
    final hasMore = sharees.length > _limitCountTo;
    const type = AvatarType.small;
    final double avatarSize = getAvatarSize(type);
    final double overlapPadding = getOverlapPadding(type);
    final trailingWidgetWidth = trailingWidget == null ? 0.0 : avatarSize;
    final visibleAvatarCount = displayCount + (hasMore ? 1 : 0);
    final visibleAvatarsWidth = visibleAvatarCount == 0
        ? 0.0
        : avatarSize + (visibleAvatarCount - 1) * overlapPadding;
    final trailingGap =
        visibleAvatarCount > 0 && trailingWidget != null ? _trailingGap : 0.0;
    final contentWidth =
        visibleAvatarsWidth + trailingGap + trailingWidgetWidth;

    final widgets = List<Widget>.generate(
      displayCount,
      (index) => Positioned(
        left: overlapPadding * index,
        child: UserAvatarWidget(
          sharees[index],
          thumbnailView: true,
          type: type,
        ),
      ),
    );

    if (hasMore) {
      widgets.add(
        Positioned(
          left: overlapPadding * displayCount,
          child: MoreCountWidget(
            sharees.length - displayCount,
            type: moreCountTypeFromAvatarType(type),
            thumbnailView: true,
          ),
        ),
      );
    }

    if (trailingWidget != null) {
      widgets.add(
        Positioned(
          left: visibleAvatarsWidth + trailingGap,
          child: SizedBox.square(
            dimension: avatarSize,
            child: Center(
              child: trailingWidget!,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: contentWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: widgets,
      ),
    );
  }
}
