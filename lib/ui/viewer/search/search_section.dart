import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/go_to_map_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import 'package:photos/ui/viewer/search/result/search_section_all_page.dart';
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/utils/navigation_util.dart";

class SearchSection extends StatefulWidget {
  final SectionType sectionType;
  final List<SearchResult> examples;
  final int limit;

  const SearchSection({
    Key? key,
    required this.sectionType,
    required this.examples,
    required this.limit,
  }) : super(key: key);

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  late List<SearchResult> _examples;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _examples = widget.examples;

    final streamsToListenTo = widget.sectionType.updateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _examples = await widget.sectionType.getData();
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
  void didUpdateWidget(covariant SearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _examples = widget.examples;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for ${widget.sectionType.name}");
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: widget.examples.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.sectionType.sectionTitle(context),
                        style: textTheme.largeBold,
                      ),
                    ),
                    _examples.length < (widget.limit - 1)
                        ? const SizedBox.shrink()
                        : GestureDetector(
                            onTap: () {
                              routeToPage(
                                context,
                                SearchSectionAllPage(
                                  sectionType: widget.sectionType,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.chevron_right_outlined,
                                color: getEnteColorScheme(context).strokeMuted,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 2),
                SearchExampleRow(_examples, widget.sectionType),
              ],
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sectionType.sectionTitle(context),
                            style: textTheme.largeBold,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.sectionType.getEmptyStateText(context),
                            style: textTheme.smallMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SearchSectionEmptyCTAIcon(widget.sectionType),
                ],
              ),
            ),
    );
  }
}

class RecentSection extends StatelessWidget {
  final List<SearchResult> searches;

  const RecentSection({
    required this.searches,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for recents");
    final textTheme = getEnteTextTheme(context);
    return ListenableBuilder(
      listenable: RecentSearches(),
      builder: (context, _) {
        if (RecentSearches().searches.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        SectionType.recents.sectionTitle(context),
                        style: textTheme.largeBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SearchExampleRow(
                  searches,
                  SectionType.recents,
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class SearchExampleRow extends StatelessWidget {
  final SectionType sectionType;
  final List<SearchResult> examples;

  const SearchExampleRow(this.examples, this.sectionType, {super.key});

  @override
  Widget build(BuildContext context) {
    //Cannot use listView.builder here
    final scrollableExamples = <Widget>[];
    if (sectionType == SectionType.location) {
      scrollableExamples.add(const GoToMapWidget());
    }
    examples.forEachIndexed((index, element) {
      scrollableExamples.add(
        SearchExample(
          searchResult: examples.elementAt(index),
        ),
      );
    });
    scrollableExamples.add(SearchSectionCTAIcon(sectionType));
    return SizedBox(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: scrollableExamples,
        ),
      ),
    );
  }
}

class SearchExample extends StatelessWidget {
  final SearchResult searchResult;
  const SearchExample({required this.searchResult, super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    late final double width;
    if (textScaleFactor <= 1.0) {
      width = 85.0;
    } else {
      width = 85.0 + ((textScaleFactor - 1.0) * 64);
    }
    return GestureDetector(
      onTap: () {
        RecentSearches().add(searchResult.name());

        if (searchResult is GenericSearchResult) {
          final genericSearchResult = searchResult as GenericSearchResult;
          if (genericSearchResult.onResultTap != null) {
            genericSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(searchResult),
            );
          }
        } else if (searchResult is AlbumSearchResult) {
          final albumSearchResult = searchResult as AlbumSearchResult;
          routeToPage(
            context,
            CollectionPage(
              albumSearchResult.collectionWithThumbnail,
              tagPrefix: albumSearchResult.heroTag(),
            ),
          );
        }
      },
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: searchResult.previewThumbnail() != null
                      ? ThumbnailWidget(
                          searchResult.previewThumbnail()!,
                          shouldShowSyncStatus: false,
                        )
                      : const NoThumbnailWidget(),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                searchResult.name(),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: getEnteTextTheme(context).mini,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
