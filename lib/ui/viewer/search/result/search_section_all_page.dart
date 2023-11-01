import "package:flutter/material.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/searchable_item.dart";
import "package:photos/utils/navigation_util.dart";

class SearchSectionAllPage extends StatefulWidget {
  final SectionType sectionType;
  const SearchSectionAllPage({required this.sectionType, super.key});

  @override
  State<SearchSectionAllPage> createState() => _SearchSectionAllPageState();
}

class _SearchSectionAllPageState extends State<SearchSectionAllPage> {
  late final Future<List<SearchResult>> sectionData;
  late final bool _showCTATile;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sectionData = widget.sectionType.getData(limit: null, context: context);
    _showCTATile = widget.sectionType.isCTAVisible;
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
      body: FutureBuilder(
        future: sectionData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final sectionResults = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleBarTitleWidget(
                        title: widget.sectionType.sectionTitle(context),
                      ),
                      Text(sectionResults!.length.toString()),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        if (sectionResults.length == index) {
                          return SearchableItemPlaceholder(widget.sectionType);
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
                              RecentSearches().add(sectionResults[index]);

                              routeToPage(
                                context,
                                CollectionPage(
                                  albumSectionResult.collectionWithThumbnail,
                                  tagPrefix: albumSectionResult.heroTag(),
                                ),
                              );
                            },
                          );
                        }
                        return SearchableItemWidget(sectionResults[index]);
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 10);
                      },
                      itemCount: sectionResults.length + (_showCTATile ? 1 : 0),
                      physics: const BouncingScrollPhysics(),
                      //This cache extend is needed for creating a new album
                      //using SearchSectionCTATile to work. This is so that
                      //SearchSectionCTATile doesn't get disposed when keyboard
                      //is open and the widget is out of view.
                      cacheExtent:
                          widget.sectionType == SectionType.album ? 400 : null,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const EnteLoadingWidget();
          }
        },
      ),
    );
  }
}
