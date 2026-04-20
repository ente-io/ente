import 'package:ente_icons/ente_icons.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import "package:intl/intl.dart";
import "package:photos/core/configuration.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/sharing/album_share_info_widget.dart";
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
  static const _borderWidth = 1.0;
  static const _cornerRadius = 20.0;
  static const _cornerSmoothing = 0.6;
  static const _overlayPadding = 8.0;

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
    final enteTextTheme = getEnteTextTheme(context);
    final Widget? linkIcon = c.hasLink && isOwner
        ? Padding(
            padding: const EdgeInsetsGeometry.symmetric(
              vertical: 3,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLink02,
              color: c.publicURLs.first.isExpired ? warning500 : strokeBaseDark,
              size: 10,
              strokeWidth: 2.5,
            ),
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
                    cornerRadius: _cornerRadius + _borderWidth,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: Container(
                    color: getEnteColorScheme(context).strokeFaint,
                    width: sideOfThumbnail,
                    height: sideOfThumbnail,
                  ),
                ),
                ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: SizedBox(
                    height: sideOfThumbnail - _borderWidth * 2,
                    width: sideOfThumbnail - _borderWidth * 2,
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
                                color: getEnteColorScheme(context).backdropBase,
                                child: const NoThumbnailWidget(
                                  borderRadius: _cornerRadius,
                                  addBorder: false,
                                ),
                              );
                            }
                          },
                        ),
                        if (isOwner && (c.hasSharees || c.hasLink))
                          Hero(
                            tag: tagPrefix + "_sharees",
                            transitionOnUserGestures: true,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: AlbumSharesIcons(
                                padding: const EdgeInsets.only(
                                  left: _overlayPadding,
                                  top: _overlayPadding,
                                ),
                                sharees: c.getSharees(),
                                type: AvatarType.small,
                                trailingWidget: linkIcon,
                              ),
                            ),
                          ),
                        Positioned(
                          top: _overlayPadding,
                          right: _overlayPadding,
                          child: Hero(
                            tag: tagPrefix + "_album_selection",
                            transitionOnUserGestures: true,
                            child: ListenableBuilder(
                              listenable:
                                  selectedAlbums ?? ValueNotifier(false),
                              builder: (context, _) {
                                final bool isSelected =
                                    selectedAlbums?.isAlbumSelected(c) ?? false;
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 22,
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
                              child: UserAvatarWidget(
                                c.owner,
                                thumbnailView: true,
                                type: AvatarType.small,
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
              ],
            ),
          ),
          const SizedBox(height: 6),
          Hero(
            tag: tagPrefix + "_title",
            transitionOnUserGestures: true,
            child: SizedBox(
              width: sideOfThumbnail,
              child: FutureBuilder<int>(
                future: showFileCount
                    ? CollectionsService.instance.getFileCount(c)
                    : Future.value(0),
                builder: (context, snapshot) {
                  int? cachedCount;
                  if (showFileCount) {
                    if (snapshot.hasData) {
                      cachedCount = snapshot.data;
                    } else {
                      //Need to use cached count so that the hero
                      //animation works as expected without flickering.
                      cachedCount =
                          CollectionsService.instance.getCachedFileCount(c);
                    }
                  }
                  if (cachedCount != null && cachedCount > 0) {
                    final String textCount = NumberFormat().format(cachedCount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: sideOfThumbnail,
                          ),
                          child: Text(
                            c.displayName,
                            style: enteTextTheme.small,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: enteTextTheme.miniMuted,
                            children: [
                              TextSpan(text: textCount),
                            ],
                          ),
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
