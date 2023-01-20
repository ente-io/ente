import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class AlbumListItemWidget extends StatelessWidget {
  final CollectionWithThumbnail item;
  const AlbumListItemWidget(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final logger = Logger("AlbumListItemWidget");
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    const sideOfThumbnail = 60.0;
    return Stack(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
              child: SizedBox(
                height: sideOfThumbnail,
                width: sideOfThumbnail,
                key: Key("collection_item:" + (item.thumbnail?.tag ?? "")),
                child: item.thumbnail != null
                    ? ThumbnailWidget(
                        item.thumbnail,
                        showFavForAlbumOnly: true,
                      )
                    : const NoThumbnailWidget(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.collection.collectionName),
                  FutureBuilder<int>(
                    future: FilesDB.instance
                        .collectionFileCount(item.collection.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final text =
                            snapshot.data == 1 ? " memory" : " memories";
                        return Text(
                          snapshot.data.toString() + text,
                          style: textTheme.small.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        );
                      } else {
                        if (snapshot.hasError) {
                          logger.severe(
                            "Failed to fetch file count of collection id ${item.collection.id}",
                          );
                        }
                        return Text(
                          "",
                          style: textTheme.small.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        IgnorePointer(
          child: Container(
            height: sideOfThumbnail,
            //32 is to account for padding of 16pts on both sides
            width: MediaQuery.of(context).size.width - 32,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.strokeFainter),
              borderRadius: const BorderRadius.all(
                Radius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
