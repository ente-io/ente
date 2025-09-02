import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/index_of_indexed_stack.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/search_suffix_icon_widget.dart";
import "package:photos/utils/standalone/date_time.dart";
import "package:photos/utils/standalone/debouncer.dart";

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  static final ValueNotifier<Stream<List<SearchResult>>?>
      searchResultsStreamNotifier = ValueNotifier(null);

  ///This stores the query that is being searched for. When going to other tabs
  ///when searching, this state gets disposed and when coming back to the
  ///search tab, this query is used to populate the search bar.
  static String query = "";
  //Debouncing + querying
  static final isLoading = ValueNotifier(false);
  final _searchService = SearchService.instance;
  final _debouncer = Debouncer(const Duration(milliseconds: 200));
  late FocusNode focusNode;
  StreamSubscription<TabDoubleTapEvent>? _tabDoubleTapEvent;
  double _bottomPadding = 0.0;
  double _distanceOfWidgetFromBottom = 0;
  GlobalKey widgetKey = GlobalKey();
  TextEditingController textController = TextEditingController();
  late final StreamSubscription<ClearAndUnfocusSearchBar>
      _clearAndUnfocusSearchBar;
  late final Logger _logger = Logger("SearchWidgetState");

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    _tabDoubleTapEvent =
        Bus.instance.on<TabDoubleTapEvent>().listen((event) async {
      debugPrint("Firing now ${event.selectedIndex}");
      if (mounted && event.selectedIndex == 3) {
        focusNode.requestFocus();
      }
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      //This buffer is for doing this operation only after SearchWidget's
      //animation is complete.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final RenderBox box =
              widgetKey.currentContext!.findRenderObject() as RenderBox;
          final heightOfWidget = box.size.height;
          final offsetPosition = box.localToGlobal(Offset.zero);
          final y = offsetPosition.dy;
          final heightOfScreen = MediaQuery.sizeOf(context).height;
          _distanceOfWidgetFromBottom = heightOfScreen - (y + heightOfWidget);
        }
      });

      textController.addListener(textControllerListener);
    });

    //Populate the serach tab with the latest query when coming back
    //to the serach tab.
    textController.text = query;

    _clearAndUnfocusSearchBar =
        Bus.instance.on<ClearAndUnfocusSearchBar>().listen((event) {
      textController.clear();
      focusNode.unfocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //https://api.flutter.dev/flutter/dart-ui/FlutterView-class.html
    _bottomPadding =
        (MediaQuery.viewInsetsOf(context).bottom - _distanceOfWidgetFromBottom);
    if (_bottomPadding < 0) {
      _bottomPadding = 0;
    } else if (_bottomPadding != 0) {
      _bottomPadding += MediaQuery.viewPaddingOf(context).bottom;
    }
  }

  @override
  void dispose() {
    _debouncer.cancelDebounceTimer();
    focusNode.dispose();
    _tabDoubleTapEvent?.cancel();
    textController.removeListener(textControllerListener);
    textController.dispose();
    _clearAndUnfocusSearchBar.cancel();
    super.dispose();
  }

  Future<void> textControllerListener() async {
    isLoading.value = true;
    _debouncer.run(() async {
      if (mounted) {
        query = textController.text.trim();
        IndexOfStackNotifier().isSearchQueryEmpty = query.isEmpty;
        searchResultsStreamNotifier.value =
            _getSearchResultsStream(context, query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return RepaintBoundary(
      key: widgetKey,
      child: Padding(
        padding: EdgeInsets.only(bottom: _bottomPadding),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: colorScheme.backgroundBase,
                child: Container(
                  color: colorScheme.fillFaint,
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlignVertical: const TextAlignVertical(y: 0),
                    // Below parameters are to disable auto-suggestion
                    // Above parameters are to disable auto-suggestion
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).search,
                      filled: true,
                      fillColor: getEnteColorScheme(context).fillFaint,
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Hero(
                        tag: "search_icon",
                        child: Icon(
                          Icons.search,
                          color: colorScheme.strokeFaint,
                        ),
                      ),

                      /*Using valueListenableBuilder inside a stateful widget because this widget is only rebuild when
                      setState is called when deboucncing is over and the spinner needs to be shown while debouncing */
                      suffixIcon: ValueListenableBuilder(
                        valueListenable: isLoading,
                        builder: (
                          BuildContext context,
                          bool isSearching,
                          Widget? child,
                        ) {
                          return SearchSuffixIcon(
                            isSearching,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<SearchResult>> _getSearchResultsStream(
    BuildContext context,
    String query,
  ) {
    int resultCount = 0;
    final maxResultCount = _isYearValid(query) ? 12 : 11;
    final streamController = StreamController<List<SearchResult>>();

    if (query.isEmpty) {
      streamController.sink.add([]);
      streamController.close();
      return streamController.stream;
    }

    void onResultsReceived(List<SearchResult> results) {
      streamController.sink.add(results);
      resultCount++;
      if (resultCount == maxResultCount) {
        streamController.close();
      }
      if (resultCount > maxResultCount) {
        _logger.warning(
          "More results than expected. Expected: $maxResultCount, actual: $resultCount",
        );
      }
    }

    if (_isYearValid(query)) {
      _searchService.getYearSearchResults(query).then((yearSearchResults) {
        onResultsReceived(yearSearchResults);
      });
    }

    _searchService.getHolidaySearchResults(context, query).then(
      (holidayResults) {
        onResultsReceived(holidayResults);
      },
    );

    _searchService.getFileTypeResults(context, query).then(
      (fileTypeSearchResults) {
        onResultsReceived(fileTypeSearchResults);
      },
    );

    _searchService.getCaptionAndNameResults(query).then(
      (captionAndDisplayNameResult) {
        onResultsReceived(captionAndDisplayNameResult);
      },
    );

    _searchService.getFileExtensionResults(query).then(
      (fileExtnResult) {
        onResultsReceived(fileExtnResult);
      },
    );

    _searchService.getLocationResults(query).then(
      (locationResult) {
        onResultsReceived(locationResult);
      },
    );

    _searchService.getAllFace(null).then(
      (faceResult) {
        final List<GenericSearchResult> filteredResults = [];
        for (final result in faceResult) {
          if (result.name().toLowerCase().contains(query.toLowerCase())) {
            filteredResults.add(result);
          }
        }
        onResultsReceived(filteredResults);
      },
    );

    _searchService.getCollectionSearchResults(query).then(
      (collectionResults) {
        onResultsReceived(collectionResults);
      },
    );

    _searchService.getMonthSearchResults(context, query).then(
      (monthResults) {
        onResultsReceived(monthResults);
      },
    );

    _searchService.getDateResults(context, query).then(
      (possibleEvents) {
        onResultsReceived(possibleEvents);
      },
    );

    _searchService.getMagicSearchResults(context, query).then(
      (magicResults) {
        onResultsReceived(magicResults);
      },
    );

    _searchService.getContactSearchResults(query).then(
      (contactResults) {
        onResultsReceived(contactResults);
      },
    );

    return streamController.stream;
  }

  bool _isYearValid(String year) {
    final yearAsInt = int.tryParse(year); //returns null if cannot be parsed
    return yearAsInt != null && yearAsInt <= currentYear;
  }
}
