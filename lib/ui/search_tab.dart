import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/search_results_state.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/no_result_widget.dart";
import "package:photos/ui/viewer/search/search_section.dart";
import "package:photos/ui/viewer/search/search_suggestions.dart";
import "package:photos/ui/viewer/search/search_widget_new.dart";
import "package:photos/ui/viewer/search/tab_empty_state.dart";

Future<List<List<SearchResult>>> allSectionsExamplesFuture = Future.value([]);

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
  final allSectionsExamples = <Future<List<SearchResult>>>[];
  late StreamSubscription<SyncStatusUpdate> _syncStatusSubscription;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _syncStatusSubscription =
          Bus.instance.on<SyncStatusUpdate>().listen((event) {
        if (event.status == SyncStatus.completedBackup) {
          setState(() {
            allSectionsExamples.clear();
            aggregateSectionsExamples();
          });
        }
      });
      setState(() {
        aggregateSectionsExamples();
      });
    });
  }

  void aggregateSectionsExamples() {
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
  void dispose() {
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchTypes = SectionType.values.toList(growable: true);
    // remove face and content sectionType
    searchTypes.remove(SectionType.face);
    searchTypes.remove(SectionType.content);
    return FutureBuilder(
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
                  ? const SizedBox.shrink()
                  //Recents is in WIP
                  // ? RecentSection(
                  //     searches: snapshot.data!.elementAt(index),
                  //   )
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
    );
  }
}
