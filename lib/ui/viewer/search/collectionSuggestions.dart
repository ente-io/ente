import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';

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
    collectionsP1 = generateSuggestionWidgets(p1IDs, collectionsP1);
    collectionsP2 = generateSuggestionWidgets(p2IDs, collectionsP2);
    collectionsP3 = generateSuggestionWidgets(p3IDs, collectionsP3);
    return [...collectionsP1, ...collectionsP2, ...collectionsP3];
  }

  List<Widget> generateSuggestionWidgets(
    List<int> pIDs,
    List<Widget> pCollections,
  ) {
    for (int id in pIDs) {
      Collection collection = CollectionsService.instance.getCollectionByID(id);
      pCollections.add(
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
    }
    return pCollections;
  }
}
