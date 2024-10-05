import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/models/search/hierarchical/contacts_filter.dart";
import "package:photos/models/search/hierarchical/file_type_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/location_filter.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";

Future<List<EnteFile>> getFilteredFiles(
  List<HierarchicalSearchFilter> filters,
) async {
  final filteredFiles = <EnteFile>[];
  final files = await SearchService.instance.getAllFiles();
  final resultsNeverComputedFilters = <HierarchicalSearchFilter>[];

  for (HierarchicalSearchFilter filter in filters) {
    if (filter.getMatchedUploadedIDs().isEmpty) {
      resultsNeverComputedFilters.add(filter);
    }
  }

  try {
    for (EnteFile file in files) {
      if (file.uploadedFileID == null || file.uploadedFileID == -1) {
        continue;
      }
      for (HierarchicalSearchFilter filter in resultsNeverComputedFilters) {
        if (filter.isMatch(file)) {
          filter.matchedUploadedIDs.add(file.uploadedFileID!);
        }
      }
    }

    Set<int> filteredUploadedIDs = {};
    for (int i = 0; i < filters.length; i++) {
      if (i == 0) {
        filteredUploadedIDs =
            filteredUploadedIDs.union(filters[i].getMatchedUploadedIDs());
      } else {
        filteredUploadedIDs = filteredUploadedIDs
            .intersection(filters[i].getMatchedUploadedIDs());
      }
    }

    final filteredIDtoFile =
        await FilesDB.instance.getFilesFromIDs(filteredUploadedIDs.toList());
    for (int id in filteredIDtoFile.keys) {
      filteredFiles.add(filteredIDtoFile[id]!);
    }
  } catch (e) {
    Logger("HierarchicalSearchUtil").severe("Failed to get filtered files: $e");
  }

  return filteredFiles;
}

void curateFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) async {
  try {
    final albumFilters =
        await _curateAlbumFilters(searchFilterDataProvider, files);
    final fileTypeFilters =
        _curateFileTypeFilters(searchFilterDataProvider, files);
    final locationFilters = await _curateLocationFilters(
      searchFilterDataProvider,
      files,
    );
    final contactsFilters =
        _curateContactsFilter(searchFilterDataProvider, files);

    searchFilterDataProvider.clearAndAddRecommendations(
      [
        ...contactsFilters,
        ...albumFilters,
        ...locationFilters,
        ...fileTypeFilters,
      ],
    );
  } catch (e) {
    Logger("HierarchicalSearchUtil").severe("Failed to curate filters", e);
  }
}

Future<List<AlbumFilter>> _curateAlbumFilters(
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

  return albumFilters;
}

List<FileTypeFilter> _curateFileTypeFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) {
  final fileTypeFilters = <FileTypeFilter>[];
  int photosCount = 0;
  int videosCount = 0;
  int livePhotosCount = 0;

  for (EnteFile file in files) {
    final id = file.uploadedFileID;
    if (id != null && id != -1) {
      if (file.fileType == FileType.image) {
        photosCount++;
      } else if (file.fileType == FileType.video) {
        videosCount++;
      } else if (file.fileType == FileType.livePhoto) {
        livePhotosCount++;
      }
    }
  }

  if (photosCount > 0) {
    fileTypeFilters.add(
      FileTypeFilter(
        fileType: FileType.image,
        occurrence: photosCount,
      ),
    );
  }
  if (videosCount > 0) {
    fileTypeFilters.add(
      FileTypeFilter(
        fileType: FileType.video,
        occurrence: videosCount,
      ),
    );
  }
  if (livePhotosCount > 0) {
    fileTypeFilters.add(
      FileTypeFilter(
        fileType: FileType.livePhoto,
        occurrence: livePhotosCount,
      ),
    );
  }

  return fileTypeFilters;
}

Future<List<LocationFilter>> _curateLocationFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) async {
  final locationFilters = <LocationFilter>[];
  final locationTagToOccurrence =
      await LocationService.instance.getLocationTagsToOccurance(files);

  for (LocationTag locationTag in locationTagToOccurrence.keys) {
    locationFilters.add(
      LocationFilter(
        locationTag: locationTag,
        occurrence: locationTagToOccurrence[locationTag]!,
      ),
    );
  }

  return locationFilters;
}

List<ContactsFilter> _curateContactsFilter(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
) {
  final contactsFilters = <ContactsFilter>[];
  final ownerIdToOccurrence = <int, int>{};

  for (EnteFile file in files) {
    if (file.ownerID == Configuration.instance.getUserID() ||
        file.uploadedFileID == null ||
        file.uploadedFileID == -1 ||
        file.ownerID == null) continue;
    ownerIdToOccurrence[file.ownerID!] =
        (ownerIdToOccurrence[file.ownerID] ?? 0) + 1;
  }

  for (int id in ownerIdToOccurrence.keys) {
    final user = CollectionsService.instance.getFileOwner(id, null);
    contactsFilters.add(
      ContactsFilter(
        user: user,
        occurrence: ownerIdToOccurrence[id]!,
      ),
    );
  }

  return contactsFilters;
}
