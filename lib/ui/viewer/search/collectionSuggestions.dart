import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionSuggestions {
  final Map<String, Set> collectionIDs;
  final BuildContext context;
  const CollectionSuggestions(this.collectionIDs, this.context);

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
      CollectionWithThumbnail c = CollectionWithThumbnail(collection, null);
      pCollections.add(
        GestureDetector(
          child: Row(
            children: [
              Column(
                children: [
                  const Text('Album'),
                  Text(collection.name),
                  FutureBuilder<int>(
                    future: FilesDB.instance.collectionFileCount(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data > 0) {
                        int noOfMemories = snapshot.data;

                        return RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .defaultTextColor,
                            ),
                            children: [
                              TextSpan(text: noOfMemories.toString()),
                              TextSpan(
                                text:
                                    noOfMemories != 1 ? ' memories' : ' memory',
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
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
          onTap: () {
            routeToPage(context, CollectionPage(c));
          },
        ),
      );
    }
    return pCollections;
  }
}
