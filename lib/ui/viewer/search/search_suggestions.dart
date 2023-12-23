import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import 'package:photos/models/search/search_result.dart';
import "package:photos/services/collections_service.dart";
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
    Key? key,
  }) : super(key: key);

  @override
  State<SearchSuggestionsWidget> createState() =>
      _SearchSuggestionsWidgetState();
}

class _SearchSuggestionsWidgetState extends State<SearchSuggestionsWidget> {
  Stream<List<SearchResult>>? resultsStream;
  final queueOfEvents = <List<SearchResult>>[];
  var searchResultWidgets = <Widget>[];
  StreamSubscription<List<SearchResult>>? subscription;
  Timer? timer;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   searchResultWidgets.clear();
  //   releaseResources();
  //   resultsStream = InheritedSearchResults.of(context).searchResultsStream;
  //   subscription = resultsStream?.listen((event) {
  //     if (event.isNotEmpty) {
  //       //update a index value notifier for indexed stack here and rebuild the indexedStack widget.
  //       //Also, add dependecy to inherited widget on changing stream in this widget and not on the serach tab.
  //       queueOfEvents.add(event);
  //     }
  //   });
  //   generateResultWidgetsInIntervalsFromQueue();
  // }

  @override
  void initState() {
    super.initState();
    SearchWidgetState.searchResultsStreamNotifier.addListener(() {
      final value = SearchWidgetState.searchResultsStreamNotifier.value;
      searchResultWidgets.clear();
      releaseResources();
      resultsStream = value;
      subscription = resultsStream?.listen((event) {
        if (event.isNotEmpty) {
          //update a index value notifier for indexed stack here and rebuild the indexedStack widget.
          //Also, add dependecy to inherited widget on changing stream in this widget and not on the serach tab.
          queueOfEvents.add(event);
        }
      });
      generateResultWidgetsInIntervalsFromQueue();
    });
  }

  void releaseResources() {
    subscription?.cancel();
    timer?.cancel();
  }

  ///This method generates searchResultsWidgets from the queueOfEvents by checking
  ///every 60ms if the queue is empty or not. If the queue is not empty, it
  ///generates the widgets and clears the queue and updates the UI.
  void generateResultWidgetsInIntervalsFromQueue() {
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (queueOfEvents.isNotEmpty) {
        for (List<SearchResult> event in queueOfEvents) {
          for (SearchResult result in event) {
            searchResultWidgets.add(
              SearchResultsWidgetGenerator(result).animate().fadeIn(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeIn,
                  ),
            );
          }
        }
        queueOfEvents.clear();
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
    print(
      "_______ rebuiding SearchSuggestionWidget with stream : ${resultsStream.hashCode}",
    );
    // return const SizedBox.shrink();
    // late final String title;
    // final resultsCount = results.length;
    // title = S.of(context).searchResultCount(resultsCount);
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
            //     // Text(
            //     //   title,
            //     //   style: getEnteTextTheme(context).largeBold,
            //     // ),
            //     const SizedBox(height: 20),
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
