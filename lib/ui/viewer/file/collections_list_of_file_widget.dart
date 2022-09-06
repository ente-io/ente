import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionsListOfFile extends StatelessWidget {
  final Future<Set<int>> allCollectionIDsOfFile;
  const CollectionsListOfFile(this.allCollectionIDsOfFile, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: allCollectionIDsOfFile,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final Set<int> collectionIDs = snapshot.data;
          final collections = [];
          for (var collectionID in collectionIDs) {
            collections.add(
              CollectionsService.instance.getCollectionByID(collectionID),
            );
          }
          return ListView.builder(
            itemCount: collections.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  routeToPage(
                    context,
                    CollectionPage(
                      CollectionWithThumbnail(collections[index], null),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    bottom: 18,
                    right: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseBackgroundColor
                        .withOpacity(0.025),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        collections[index].name,
                        style: Theme.of(context).textTheme.subtitle2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          Logger("CollectionsListOfFile").info(snapshot.error);
          return const SizedBox.shrink();
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }
}
