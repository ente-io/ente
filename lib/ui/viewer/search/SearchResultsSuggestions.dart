import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';

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
    return CollectionSuggestions();
  }
}

class CollectionSuggestions extends StatelessWidget {
  const CollectionSuggestions({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('test');
  }
}
