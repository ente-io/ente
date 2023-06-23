import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import "package:photos/models/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class AlbumRowItemWidget extends StatelessWidget {
  final Collection c;
  final double sideOfThumbnail;
  final bool showFileCount;
  static const tagPrefix = "collection";

  AlbumRowItemWidget(
    this.c,
    this.sideOfThumbnail, {
    this.showFileCount = true,
    Key? key,
  }) : super(key: Key(c.id.toString()));

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
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
                  child: FutureBuilder<File?>(
                    future: CollectionsService.instance.getCover(c),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final thumbnail = snapshot.data!;
                        final String heroTag = tagPrefix + thumbnail.tag;
                        return Hero(
                          tag: heroTag,
                          child: ThumbnailWidget(
                            thumbnail,
                            shouldShowArchiveStatus: c.isArchived(),
                            showFavForAlbumOnly: true,
                            key: Key(heroTag),
                          ),
                        );
                      } else {
                        return const NoThumbnailWidget();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                (c.displayName).trim(),
                style: enteTextTheme.small,
                overflow: TextOverflow.ellipsis,
              ),
              showFileCount
                  ? FutureBuilder<int>(
                      future: FilesDB.instance.collectionFileCount(c.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            NumberFormat().format(snapshot.data),
                            style: enteTextTheme.small.copyWith(
                              color: enteColorScheme.textMuted,
                            ),
                          );
                        } else {
                          return Text(
                            "",
                            style: enteTextTheme.small.copyWith(
                              color: enteColorScheme.textMuted,
                            ),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
            ],
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
            appBarType: (c.type == CollectionType.favorites
                ? GalleryType.favorite
                : GalleryType.ownedCollection),
          ),
        );
      },
    );
  }
}
