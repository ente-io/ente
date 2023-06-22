import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/models/file.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/colors.dart';
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class OutgoingAlbumItem extends StatelessWidget {
  final Collection c;
  static const heroTagPrefix = "outgoing_collection";

  const OutgoingAlbumItem({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final shareesName = <String>[];
    if (c.hasSharees) {
      for (int index = 0; index < c.sharees!.length; index++) {
        final sharee = c.sharees![index]!;
        final String name =
            (sharee.name?.isNotEmpty ?? false) ? sharee.name! : sharee.email;
        if (index < 2) {
          shareesName.add(name);
        } else {
          final remaining = c.sharees!.length - index;
          if (remaining == 1) {
            // If it's the last sharee
            shareesName.add(name);
          } else {
            shareesName.add(
              "and " +
                  remaining.toString() +
                  " other" +
                  (remaining > 1 ? "s" : ""),
            );
          }
          break;
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: SizedBox(
                height: 60,
                width: 60,
                child: FutureBuilder<File?>(
                  future: CollectionsService.instance.getCover(c),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final String heroTag = heroTagPrefix + snapshot.data!.tag;
                      return Hero(
                        tag: heroTag,
                        child: ThumbnailWidget(
                          snapshot.data!,
                          key: ValueKey(heroTag),
                        ),
                      );
                    } else {
                      return const NoThumbnailWidget();
                    }
                  },
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(2)),
                      c.hasLink
                          ? (c.publicURLs!.first!.isExpired
                              ? const Icon(
                                  Icons.link,
                                  color: warning500,
                                )
                              : const Icon(Icons.link))
                          : const SizedBox.shrink(),
                    ],
                  ),
                  shareesName.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                          child: Text(
                            S.of(context).sharedWith(shareesName.join(", ")),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColorLight,
                            ),
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        final thumbnail = await CollectionsService.instance.getCover(c);
        final page = CollectionPage(
          CollectionWithThumbnail(
            c,
            thumbnail,
          ),
          appBarType: GalleryType.ownedCollection,
          tagPrefix: heroTagPrefix,
        );
        routeToPage(context, page);
      },
    );
  }
}
