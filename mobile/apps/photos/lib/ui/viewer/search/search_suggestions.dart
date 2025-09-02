import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/index_of_indexed_stack.dart";
import 'package:photos/models/search/search_result.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/search/result/search_result_widget.dart";
import "package:photos/ui/viewer/search/search_widget.dart";
import "package:photos/utils/navigation_util.dart";

///Not using StreamBuilder in this widget for rebuilding on every new event as
///StreamBuilder is not lossless. It misses some events if the stream fires too
///fast. Instead, we usi a queue to store the events and then generate the
///widgets from the queue at regular intervals.
class SearchSuggestionsWidget extends StatefulWidget {
  const SearchSuggestionsWidget({
    super.key,
  });

  @override
  State<SearchSuggestionsWidget> createState() =>
      _SearchSuggestionsWidgetState();
}

class _SearchSuggestionsWidgetState extends State<SearchSuggestionsWidget> {
  Stream<List<SearchResult>>? resultsStream;
  final queueOfSearchResults = <List<SearchResult>>[];
  var searchResultWidgets = <Widget>[];
  StreamSubscription<List<SearchResult>>? subscription;
  Timer? timer;

  ///This is the interval at which the queue is checked for new events and
  ///the search result widgets are generated from the queue.
  static const _surfaceNewResultsInterval = 50;

  @override
  void initState() {
    super.initState();
    SearchWidgetState.searchResultsStreamNotifier.addListener(() {
      IndexOfStackNotifier().searchState = SearchState.searching;
      final resultsStream = SearchWidgetState.searchResultsStreamNotifier.value;

      searchResultWidgets.clear();
      releaseResources();

      subscription = resultsStream!.listen(
        (searchResults) {
          //Currently, we add searchResults even if the list is empty. So we are adding
          //empty list to the queue, which will trigger rebuilds with no change in UI
          //(see [generateResultWidgetsInIntervalsFromQueue]'s setState()).
          //This is needed to clear the search results in this widget when the
          //search bar is cleared, and the event fired by the stream will be an
          //empty list. Can optimize rebuilds if there are performance issues in future.
          if (searchResults.isNotEmpty) {
            IndexOfStackNotifier().searchState = SearchState.notEmpty;
          }
          queueOfSearchResults.add(searchResults);
        },
        onDone: () {
          Future.delayed(
              const Duration(milliseconds: _surfaceNewResultsInterval + 20),
              () {
            if (searchResultWidgets.isEmpty) {
              IndexOfStackNotifier().searchState = SearchState.empty;
            }
          });
          SearchWidgetState.isLoading.value = false;
        },
      );

      generateResultWidgetsInIntervalsFromQueue();
    });
  }

  void releaseResources() {
    subscription?.cancel();
    timer?.cancel();
  }

  ///This method generates searchResultsWidgets from the queueOfEvents by checking
  ///every [_surfaceNewResultsInterval] if the queue is empty or not. If the
  ///queue is not empty, it generates the widgets and clears the queue and
  ///updates the UI.
  void generateResultWidgetsInIntervalsFromQueue() {
    timer = Timer.periodic(
        const Duration(milliseconds: _surfaceNewResultsInterval), (timer) {
      if (queueOfSearchResults.isNotEmpty) {
        for (List<SearchResult> event in queueOfSearchResults) {
          for (SearchResult result in event) {
            searchResultWidgets.add(
              SearchResultsWidgetGenerator(result).animate().fadeIn(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeIn,
                  ),
            );
          }
        }
        queueOfSearchResults.clear();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    releaseResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title;
    final resultsCount = searchResultWidgets.length;
    title = AppLocalizations.of(context).searchResultCount(count: resultsCount);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Bus.instance.fire(ClearAndUnfocusSearchBar());
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: SearchWidgetState.isLoading.value
                  ? EnteLoadingWidget(
                      size: 14,
                      padding: 4,
                      color: getEnteColorScheme(context).strokeMuted,
                      alignment: Alignment.topLeft,
                    )
                  : Text(
                      title,
                      style: getEnteTextTheme(context).largeBold,
                    ).animate().fadeIn(
                        duration: const Duration(milliseconds: 60),
                        curve: Curves.easeIn,
                      ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    return searchResultWidgets[index];
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemCount: searchResultWidgets.length,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: (MediaQuery.sizeOf(context).height / 2) + 50,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultsWidgetGenerator extends StatelessWidget {
  final SearchResult result;
  const SearchResultsWidgetGenerator(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    if (result is AlbumSearchResult) {
      final AlbumSearchResult albumSearchResult = result as AlbumSearchResult;
      return SearchResultWidget(
        result,
        resultCount: CollectionsService.instance.getFileCount(
          albumSearchResult.collectionWithThumbnail.collection,
        ),
        onResultTap: () => routeToPage(
          context,
          CollectionPage(
            albumSearchResult.collectionWithThumbnail,
            tagPrefix: result.heroTag(),
          ),
        ),
      );
    } else if (result is GenericSearchResult) {
      return SearchResultWidget(
        result,
        onResultTap: (result as GenericSearchResult).onResultTap != null
            ? () => (result as GenericSearchResult).onResultTap!(context)
            : null,
      );
    } else {
      Logger('SearchResultsWidgetGenerator').info("Invalid/Unsupported value");
      return const SizedBox.shrink();
    }
  }
}
