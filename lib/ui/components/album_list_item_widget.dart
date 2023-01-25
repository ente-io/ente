import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class AlbumListItemWidget extends StatelessWidget {
  final CollectionWithThumbnail? item;
  final bool isNew;
  const AlbumListItemWidget({
    this.item,
    this.isNew = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    const sideOfThumbnail = 60.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
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
                    key: Key("collection_item:" + (item?.thumbnail?.tag ?? "")),
                    child: isNew
                        ? Icon(
                            Icons.add_outlined,
                            color: colorScheme.strokeMuted,
                          )
                        : item?.thumbnail != null
                            ? ThumbnailWidget(
                                item!.thumbnail,
                                showFavForAlbumOnly: true,
                              )
                            : const NoThumbnailWidget(
                                hasBorder: false,
                              ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: isNew
                      ? Text(
                          "New album",
                          style: textTheme.body
                              .copyWith(color: colorScheme.textMuted),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item?.collection.collectionName ?? ""),
                            item != null
                                ? FutureBuilder<int>(
                                    future:
                                        FilesDB.instance.collectionFileCount(
                                      item!.collection.id,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final text = snapshot.data == 1
                                            ? " memory"
                                            : " memories";
                                        return Text(
                                          snapshot.data.toString() + text,
                                          style: textTheme.small.copyWith(
                                            color: colorScheme.textMuted,
                                          ),
                                        );
                                      } else {
                                        if (snapshot.hasError) {
                                          Logger("AlbumListItemWidget").severe(
                                            "Failed to fetch file count of collection id ${item!.collection.id}",
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
                                  )
                                : throw "CollectionWithThumbnail item cannot be null",
                          ],
                        ),
                ),
              ],
            ),
            IgnorePointer(
              child: DottedBorder(
                dashPattern: isNew ? [4] : [300, 0],
                color: colorScheme.strokeFainter,
                strokeWidth: 1,
                padding: const EdgeInsets.all(0),
                borderType: BorderType.RRect,
                radius: const Radius.circular(4),
                child: SizedBox(
                  //Have to decrease the height and width by 1 pt as the stroke
                  //dotted border gives is of strokeAlign.center, so 0.5 inside and
                  // outside. Here for the row, stroke should be inside so we
                  //decrease the size of this sizedBox by 1 (so it shrinks 0.5 from
                  //every side) so that the strokeAlign.center of this sizedBox
                  //looks like a strokeAlign.inside in the row.
                  height: sideOfThumbnail - 1,
                  //This width will work for this only if the row widget takes up the
                  //full size it's parent (stack).
                  width: constraints.maxWidth - 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
