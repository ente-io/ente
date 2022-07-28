import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/search/collection_result_widget.dart';
import 'package:photos/ui/viewer/search/filename_result_widget.dart';

class SearchResultsSuggestions extends StatelessWidget {
  final List<CollectionWithThumbnail> collectionsWithThumbnail;
  final List<File> matchedFiles;
  const SearchResultsSuggestions(
    this.collectionsWithThumbnail,
    this.matchedFiles, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> suggestions = [];
    for (CollectionWithThumbnail c in collectionsWithThumbnail) {
      suggestions.add(c);
    }
    for (File file in matchedFiles) {
      suggestions.add(file);
    }
    suggestions.shuffle();
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          dynamic value = suggestions[index];
          if (value is File) {
            return FilenameResultWidget(value);
          } else if (value is CollectionWithThumbnail) {
            return CollectionResultWidget(value);
          } else {
            throw StateError("Invalid/Unsupported value");
          }
        },
      ),
    );
  }
}
