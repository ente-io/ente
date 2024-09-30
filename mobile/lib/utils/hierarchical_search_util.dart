import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";

Future<List<EnteFile>> getFilteredFiles(
  List<EnteFile> files,
  List<HierarchicalSearchFilter> filters,
) async {
  final filteredFiles = <EnteFile>[];
  for (EnteFile file in files) {
    for (HierarchicalSearchFilter filter in filters) {
      if (filter is AlbumFilter) {
        if (filter.isMatch(file) &&
            file.uploadedFileID != null &&
            file.uploadedFileID != -1) {
          filter.matchedUploadedIDs.add(file.uploadedFileID!);
        }
      } else {
        if (filter.isMatch(file)) {
          filteredFiles.add(file);
        }
      }
    }
  }

  Set<int> filteredUploadedIDs = {};
  for (int i = 0; i < filters.length; i++) {
    if (i == 0) {
      filteredUploadedIDs =
          filteredUploadedIDs.union(filters[i].getMatchedUploadedIDs());
    } else {
      filteredUploadedIDs =
          filteredUploadedIDs.intersection(filters[i].getMatchedUploadedIDs());
    }
  }

  final filteredIDtoFile =
      await FilesDB.instance.getFilesFromIDs(filteredUploadedIDs.toList());
  for (int id in filteredIDtoFile.keys) {
    filteredFiles.add(filteredIDtoFile[id]!);
  }

  return filteredFiles;
}

void curateAlbumFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) async {
  final albumFilters = <AlbumFilter>[];
  final idToOccurrence = <int, int>{};
  final uploadedIDs = <int>[];
  for (EnteFile file in files) {
    if (file.uploadedFileID != null && file.uploadedFileID != -1) {
      uploadedIDs.add(file.uploadedFileID!);
    }
  }
  final collectionIDsOfFiles =
      await FilesDB.instance.getAllCollectionIDsOfFiles(uploadedIDs);

  for (int collectionID in collectionIDsOfFiles) {
    idToOccurrence[collectionID] = (idToOccurrence[collectionID] ?? 0) + 1;
  }

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

  searchFilterDataProvider.clearAndAddRecommendations(albumFilters);
}
