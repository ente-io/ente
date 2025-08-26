import "dart:async";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";
import "package:photos/utils/navigation_util.dart";

class AlbumsSection extends StatefulWidget {
  final List<AlbumSearchResult> albumSearchResults;
  const AlbumsSection(this.albumSearchResults, {super.key});

  @override
  State<AlbumsSection> createState() => _AlbumsSectionState();
}

class _AlbumsSectionState extends State<AlbumsSection> {
  late List<AlbumSearchResult> _albumSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _albumSearchResults = widget.albumSearchResults;

    final streamsToListenTo = SectionType.album.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _albumSearchResults = (await SectionType.album.getData(
            context,
            limit: kSearchSectionLimit,
          )) as List<AlbumSearchResult>;
          setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AlbumsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _albumSearchResults = widget.albumSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_albumSearchResults.isEmpty) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SectionType.album.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.album.getEmptyStateText(context),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.album),
          ],
        ),
      );
    } else {
      final recommendations = <Widget>[
        ..._albumSearchResults.map(
          (albumSearchResult) => AlbumRecommendation(albumSearchResult),
        ),
        const AlbumCTA(),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              SectionType.album,
              hasMore: (_albumSearchResults.length >= kSearchSectionLimit - 1),
            ),
            const SizedBox(height: 2),
            SizedBox(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recommendations,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class AlbumRecommendation extends StatelessWidget {
  static const _width = 100.0;
  final AlbumSearchResult albumSearchResult;
  const AlbumRecommendation(this.albumSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = albumSearchResult.heroTag() +
        (albumSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(albumSearchResult.name());
          routeToPage(
            context,
            CollectionPage(
              albumSearchResult.collectionWithThumbnail,
              tagPrefix: albumSearchResult.heroTag(),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: _width,
                height: 100,
                child: albumSearchResult.previewThumbnail() != null
                    ? Hero(
                        tag: heroTag,
                        child: ThumbnailWidget(
                          albumSearchResult.previewThumbnail()!,
                          shouldShowArchiveStatus: false,
                          shouldShowSyncStatus: false,
                        ),
                      )
                    : const NoThumbnailWidget(
                        borderRadius: 8,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    albumSearchResult.name(),
                    style: enteTextTheme.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder(
                    future: CollectionsService.instance.getFileCount(
                      albumSearchResult.collectionWithThumbnail.collection,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data != 0) {
                        return Text(
                          snapshot.data.toString(),
                          style: enteTextTheme.miniMuted,
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlbumCTA extends StatelessWidget {
  const AlbumCTA({super.key});

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: SectionType.album.ctaOnTap(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Theme.of(context).brightness == Brightness.light
                    ? enteColorScheme.backdropBase
                    : enteColorScheme.backdropFaint,
                height: 100,
                width: 100,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  strokeWidth: 1.5,
                  borderPadding: const EdgeInsets.all(0.75),
                  dashPattern: const [3.75, 3.75],
                  radius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  color: enteColorScheme.strokeFaint,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: enteColorScheme.strokeFaint,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).addNew,
              style: getEnteTextTheme(context).smallFaint,
            ),
          ],
        ),
      ),
    );
  }
}
