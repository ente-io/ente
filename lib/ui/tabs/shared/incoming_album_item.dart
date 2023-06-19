import "dart:math";

import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/models/file.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class IncomingAlbumItem extends StatelessWidget {
  final CollectionWithThumbnail c;
  const String heroTagPrefix = "shared_collection";

  const IncomingAlbumItem(
    this.c, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double horizontalPaddingOfGridRow = 16;
    const double crossAxisSpacingOfGrid = 9;
    final TextStyle albumTitleTextStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14);
    final Size size = MediaQuery.of(context).size;
    final int albumsCountInOneRow = max(size.width ~/ 220.0, 2);
    final double totalWhiteSpaceOfRow = (horizontalPaddingOfGridRow * 2) +
        (albumsCountInOneRow - 1) * crossAxisSpacingOfGrid;
    final double sideOfThumbnail = (size.width / albumsCountInOneRow) -
        (totalWhiteSpaceOfRow / albumsCountInOneRow);
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: sideOfThumbnail,
              width: sideOfThumbnail,
              child: Stack(
                children: [
                  FutureBuilder<File?>(
                    future: CollectionsService.instance.getCover(c.collection),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final heroTag = heroTagPrefix + snapshot.data!.tag;
                        return Hero(
                          tag: heroTag,
                          child: ThumbnailWidget(
                            snapshot.data!,
                            key: Key(heroTag),
                            shouldShowArchiveStatus:
                                c.collection.hasShareeArchived(),
                            shouldShowSyncStatus: false,
                          ),
                        );
                      } else {
                        return const NoThumbnailWidget();
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                      child: UserAvatarWidget(
                        c.collection.owner!,
                        thumbnailView: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: sideOfThumbnail - 40),
                child: Text(
                  c.collection.displayName,
                  style: albumTitleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FutureBuilder<int>(
                future: FilesDB.instance.collectionFileCount(c.collection.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    return RichText(
                      text: TextSpan(
                        style: albumTitleTextStyle.copyWith(
                          color: albumTitleTextStyle.color!.withOpacity(0.5),
                        ),
                        children: [
                          const TextSpan(text: "  \u2022  "),
                          TextSpan(text: snapshot.data.toString()),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        routeToPage(
          context,
          CollectionPage(
            c,
            appBarType: GalleryType.sharedCollection,
            tagPrefix: heroTagPrefix,
          ),
        );
      },
    );
  }
}
