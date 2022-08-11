import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/collection_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/filename_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/location_result_widget.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final List<SearchResult> results;
  const SearchSuggestionsWidget(
    this.results, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.searchResultsColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: -3,
              blurRadius: 6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemCount: results.length + 1,
              itemBuilder: (context, index) {
                if (results.length == index) {
                  return Container(
                    height: 6,
                    color: Theme.of(context).colorScheme.searchResultsColor,
                  );
                }
                final result = results[index];
                if (result is AlbumSearchResult) {
                  return AlbumSearchResultWidget(result);
                } else if (result is LocationSearchResult) {
                  return LocationSearchResultWidget(result);
                } else if (result is FileSearchResult) {
                  return FileSearchResultWidget(result);
                } else {
                  Logger('SearchSuggestionsWidget')
                      .info("Invalid/Unsupported value");
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
