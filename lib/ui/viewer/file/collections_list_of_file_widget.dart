import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/file/file_info_collection_widget.dart';
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
              return FileInfoCollection(
                name: collections[index].name,
                onTap: () {
                  routeToPage(
                    context,
                    CollectionPage(
                      CollectionWithThumbnail(collections[index], null),
                    ),
                  );
                },
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
