import "dart:async";

import "package:collection/collection.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/hierarchical/magic_filter.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/searchable_appbar.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import "package:photos/ui/viewer/search/result/searchable_item.dart";

class SearchSectionAllPage extends StatefulWidget {
  final SectionType sectionType;
  final bool startInSearchMode;
  const SearchSectionAllPage({
    required this.sectionType,
    this.startInSearchMode = false,
    super.key,
  });

  @override
  State<SearchSectionAllPage> createState() => _SearchSectionAllPageState();
}

class _SearchSectionAllPageState extends State<SearchSectionAllPage> {
  late Future<List<SearchResult>> sectionData;
  final streamSubscriptions = <StreamSubscription>[];
  String _searchQuery = "";

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    sectionData = widget.sectionType.getData(context);

    final streamsToListenTo = widget.sectionType.viewAllUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          setState(() {
            sectionData = widget.sectionType.getData(context);
          });
        }),
      );
    }
  }

  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _clearSearchQuery() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = "";
      });
    }
  }

  List<SearchResult> _filterResults(List<SearchResult> sectionResults) {
    if (!_isSearching) {
      return sectionResults;
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return sectionResults;
    }
    return sectionResults
        .where((result) => result.name().toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const horizontalEdgePadding = 16.0;
    final cacheExtent = widget.sectionType == SectionType.album ? 400.0 : null;
    return Scaffold(
      body: FutureBuilder<List<SearchResult>>(
        future: sectionData,
        builder: (context, snapshot) {
          final slivers = <Widget>[
            SearchableAppBar(
              title: Text(widget.sectionType.sectionTitle(context)),
              autoActivateSearch: widget.startInSearchMode,
              onSearch: _updateSearchQuery,
              onSearchClosed: _clearSearchQuery,
              centerTitle: false,
              searchIconPadding: const EdgeInsets.fromLTRB(
                12,
                12,
                horizontalEdgePadding,
                12,
              ),
            ),
          ];

          if (!snapshot.hasData) {
            slivers.add(
              const SliverFillRemaining(
                child: Center(child: EnteLoadingWidget()),
              ),
            );
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              cacheExtent: cacheExtent,
              slivers: slivers,
            );
          }

          List<SearchResult> sectionResults = snapshot.data!;

          if (widget.sectionType.sortByName) {
            sectionResults.sort(
              (a, b) => compareAsciiLowerCaseNatural(a.name(), b.name()),
            );
          }

          if (widget.sectionType == SectionType.location) {
            final result = sectionResults.splitMatch(
              (e) => e.type() == ResultType.location,
            );
            sectionResults = result.matched;
            sectionResults.addAll(result.unmatched);
          }

          final filteredResults = _filterResults(sectionResults);
          if (_isSearching && filteredResults.isEmpty) {
            slivers.add(
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).noResultsFound + '.',
                  ),
                ),
              ),
            );
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              cacheExtent: cacheExtent,
              slivers: slivers,
            );
          }

          final showCTA = widget.sectionType.isCTAVisible && !_isSearching;
          final totalItems = filteredResults.length + (showCTA ? 1 : 0);
          if (totalItems > 0) {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: horizontalEdgePadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 10);
                      }
                      final itemIndex = index ~/ 2;
                      if (showCTA && itemIndex == 0) {
                        return SearchableItemPlaceholder(widget.sectionType);
                      }
                      final adjustedIndex = showCTA ? itemIndex - 1 : itemIndex;
                      final result = filteredResults[adjustedIndex];
                      if (result is AlbumSearchResult) {
                        return SearchableItemWidget(
                          result,
                          resultCount: CollectionsService.instance.getFileCount(
                            result.collectionWithThumbnail.collection,
                          ),
                          onResultTap: () {
                            RecentSearches().add(result.name());
                            routeToPage(
                              context,
                              CollectionPage(
                                result.collectionWithThumbnail,
                                tagPrefix: "searchable_item" + result.heroTag(),
                              ),
                            );
                          },
                        );
                      }

                      if (widget.sectionType == SectionType.magic &&
                          result is GenericSearchResult) {
                        return SearchableItemWidget(
                          result,
                          onResultTap: () {
                            RecentSearches().add(result.name());
                            routeToPage(
                              context,
                              MagicResultScreen(
                                result.resultFiles(),
                                name: result.name(),
                                enableGrouping:
                                    result.params["enableGrouping"]! as bool,
                                fileIdToPosMap: result.params["fileIdToPosMap"]
                                    as Map<int, int>,
                                heroTag: "searchable_item" + result.heroTag(),
                                magicFilter:
                                    result.getHierarchicalSearchFilter()
                                        as MagicFilter,
                              ),
                            );
                          },
                        );
                      } else if (result is GenericSearchResult) {
                        return SearchableItemWidget(
                          result,
                          onResultTap: result.onResultTap != null
                              ? () => result.onResultTap!(context)
                              : null,
                        );
                      }
                      return SearchableItemWidget(result);
                    },
                    childCount: totalItems * 2 - 1,
                  ),
                ),
              ),
            );
          }
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            cacheExtent: cacheExtent,
            slivers: slivers,
          );
        },
      ),
    );
  }
}
