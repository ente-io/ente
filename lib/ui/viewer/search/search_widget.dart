import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/no_result_widget.dart';
import 'package:photos/ui/viewer/search/search_suffix_icon_widget.dart';
import 'package:photos/ui/viewer/search/search_suggestions.dart';
import 'package:photos/utils/date_time_util.dart';
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
  final _debouncer = Debouncer(const Duration(milliseconds: 200));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        color: Colors.black.withOpacity(0.32),
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
                        hintText:
                            'Search for albums, places, holidays, months & years',
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
                        suffixIcon: ValueListenableBuilder(
                          valueListenable: _debouncer._debounceNotifier,
                          builder: (
                            BuildContext context,
                            Timer debounce,
                            Widget child,
                          ) {
                            return SearchSuffixIcon(debounce);
                          },
                        ),
                      ),
                      onChanged: (value) async {
                        final List<SearchResult> allResults =
                            await getSearchResultsForQuery(value);
                        if (mounted) {
                          setState(() {
                            _query = value;
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
    _debouncer.cancel();
    super.dispose();
  }

  Future<List<SearchResult>> getSearchResultsForQuery(String query) async {
    final List<SearchResult> allResults = [];
    if (query.isEmpty) {
      if (_debouncer._debounceTimer != null &&
          _debouncer._debounceTimer.isActive) {
        _debouncer._debounceTimer.cancel();
      }
      return (allResults);
    }

    final Completer<List<SearchResult>> completer = Completer();

    _debouncer.run(() async {
      final queryAsIntForYear = int.tryParse(query);
      if (_isYearValid(queryAsIntForYear)) {
        final yearResult =
            await _searchService.getYearSearchResults(queryAsIntForYear);
        allResults.add(yearResult); //only one year will be returned
      }

      final holidayResults =
          await _searchService.getHolidaySearchResults(query);
      allResults.addAll(holidayResults);

      final collectionResults =
          await _searchService.getCollectionSearchResults(query);
      allResults.addAll(collectionResults);

      final locationResults =
          await _searchService.getLocationSearchResults(query);
      allResults.addAll(locationResults);

      final monthResults = await _searchService.getMonthSearchResults(query);
      allResults.addAll(monthResults);

      completer.complete(allResults);
    });

    return completer.future;
  }

  bool _isYearValid(int year) {
    return year != null && year >= 1970 && year <= currentYear;
  }
}

class Debouncer {
  final Duration duration;
  Timer _debounceTimer;
  final ValueNotifier<Timer> _debounceNotifier = ValueNotifier(null);
  Debouncer(this.duration);

  run(Function fn) {
    if (_debounceTimer != null && _debounceTimer.isActive) {
      _debounceTimer.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 250), fn);
    _debounceNotifier.value = _debounceTimer;
  }

  cancel() {
    if (_debounceTimer != null) {
      _debounceTimer.cancel();
    }
  }
}
