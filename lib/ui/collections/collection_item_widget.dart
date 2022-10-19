import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionItem extends StatelessWidget {
  final CollectionWithThumbnail c;
  final double sideOfThumbnail;

  CollectionItem(
    this.c,
    this.sideOfThumbnail, {
    Key? key,
  }) : super(key: Key(c.collection.id.toString()));

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final enteTextTheme = getEnteTextTheme(context);
    final String heroTag =
        "collection" + (c.thumbnail?.tag ?? c.collection.id.toString());
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: sideOfThumbnail,
              width: sideOfThumbnail,
              child: Hero(
                tag: heroTag,
                child: c.thumbnail != null
                    ? ThumbnailWidget(
                        c.thumbnail,
                        shouldShowArchiveStatus: c.collection.isArchived(),
                        key: Key(heroTag),
                      )
                    : const NoThumbnailWidget(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.collection.name ?? "Unnamed",
                style: enteTextTheme.small,
                overflow: TextOverflow.ellipsis,
              ),
              FutureBuilder<int>(
                future: FilesDB.instance.collectionFileCount(c.collection.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    return Text(
                      snapshot.data.toString(),
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
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        routeToPage(context, CollectionPage(c));
      },
    );
  }
}
