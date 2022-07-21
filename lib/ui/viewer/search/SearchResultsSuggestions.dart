import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';

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

class CollectionSuggestions {
  final Map<String, Set> collectionIDs;
  const CollectionSuggestions(this.collectionIDs);

  List<Widget> getSuggestions() {
    List<int> p1IDs = collectionIDs['p1'].toList();
    List<int> p2IDs = collectionIDs['p2'].toList();
    List<int> p3IDs = collectionIDs['p3'].toList();
    List<Widget> collectionsP1 = [];
    List<Widget> collectionsP2 = [];
    List<Widget> collectionsP3 = [];
    Collection collection =
        CollectionsService.instance.getCollectionByID(p1IDs[0]);
    p1IDs.forEach(
      (element) {
        Collection collection =
            CollectionsService.instance.getCollectionByID(element);
        collectionsP1.add(
          Row(
            children: [
              Column(
                children: [
                  const Text('Album'),
                  Text(collection.name),
                  Text('10 memories'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_alarms),
                  Icon(Icons.access_alarms),
                  Icon(Icons.access_alarms),
                ],
              )
            ],
          ),
        );
      },
    );
    return collectionsP1;
  }
}
