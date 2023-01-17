import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CollectionItem extends StatelessWidget {
  final CollectionWithThumbnail c;
  final double sideOfThumbnail;
  final bool shouldRender;

  CollectionItem(
    this.c,
    this.sideOfThumbnail, {
    this.shouldRender = false,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: sideOfThumbnail,
                  width: sideOfThumbnail,
                  child: Hero(
                    tag: heroTag,
                    child: c.thumbnail != null
                        ? CollectionItemThumbnailWidget(
                            c: c,
                            heroTag: heroTag,
                            shouldRender: shouldRender,
                          )
                        : const NoThumbnailWidget(),
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
                (c.collection.name ?? "Unnamed").trim(),
                style: enteTextTheme.small,
                overflow: TextOverflow.ellipsis,
              ),
              FutureBuilder<int>(
                future: FilesDB.instance.collectionFileCount(c.collection.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
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
        routeToPage(
          context,
          CollectionPage(
            c,
            appBarType: (c.collection.type == CollectionType.favorites
                ? GalleryType.favorite
                : GalleryType.ownedCollection),
          ),
        );
      },
    );
  }
}

class CollectionItemThumbnailWidget extends StatefulWidget {
  const CollectionItemThumbnailWidget({
    Key? key,
    required this.c,
    required this.heroTag,
    this.shouldRender = false,
  }) : super(key: key);

  final CollectionWithThumbnail c;
  final String heroTag;
  final bool shouldRender;

  @override
  State<CollectionItemThumbnailWidget> createState() =>
      _CollectionItemThumbnailWidgetState();
}

class _CollectionItemThumbnailWidgetState
    extends State<CollectionItemThumbnailWidget> {
  bool _shouldRender = false;

  @override
  void initState() {
    super.initState();
    _shouldRender = widget.shouldRender;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key("collection_item" + widget.c.thumbnail!.tag),
      onVisibilityChanged: (visibility) {
        final shouldRender = visibility.visibleFraction > 0;
        if (mounted && shouldRender && !_shouldRender) {
          setState(() {
            _shouldRender = shouldRender;
          });
        }
      },
      child: _shouldRender
          ? ThumbnailWidget(
              widget.c.thumbnail,
              shouldShowArchiveStatus: widget.c.collection.isArchived(),
              showFavForAlbumOnly: true,
              key: Key(widget.heroTag),
            )
          : const NoThumbnailWidget(),
    );
  }
}
