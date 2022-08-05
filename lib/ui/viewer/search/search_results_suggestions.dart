import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/collection_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/filename_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/location_result_widget.dart';

class SearchResultsSuggestionsWidget extends StatelessWidget {
  final List<SearchResult> results;
  const SearchResultsSuggestionsWidget(
    this.results, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.defaultBackgroundColor,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          if (result is AlbumSearchResult) {
            return CollectionResultWidget(result);
          } else if (result is FileSearchResult) {
            return FilenameResultWidget(result);
          } else if (result is LocationSearchResult) {
            return LocationResultsWidget(result);
          } else {
            throw StateError("Invalid/Unsupported value");
          }
        },
      ),
    );
  }
}
