import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/collection.dart";
import "package:photos/models/collection_items.dart";
import "package:photos/models/file.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class AlbumsItemWidget extends StatelessWidget {
  final File file;
  final int currentUserID;
  const AlbumsItemWidget(
    this.file,
    this.currentUserID, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fileIsBackedup = file.uploadedFileID == null ? false : true;
    late Future<Set<int>> allCollectionIDsOfFile;
    //Typing this as Future<Set<T>> as it would be easier to implement showing multiple device folders for a file in the future
    final Future<Set<String>> allDeviceFoldersOfFile =
        Future.sync(() => {file.deviceFolder ?? ''});
    if (fileIsBackedup) {
      allCollectionIDsOfFile = FilesDB.instance.getAllCollectionIDsOfFile(
        file.uploadedFileID!,
      );
    }
    return InfoItemWidget(
      key: const ValueKey("Albums"),
      leadingIcon: Icons.folder_outlined,
      title: "Albums",
      subtitleSection: fileIsBackedup
          ? _collectionsListOfFile(
              context,
              allCollectionIDsOfFile,
              currentUserID,
            )
          : _deviceFoldersListOfFile(allDeviceFoldersOfFile),
      hasChipButtons: true,
    );
  }

  Future<List<ChipButtonWidget>> _deviceFoldersListOfFile(
    Future<Set<String>> allDeviceFoldersOfFile,
  ) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      final List<String> deviceFolders =
          (await allDeviceFoldersOfFile).toList();
      for (var deviceFolder in deviceFolders) {
        chipButtons.add(
          ChipButtonWidget(
            deviceFolder,
          ),
        );
      }
      return chipButtons;
    } catch (e, s) {
      Logger("AlbumsItemWidget").info(e, s);
      return [];
    }
  }

  Future<List<ChipButtonWidget>> _collectionsListOfFile(
    BuildContext context,
    Future<Set<int>> allCollectionIDsOfFile,
    int currentUserID,
  ) async {
    try {
      final chipButtons = <ChipButtonWidget>[];
      final Set<int> collectionIDs = await allCollectionIDsOfFile;
      final collections = <Collection>[];
      for (var collectionID in collectionIDs) {
        final c = CollectionsService.instance.getCollectionByID(collectionID);
        collections.add(c!);
        chipButtons.add(
          ChipButtonWidget(
            c.isHidden() ? "Hidden" : c.name,
            onTap: () {
              if (c.isHidden()) {
                return;
              }
              routeToPage(
                context,
                CollectionPage(
                  CollectionWithThumbnail(c, null),
                  appBarType: c.isOwner(currentUserID)
                      ? GalleryType.ownedCollection
                      : GalleryType.sharedCollection,
                ),
              );
            },
          ),
        );
      }
      return chipButtons;
    } catch (e, s) {
      Logger("AlbumsItemWidget").info(e, s);
      return [];
    }
  }
}
