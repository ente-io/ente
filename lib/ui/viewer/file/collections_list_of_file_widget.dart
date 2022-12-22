import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/file/file_info_collection_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class CollectionsListOfFileWidget extends StatelessWidget {
  final Future<Set<int>> allCollectionIDsOfFile;
  final int currentUserID;

  const CollectionsListOfFileWidget(
      this.allCollectionIDsOfFile, this.currentUserID,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<int>>(
      future: allCollectionIDsOfFile,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final Set<int> collectionIDs = snapshot.data!;
          final collections = <Collection>[];
          for (var collectionID in collectionIDs) {
            final c =
                CollectionsService.instance.getCollectionByID(collectionID);
            collections.add(c);
          }
          return ListView.builder(
            itemCount: collections.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final bool isHidden = collections[index].isHidden();
              return FileInfoCollectionWidget(
                name: isHidden ? 'Hidden' : collections[index].name,
                onTap: () {
                  if (isHidden) {
                    return;
                  }
                  routeToPage(
                    context,
                    CollectionPage(
                      CollectionWithThumbnail(collections[index], null),
                      appBarType: collections[index].isOwner(currentUserID)
                          ? GalleryType.ownedCollection
                          : GalleryType.sharedCollection,
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
