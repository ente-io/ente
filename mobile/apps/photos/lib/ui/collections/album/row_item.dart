import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
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
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

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
  static const _cornerRadius = 12.0;
  static const _cornerSmoothing = 0.6;

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
        ? Icon(
            Icons.link,
            color: c.publicURLs.first.isExpired ? warning500 : strokeBaseDark,
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
                                shouldShowArchiveStatus: isOwner
                                    ? c.isArchived()
                                    : c.hasShareeArchived(),
                                showFavForAlbumOnly: true,
                                shouldShowSyncStatus: false,
                                shouldShowPinIcon: isOwner && c.isPinned,
                                key: Key(heroTag),
                              );
                              return Hero(
                                tag: heroTag,
                                transitionOnUserGestures: true,
                                child: isSelected
                                    ? ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          BlendMode.darken,
                                        ),
                                        child: thumbnailWidget,
                                      )
                                    : thumbnailWidget,
                              );
                            } else {
                              return Container(
                                color: getEnteColorScheme(context).backdropBase,
                                child: const NoThumbnailWidget(
                                  borderRadius: 12,
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
                                padding: const EdgeInsets.only(left: 4, top: 4),
                                sharees: c.getSharees(),
                                type: AvatarType.mini,
                                trailingWidget: linkIcon,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
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
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Hero(
                              tag: tagPrefix + "_owner_other",
                              transitionOnUserGestures: true,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 4, bottom: 4),
                                child: UserAvatarWidget(
                                  c.owner,
                                  thumbnailView: true,
                                ),
                              ),
                            ),
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
}
