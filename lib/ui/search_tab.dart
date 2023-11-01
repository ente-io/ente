import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/search_results_state.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/no_result_widget.dart";
import "package:photos/ui/viewer/search/search_section.dart";
import "package:photos/ui/viewer/search/search_suggestions.dart";
import "package:photos/ui/viewer/search/search_widget_new.dart";
import "package:photos/ui/viewer/search/tab_empty_state.dart";

late Future<List<List<SearchResult>>> allSectionsExamplesFuture;

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  var _searchResults = <SearchResult>[];
  int index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchResults = InheritedSearchResults.of(context).results;
    if (_searchResults.isEmpty) {
      if (isSearchQueryEmpty) {
        index = 0;
      } else {
        index = 2;
      }
    } else {
      index = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IndexedStack(
        index: index,
        children: [
          const AllSearchSections(),
          SearchSuggestionsWidget(_searchResults),
          const NoResultWidget(),
        ],
      ),
    );
  }
}

class AllSearchSections extends StatefulWidget {
  const AllSearchSections({super.key});

  @override
  State<AllSearchSections> createState() => _AllSearchSectionsState();
}

class _AllSearchSectionsState extends State<AllSearchSections> {
  late List<Future<List<SearchResult>>> allSectionsExamples;

  @override
  void initState() {
    super.initState();
    allSectionsExamples = <Future<List<SearchResult>>>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (SectionType sectionType in SectionType.values) {
      if (sectionType == SectionType.face ||
          sectionType == SectionType.content) {
        continue;
      }
      allSectionsExamples.add(
        sectionType.getData(limit: searchSectionLimit, context: context),
      );
    }
    allSectionsExamplesFuture =
        Future.wait<List<SearchResult>>(allSectionsExamples);
  }

  @override
  Widget build(BuildContext context) {
    // Return a ListViewBuilder for value search_types.dart SectionType,
    // render search section for each value
    final searchTypes = SectionType.values.toList(growable: true);
    // remove face and content sectionType
    searchTypes.remove(SectionType.face);
    searchTypes.remove(SectionType.content);
    return Expanded(
      child: Stack(
        children: [
          FutureBuilder(
            future: allSectionsExamplesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.every((element) => element.isEmpty)) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: SearchTabEmptyState(),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 180),
                  physics: const BouncingScrollPhysics(),
                  itemCount: searchTypes.length,
                  itemBuilder: (context, index) {
                    return searchTypes[index] == SectionType.recents
                        ? const RecentSection()
                        : SearchSection(
                            sectionType: searchTypes[index],
                            examples: snapshot.data!.elementAt(index),
                            limit: searchSectionLimit,
                          );
                  },
                );
              } else if (snapshot.hasError) {
                //todo: Show something went wrong here
                return const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: EnteLoadingWidget(),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: EnteLoadingWidget(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
