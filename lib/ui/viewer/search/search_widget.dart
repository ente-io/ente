import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/holiday_search_result.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/models/search/year_search_result.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/ui/viewer/search/search_suggestions.dart';
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
  final String searchQuery = '';
  const SearchWidget({Key key}) : super(key: key);
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final List<SearchResult> results = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              color: Theme.of(context).colorScheme.defaultBackgroundColor,
              child: TextFormField(
                style: Theme.of(context).textTheme.subtitle1,
                decoration: InputDecoration(
                  hintText: 'Search for albums, places & files',
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
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
                  suffixIcon: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context)
                          .colorScheme
                          .iconColor
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                onChanged: (value) async {
                  final List<SearchResult> allResults =
                      await getSearchResultsForQuery(value);
                  if (mounted) {
                    setState(() {
                      results.clear();
                      results.addAll(allResults);
                    });
                  }
                },
                autofocus: true,
              ),
            ),
            results.isNotEmpty
                ? SearchSuggestionsWidget(results)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Future<List<SearchResult>> getSearchResultsForQuery(String query) async {
    final List<SearchResult> allResults = [];

    final queryAsIntForYear = int.tryParse(query);
    if (isYearValid(queryAsIntForYear)) {
      final yearResults =
          await SearchService.instance.getYearSearchResults(queryAsIntForYear);
      if (yearResults.isNotEmpty) {
        allResults.add(YearSearchResult(queryAsIntForYear, yearResults));
      }
    }

    final holidayResults =
        SearchService.instance.getHolidaySearchResults(query);
    for (HolidaySearchResult holidayResult in holidayResults) {
      allResults.add(holidayResult);
    }

    final collectionResults =
        await SearchService.instance.getCollectionSearchResults(query);
    for (CollectionWithThumbnail collectionResult in collectionResults) {
      allResults.add(AlbumSearchResult(collectionResult));
    }

    final locationResults =
        await SearchService.instance.getLocationSearchResults(query);
    for (LocationSearchResult result in locationResults) {
      allResults.add(result);
    }

    final fileResults =
        await SearchService.instance.getFileSearchResults(query);
    for (File file in fileResults) {
      allResults.add(FileSearchResult(file));
    }

    return allResults;
  }

  bool isYearValid(int year) {
    return year != null &&
        year >= 1970 &&
        year <= int.parse(DateTime.now().year.toString());
  }
}
