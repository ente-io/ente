import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/collection_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/filename_result_widget.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/location_result_widget.dart';

class SearchResultsSuggestions extends StatelessWidget {
  final List<CollectionWithThumbnail> matchedCollectionsWithThumbnail;
  final List<File> matchedFiles;
  final Map<String, List<File>> locationsToMatchedFiles;
  const SearchResultsSuggestions(
    this.matchedCollectionsWithThumbnail,
    this.matchedFiles,
    this.locationsToMatchedFiles, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> suggestions = [];
    for (CollectionWithThumbnail c in matchedCollectionsWithThumbnail) {
      suggestions.add(c);
    }
    for (File file in matchedFiles) {
      suggestions.add(file);
    }
    for (MapEntry<String, List<File>> locationAndFiles
        in locationsToMatchedFiles.entries) {
      suggestions.add(locationAndFiles);
    }
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          dynamic value = suggestions[index];
          if (value is CollectionWithThumbnail) {
            return CollectionResultWidget(value);
          } else if (value is File) {
            return FilenameResultWidget(value);
          } else if (value is MapEntry<String, List<File>>) {
            return LocationResultsWidget(value);
          } else {
            throw StateError("Invalid/Unsupported value");
          }
        },
      ),
    );
  }
}
