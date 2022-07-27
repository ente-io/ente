import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/search/collection_suggestion_widget_generator.dart';

class SearchResultsSuggestions extends StatelessWidget {
  final List<CollectionWithThumbnail> collectionsWithThumbnail;
  final List<File> matchedFiles;
  const SearchResultsSuggestions({
    Key key,
    this.collectionsWithThumbnail,
    this.matchedFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> suggestions = [];
    for (CollectionWithThumbnail c in collectionsWithThumbnail) {
      suggestions.add(CollectionSuggestionWidgetGenerator(c));
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
