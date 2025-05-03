import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/events/event.dart";
import "package:photos/extensions/list.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/hierarchical/magic_filter.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import "package:photos/ui/viewer/search/result/searchable_item.dart";
import "package:photos/utils/navigation_util.dart";

class SearchSectionAllPage extends StatefulWidget {
  final SectionType sectionType;
  const SearchSectionAllPage({required this.sectionType, super.key});

  @override
  State<SearchSectionAllPage> createState() => _SearchSectionAllPageState();
}

class _SearchSectionAllPageState extends State<SearchSectionAllPage> {
  late Future<List<SearchResult>> sectionData;
  final streamSubscriptions = <StreamSubscription>[];

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

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleBarTitleWidget(
                  title: widget.sectionType.sectionTitle(context),
                ),
                FutureBuilder(
                  future: sectionData,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final sectionResults = snapshot.data!;
                      return Text(sectionResults.length.toString())
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeIn,
                          );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              child: FutureBuilder(
                future: sectionData,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<SearchResult> sectionResults = snapshot.data!;

                    if (widget.sectionType.sortByName) {
                      sectionResults.sort(
                        (a, b) =>
                            compareAsciiLowerCaseNatural(a.name(), b.name()),
                      );
                    }

                    if (widget.sectionType == SectionType.location) {
                      final result = sectionResults.splitMatch(
                        (e) => e.type() == ResultType.location,
                      );
                      sectionResults = result.matched;
                      sectionResults.addAll(result.unmatched);
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        if (sectionResults.length == index) {
                          return SearchableItemPlaceholder(
                            widget.sectionType,
                          );
                        }
                        if (sectionResults[index] is AlbumSearchResult) {
                          final albumSectionResult =
                              sectionResults[index] as AlbumSearchResult;
                          return SearchableItemWidget(
                            albumSectionResult,
                            resultCount:
                                CollectionsService.instance.getFileCount(
                              albumSectionResult
                                  .collectionWithThumbnail.collection,
                            ),
                            onResultTap: () {
                              RecentSearches()
                                  .add(sectionResults[index].name());

                              routeToPage(
                                context,
                                CollectionPage(
                                  albumSectionResult.collectionWithThumbnail,
                                  tagPrefix: "searchable_item" +
                                      albumSectionResult.heroTag(),
                                ),
                              );
                            },
                          );
                        }

                        if (widget.sectionType == SectionType.magic) {
                          final magicSectionResult =
                              sectionResults[index] as GenericSearchResult;
                          return SearchableItemWidget(
                            magicSectionResult,
                            onResultTap: () {
                              RecentSearches()
                                  .add(sectionResults[index].name());
                              routeToPage(
                                context,
                                MagicResultScreen(
                                  magicSectionResult.resultFiles(),
                                  name: magicSectionResult.name(),
                                  enableGrouping: magicSectionResult
                                      .params["enableGrouping"]! as bool,
                                  fileIdToPosMap: magicSectionResult
                                          .params["fileIdToPosMap"]
                                      as Map<int, int>,
                                  heroTag: "searchable_item" +
                                      magicSectionResult.heroTag(),
                                  magicFilter: magicSectionResult
                                          .getHierarchicalSearchFilter()
                                      as MagicFilter,
                                ),
                              );
                            },
                          );
                        } else if (sectionResults[index]
                            is GenericSearchResult) {
                          final result =
                              sectionResults[index] as GenericSearchResult;
                          return SearchableItemWidget(
                            sectionResults[index],
                            onResultTap: result.onResultTap != null
                                ? () => result.onResultTap!(context)
                                : null,
                          );
                        }
                        return SearchableItemWidget(
                          sectionResults[index],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 10);
                      },
                      itemCount: sectionResults.length +
                          (widget.sectionType.isCTAVisible ? 1 : 0),
                      physics: const BouncingScrollPhysics(),
                      //This cache extend is needed for creating a new album
                      //using SearchSectionCTATile to work. This is so that
                      //SearchSectionCTATile doesn't get disposed when keyboard
                      //is open and the widget is out of view.
                      cacheExtent:
                          widget.sectionType == SectionType.album ? 400 : null,
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 225),
                          curve: Curves.easeIn,
                        )
                        .slide(
                          begin: const Offset(0, -0.01),
                          curve: Curves.easeIn,
                          duration: const Duration(
                            milliseconds: 225,
                          ),
                        );
                  } else {
                    return const EnteLoadingWidget();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
