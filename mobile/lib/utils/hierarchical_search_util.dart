import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";

void curateAlbumFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) {
  final albumFilters = <AlbumFilter>[];
  final idToOccurrence = <int, int>{};
  for (EnteFile file in files) {
    final collectionID = file.collectionID;
    if (collectionID == null) {
      continue;
    }
    idToOccurrence[collectionID] = (idToOccurrence[collectionID] ?? 0) + 1;
  }

  // final sortedIds = idToOccurrence.keys.toList()
  //   ..sort((a, b) => idToOccurrence[b]!.compareTo(idToOccurrence[a]!));

  // for (int id in sortedIds) {
  //   final collection = CollectionsService.instance.getCollectionByID(id);
  //   if (collection == null) {
  //     continue;
  //   }
  //   albumFilters
  //       .add(AlbumFilter(collectionID: id, albumName: collection.displayName));
  // }

  for (int id in idToOccurrence.keys) {
    final collection = CollectionsService.instance.getCollectionByID(id);
    if (collection == null) {
      continue;
    }
    albumFilters.add(
      AlbumFilter(
        collectionID: id,
        albumName: collection.displayName,
        occurrence: idToOccurrence[id]!,
      ),
    );
  }

  searchFilterDataProvider.addRecommendations(albumFilters);
}
