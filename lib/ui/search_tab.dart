import "package:fade_indexed_stack/fade_indexed_stack.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/all_sections_examples_state.dart";
import "package:photos/states/search_results_state.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/no_result_widget.dart";
import "package:photos/ui/viewer/search/search_section.dart";
import "package:photos/ui/viewer/search/search_suggestions.dart";
import 'package:photos/ui/viewer/search/search_widget.dart';
import "package:photos/ui/viewer/search/tab_empty_state.dart";

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
    return AllSectionsExamplesProvider(
      child: FadeIndexedStack(
        duration: const Duration(milliseconds: 150),
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
  @override
  Widget build(BuildContext context) {
    final searchTypes = SectionType.values.toList(growable: true);
    // remove face and content sectionType
    searchTypes.remove(SectionType.face);
    searchTypes.remove(SectionType.content);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          FutureBuilder(
            future: InheritedAllSectionsExamples.of(context)
                .allSectionsExamplesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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
                    return SearchSection(
                      sectionType: searchTypes[index],
                      examples: snapshot.data!.elementAt(index),
                      limit: searchSectionLimit,
                    );
                  },
                )
                    .animate(
                      delay: const Duration(milliseconds: 150),
                    )
                    .slide(
                      begin: const Offset(0, -0.015),
                      end: const Offset(0, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )
                    .fadeIn(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                    );
              } else if (snapshot.hasError) {
                //Errors are handled and this else if condition will be false always
                //is the understanding.
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
          ValueListenableBuilder(
            valueListenable:
                InheritedAllSectionsExamples.of(context).isDebouncingNotifier,
            builder: (context, value, _) {
              return value
                  ? const EnteLoadingWidget(
                      alignment: Alignment.topRight,
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
