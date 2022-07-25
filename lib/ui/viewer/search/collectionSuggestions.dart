import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionSuggestions {
  final List<Collection> matchedCollections;
  final BuildContext context;
  const CollectionSuggestions(this.matchedCollections, this.context);

  List<Widget> getSuggestions() {
    List<Widget> collectionsP1 = [];
    collectionsP1 = generateSuggestionWidgets(collectionsP1);
    return [...collectionsP1];
  }

  List<Widget> generateSuggestionWidgets(
    List<Widget> pCollections,
  ) {
    Future<List<File>> latestCollectionFiles =
        CollectionsService.instance.getLatestCollectionFiles();
    for (Collection collection in matchedCollections) {
      CollectionWithThumbnail c;
      pCollections.add(
        GestureDetector(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Album'),
                  Text(collection.name),
                  FutureBuilder<int>(
                    future: FilesDB.instance.collectionFileCount(collection.id),
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
              FutureBuilder(
                future: latestCollectionFiles,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    for (File file in snapshot.data) {
                      if (file.collectionID == collection.id) {
                        c = CollectionWithThumbnail(collection, file);
                        break;
                      }
                    }

                    return Row(
                      children: [
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: ThumbnailWidget(c.thumbnail),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
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
