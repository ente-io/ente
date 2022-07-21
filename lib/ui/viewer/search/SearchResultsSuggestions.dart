import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/ui/viewer/search/collectionSuggestions.dart';

class SearchResultsSuggestions extends StatefulWidget {
  final Map<String, Set> collectionIDs;
  const SearchResultsSuggestions({Key key, this.collectionIDs})
      : super(key: key);

  @override
  State<SearchResultsSuggestions> createState() =>
      _SearchResultsSuggestionsState();
}

class _SearchResultsSuggestionsState extends State<SearchResultsSuggestions> {
  @override
  Widget build(BuildContext context) {
    List<Widget> p1suggestions = [];
    p1suggestions = CollectionSuggestions(widget.collectionIDs)
        .getSuggestions(); //add other p1 suggestions to this
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: ListView.builder(
        itemCount: p1suggestions.length,
        itemBuilder: (context, index) {
          return p1suggestions[index];
        },
      ),
    );
  }
}
