import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:photos/core/configuration.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import "package:photos/models/file.dart";
import 'package:photos/models/gallery_type.dart';
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

  const AlbumRowItemWidget(
    this.c,
    this.sideOfThumbnail, {
    super.key,
    this.showFileCount = true,
    this.tag = "",
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
            color: c.publicURLs!.first!.isExpired ? warning500 : strokeBaseDark,
          )
        : null;
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: sideOfThumbnail,
                  width: sideOfThumbnail,
                  child: Stack(
                    children: [
                      FutureBuilder<File?>(
                        future: CollectionsService.instance.getCover(c),
                        builder: (context, snapshot) {
                          File? thumbnail;
                          if (snapshot.hasData) {
                            thumbnail = snapshot.data!;
                          } else {
                            //Need to use cached thumbnail so that the hero
                            //animation works as expected.
                            thumbnail =
                                CollectionsService.instance.getCoverCache(c);
                          }
                          if (thumbnail != null) {
                            final String heroTag = tagPrefix + thumbnail.tag;
                            return Hero(
                              tag: heroTag,
                              transitionOnUserGestures: true,
                              child: ThumbnailWidget(
                                thumbnail,
                                shouldShowArchiveStatus: isOwner
                                    ? c.isArchived()
                                    : c.hasShareeArchived(),
                                showFavForAlbumOnly: true,
                                shouldShowSyncStatus: false,
                                shouldShowPinIcon: isOwner && c.isPinned,
                                key: Key(heroTag),
                              ),
                            );
                          } else {
                            return const NoThumbnailWidget();
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
                                sharees: c.getSharees(),
                                type: AvatarType.mini,
                                trailingWidget: linkIcon,
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
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: UserAvatarWidget(
                                c.owner!,
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
          const SizedBox(height: 4),
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
                    return Row(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                sideOfThumbnail - ((textCount.length + 3) * 10),
                          ),
                          child: Text(
                            c.displayName,
                            style: enteTextTheme.small,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: enteTextTheme.smallMuted,
                            children: [
                              TextSpan(text: '  \u2022  $textCount'),
                            ],
                          ),
                        )
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
        final thumbnail = await CollectionsService.instance.getCover(c);
        routeToPage(
          context,
          CollectionPage(
            CollectionWithThumbnail(c, thumbnail),
            tagPrefix: tagPrefix,
            appBarType: isOwner
                ? (c.type == CollectionType.favorites
                    ? GalleryType.favorite
                    : GalleryType.ownedCollection)
                : GalleryType.sharedCollection,
          ),
        );
      },
    );
  }
}
