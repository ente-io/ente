// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/search_result.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/ui/viewer/search/result/no_result_widget.dart';
import 'package:photos/ui/viewer/search/search_suffix_icon_widget.dart';
import 'package:photos/ui/viewer/search/search_suggestions.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/debouncer.dart';
import 'package:photos/utils/navigation_util.dart';

class SearchIconWidget extends StatefulWidget {
  const SearchIconWidget({Key key}) : super(key: key);

  @override
  State<SearchIconWidget> createState() => _SearchIconWidgetState();
}

class _SearchIconWidgetState extends State<SearchIconWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "search_icon",
      child: IconButton(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        onPressed: () {
          Navigator.push(
            context,
            TransparentRoute(
              builder: (BuildContext context) => const SearchWidget(),
            ),
          );
        },
        icon: const Icon(Icons.search),
      ),
    );
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({Key key}) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  String _query = "";
  final List<SearchResult> _results = [];
  final _searchService = SearchService.instance;
  final _debouncer = Debouncer(const Duration(milliseconds: 100));
  final Logger _logger = Logger((_SearchWidgetState).toString());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        color: Theme.of(context).colorScheme.searchResultsBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Theme.of(context).colorScheme.defaultBackgroundColor,
                    child: TextFormField(
                      style: Theme.of(context).textTheme.subtitle1,
                      // Below parameters are to disable auto-suggestion
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.visiblePassword,
                      // Above parameters are to disable auto-suggestion
                      decoration: InputDecoration(
                        hintText: "Albums, months, days, years, ...",
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .iconColor
                                .withOpacity(0.5),
                          ),
                        ),
                        /*Using valueListenableBuilder inside a stateful widget because this widget is only rebuild when
                        setState is called when deboucncing is over and the spinner needs to be shown while debouncing */
                        suffixIcon: ValueListenableBuilder(
                          valueListenable: _debouncer.debounceActiveNotifier,
                          builder: (
                            BuildContext context,
                            bool isDebouncing,
                            Widget child,
                          ) {
                            return SearchSuffixIcon(
                              isDebouncing,
                            );
                          },
                        ),
                      ),
                      onChanged: (value) async {
                        _query = value;
                        final List<SearchResult> allResults =
                            await getSearchResultsForQuery(value);
                        /*checking if _query == value to make sure that the results are from the current query
                        and not from the previous query (race condition).*/
                        if (mounted && _query == value) {
                          setState(() {
                            _results.clear();
                            _results.addAll(allResults);
                          });
                        }
                      },
                      autofocus: true,
                    ),
                  ),
                ),
                _results.isNotEmpty
                    ? SearchSuggestionsWidget(_results)
                    : _query.isNotEmpty
                        ? const NoResultWidget()
                        : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.cancelDebounce();
    super.dispose();
  }

  Future<List<SearchResult>> getSearchResultsForQuery(String query) async {
    final Completer<List<SearchResult>> completer = Completer();

    _debouncer.run(
      () {
        return _getSearchResultsFromService(query, completer);
      },
    );

    return completer.future;
  }

  Future<void> _getSearchResultsFromService(
    String query,
    Completer completer,
  ) async {
    final List<SearchResult> allResults = [];
    if (query.isEmpty) {
      completer.complete(allResults);
      return;
    }
    try {
      if (_isYearValid(query)) {
        final yearResults = await _searchService.getYearSearchResults(query);
        allResults.addAll(yearResults);
      }

      final holidayResults =
          await _searchService.getHolidaySearchResults(query);
      allResults.addAll(holidayResults);

      final fileTypeSearchResults =
          await _searchService.getFileTypeResults(query);
      allResults.addAll(fileTypeSearchResults);

      final fileExtnResult =
          await _searchService.getFileExtensionResults(query);
      allResults.addAll(fileExtnResult);

      final collectionResults =
          await _searchService.getCollectionSearchResults(query);
      allResults.addAll(collectionResults);

      if (FeatureFlagService.instance.isInternalUserOrDebugBuild() &&
          query.startsWith("l:")) {
        final locationResults = await _searchService
            .getLocationSearchResults(query.replaceAll("l:", ""));
        allResults.addAll(locationResults);
      }

      final monthResults = await _searchService.getMonthSearchResults(query);
      allResults.addAll(monthResults);

      final possibleEvents = await _searchService.getDateResults(query);
      allResults.addAll(possibleEvents);
    } catch (e, s) {
      _logger.severe("error during search", e, s);
    }
    completer.complete(allResults);
  }

  bool _isYearValid(String year) {
    final yearAsInt = int.tryParse(year); //returns null if cannot be parsed
    return yearAsInt != null && yearAsInt <= currentYear;
  }
}
