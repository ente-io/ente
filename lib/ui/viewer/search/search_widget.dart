import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/search/search_result.dart';
import 'package:photos/services/search_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/map_screen.dart";
import 'package:photos/ui/viewer/search/result/no_result_widget.dart';
import 'package:photos/ui/viewer/search/search_suffix_icon_widget.dart';
import 'package:photos/ui/viewer/search/search_suggestions.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/debouncer.dart';
import 'package:photos/utils/navigation_util.dart';

class SearchIconWidget extends StatefulWidget {
  const SearchIconWidget({Key? key}) : super(key: key);

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
      child: IconButtonWidget(
        iconButtonType: IconButtonType.primary,
        icon: Icons.search,
        onTap: () {
          Navigator.push(
            context,
            TransparentRoute(
              builder: (BuildContext context) => const SearchWidget(),
            ),
          );
        },
      ),
    );
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({Key? key}) : super(key: key);

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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    color: Theme.of(context).colorScheme.defaultBackgroundColor,
                    child: TextFormField(
                      style: Theme.of(context).textTheme.titleMedium,
                      // Below parameters are to disable auto-suggestion
                      enableSuggestions: false,
                      autocorrect: false,
                      // Above parameters are to disable auto-suggestion
                      decoration: InputDecoration(
                        hintText: S.of(context).searchHintText,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          maxHeight: 44,
                          maxWidth: 44,
                          minHeight: 44,
                          minWidth: 44,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          maxHeight: 44,
                          maxWidth: 44,
                          minHeight: 44,
                          minWidth: 44,
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
                            Widget? child,
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
                            await getSearchResultsForQuery(context, value);
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
                        : const NavigateToMap(),
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

  Future<List<SearchResult>> getSearchResultsForQuery(
    BuildContext context,
    String query,
  ) async {
    final Completer<List<SearchResult>> completer = Completer();

    _debouncer.run(
      () {
        return _getSearchResultsFromService(context, query, completer);
      },
    );

    return completer.future;
  }

  Future<void> _getSearchResultsFromService(
    BuildContext context,
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
      await _searchService.getHolidaySearchResults(context, query);
      allResults.addAll(holidayResults);

      final fileTypeSearchResults =
          await _searchService.getFileTypeResults(query);
      allResults.addAll(fileTypeSearchResults);

      final captionAndDisplayNameResult =
          await _searchService.getCaptionAndNameResults(query);
      allResults.addAll(captionAndDisplayNameResult);

      final fileExtnResult =
          await _searchService.getFileExtensionResults(query);
      allResults.addAll(fileExtnResult);

      final locationResult = await _searchService.getLocationResults(query);
      allResults.addAll(locationResult);

      final collectionResults =
          await _searchService.getCollectionSearchResults(query);
      allResults.addAll(collectionResults);

      final monthResults =
          await _searchService.getMonthSearchResults(context, query);
      allResults.addAll(monthResults);

      final possibleEvents =
          await _searchService.getDateResults(context, query);
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

class NavigateToMap extends StatelessWidget {
  const NavigateToMap({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: IconButtonWidget(
        icon: Icons.map_sharp,
        iconButtonType: IconButtonType.primary,
        defaultColor: colorScheme.backgroundElevated,
        pressedColor: colorScheme.backgroundElevated2,
        size: 28,
        onTap: () async {
          final bool result = await requestForMapEnable(context);
          if (result) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  filesFutureFn: SearchService.instance.getAllFiles,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
