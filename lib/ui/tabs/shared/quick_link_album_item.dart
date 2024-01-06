import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class QuickLinkAlbumItem extends StatelessWidget {
  final Collection c;
  static const heroTagPrefix = "outgoing_collection";

  const QuickLinkAlbumItem({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: SizedBox(
                height: 60,
                width: 60,
                child: FutureBuilder<EnteFile?>(
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
                  Text(
                    c.displayName,
                    style: getEnteTextTheme(context).body,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                    child: FutureBuilder<int>(
                      future: CollectionsService.instance.getFileCount(c),
                      builder: (context, snapshot) {
                        if (!snapshot.hasError) {
                          // final String textCount = NumberFormat().format(snapshot.data);
                          return Row(
                            children: [
                              (!snapshot.hasData)
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: EnteLoadingWidget(size: 10),
                                    )
                                  : Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        S.of(context).itemCount(snapshot.data!),
                                        style: getEnteTextTheme(context)
                                            .smallMuted,
                                      ),
                                    ),
                              const SizedBox(width: 6),
                              c.hasLink
                                  ? (c.publicURLs!.first!.isExpired
                                      ? const Icon(
                                          Icons.link_outlined,
                                          color: warning500,
                                        )
                                      : Icon(
                                          Icons.link_outlined,
                                          color: getEnteColorScheme(context)
                                              .strokeMuted,
                                        ))
                                  : const SizedBox.shrink(),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Text(S.of(context).somethingWentWrong);
                        } else {
                          return const EnteLoadingWidget(size: 10);
                        }
                      },
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
          tagPrefix: heroTagPrefix,
        );
        // ignore: unawaited_futures
        routeToPage(context, page);
      },
    );
  }
}
