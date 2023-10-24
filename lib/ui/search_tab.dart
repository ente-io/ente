import "package:flutter/material.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/search_results_state.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/no_result_widget.dart";
import "package:photos/ui/viewer/search/search_section.dart";
import "package:photos/ui/viewer/search/search_suggestions.dart";
import "package:photos/ui/viewer/search/search_widget_new.dart";

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  // Focus nodes are necessary
  String _email = '';
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();
  var _searchResults = <SearchResult>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchResults = InheritedSearchResults.of(context).results;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _searchResults.isEmpty
          ? isSearchQueryEmpty
              ? const AllSearchSections()
              : const NoResultWidget()
          : SearchSuggestionsWidget(_searchResults),
    );
  }

  void clearFocus() {
    _textController.clear();
    _email = _textController.text;

    textFieldFocusNode.unfocus();
    setState(() => {});
  }
}

class AllSearchSections extends StatefulWidget {
  const AllSearchSections({super.key});

  @override
  State<AllSearchSections> createState() => _AllSearchSectionsState();
}

class _AllSearchSectionsState extends State<AllSearchSections> {
  late Future<List<List<SearchResult>>> allSectionsExamples;
  late List<Future<List<SearchResult>>> sectionExamples;
  static const _limit = 7;

  @override
  void initState() {
    super.initState();
    sectionExamples = <Future<List<SearchResult>>>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (SectionType sectionType in SectionType.values) {
      if (sectionType == SectionType.face ||
          sectionType == SectionType.content) {
        continue;
      }
      sectionExamples.add(sectionType.getData(limit: _limit, context: context));
    }
    allSectionsExamples = Future.wait<List<SearchResult>>(sectionExamples);
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
            future: allSectionsExamples,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 180),
                  physics: const BouncingScrollPhysics(),
                  itemCount: searchTypes.length,
                  itemBuilder: (context, index) {
                    return SearchSection(
                      sectionType: searchTypes[index],
                      examples: snapshot.data!.elementAt(index),
                      limit: _limit,
                    );
                  },
                );
              } else if (snapshot.hasError) {
                //todo: Show something went wrong here
                return const EnteLoadingWidget();
              } else {
                return const EnteLoadingWidget();
              }
            },
          ),
        ],
      ),
    );
  }
}
