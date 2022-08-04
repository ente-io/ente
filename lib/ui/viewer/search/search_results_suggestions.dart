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
    List<Widget> suggestions = [];
    for (CollectionWithThumbnail c in matchedCollectionsWithThumbnail) {
      suggestions.add(CollectionResultWidget(c));
    }
    for (File file in matchedFiles) {
      suggestions.add(FilenameResultWidget(file));
    }
    for (MapEntry<String, List<File>> locationToFilesMapEntry
        in locationsToMatchedFiles.entries) {
      Map<String, List<File>> locationToFilesMap = {
        locationToFilesMapEntry.key: locationToFilesMapEntry.value
      };
      suggestions.add(LocationResultsWidget(locationToFilesMap));
    }
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return suggestions[index];
        },
      ),
    );
  }
}
