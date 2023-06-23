import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:photos/core/configuration.dart";
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import "package:photos/models/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/sharing/user_avator_widget.dart";
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class AlbumRowItemWidget extends StatelessWidget {
  final Collection c;
  final double sideOfThumbnail;
  final bool showFileCount;

  const AlbumRowItemWidget(
    this.c,
    this.sideOfThumbnail, {
    super.key,
    this.showFileCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner = c.isOwner(Configuration.instance.getUserID()!);
    final String tagPrefix = isOwner ? "collection" : "shared_collection";
    final enteTextTheme = getEnteTextTheme(context);
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
                          if (snapshot.hasData) {
                            final thumbnail = snapshot.data!;
                            final String heroTag = tagPrefix + thumbnail.tag;
                            return Hero(
                              tag: heroTag,
                              child: ThumbnailWidget(
                                thumbnail,
                                shouldShowArchiveStatus: isOwner
                                    ? c.isArchived()
                                    : c.hasShareeArchived(),
                                showFavForAlbumOnly: true,
                                shouldShowSyncStatus: false,
                                key: Key(heroTag),
                              ),
                            );
                          } else {
                            return const NoThumbnailWidget();
                          }
                        },
                      ),
                      if (!isOwner)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: UserAvatarWidget(
                              c.owner!,
                              thumbnailView: true,
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
          SizedBox(
            width: sideOfThumbnail,
            child: FutureBuilder<int>(
              future: showFileCount
                  ? FilesDB.instance.collectionFileCount(c.id)
                  : Future.value(0),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data! > 0) {
                  final String textCount = NumberFormat().format(snapshot.data);
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
