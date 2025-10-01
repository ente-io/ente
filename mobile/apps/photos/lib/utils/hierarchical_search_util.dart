import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/models/search/hierarchical/contacts_filter.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/file_type_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/location_filter.dart";
import "package:photos/models/search/hierarchical/magic_filter.dart";
import "package:photos/models/search/hierarchical/only_them_filter.dart";
import "package:photos/models/search/hierarchical/top_level_generic_filter.dart";
import "package:photos/models/search/hierarchical/uploader_filter.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/magic_cache_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/utils/file_util.dart";

Future<List<EnteFile>> getFilteredFiles(
  List<HierarchicalSearchFilter> filters,
) async {
  final logger = Logger("HierarchicalSearchUtil");
  final mlDataDB = MLDataDB.instance;
  late final List<EnteFile> filteredFiles;
  final files = await SearchService.instance.getAllFilesForHierarchicalSearch();
  final resultsNeverComputedFilters = <HierarchicalSearchFilter>[];
  final ignoredCollections =
      CollectionsService.instance.getHiddenCollectionIds();

  logger.info("Getting filtered files for Filters: $filters");
  for (HierarchicalSearchFilter filter in filters) {
    if (filter is FaceFilter && filter.matchedUploadedIDs.isEmpty) {
      try {
        if (filter.personId != null) {
          final fileIDs = await mlDataDB.getFileIDsOfPersonID(
            filter.personId!,
          );
          filter.matchedUploadedIDs.addAll(fileIDs);
        } else if (filter.clusterId != null) {
          final fileIDs = await mlDataDB.getFileIDsOfClusterID(
            filter.clusterId!,
          );
          filter.matchedUploadedIDs.addAll(fileIDs);
        }
      } catch (e) {
        logger.severe("Error in filtering face filter: $e");
      }
    } else if (filter is OnlyThemFilter && filter.matchedUploadedIDs.isEmpty) {
      try {
        late Set<int> intersectionOfSelectedFaceFiltersFileIDs;
        final selectedClusterIDs = <String>[];
        final selectedPersonIDs = <String>[];
        int index = 0;

        for (final faceFilter in filter.faceFilters) {
          if (index == 0) {
            intersectionOfSelectedFaceFiltersFileIDs =
                faceFilter.matchedUploadedIDs;
          } else {
            intersectionOfSelectedFaceFiltersFileIDs =
                intersectionOfSelectedFaceFiltersFileIDs
                    .intersection(faceFilter.matchedUploadedIDs);
          }
          index++;

          if (faceFilter.clusterId != null) {
            selectedClusterIDs.add(faceFilter.clusterId!);
          } else {
            selectedPersonIDs.add(faceFilter.personId!);
          }
        }

        await mlDataDB
            .getPersonsClusterIDs(selectedPersonIDs)
            .then((clusterIDs) {
          selectedClusterIDs.addAll(clusterIDs);
        });

        final fileIDsToAvoid =
            await mlDataDB.getAllFilesAssociatedWithAllClusters(
          exceptClusters: selectedClusterIDs,
        );

        final filesOfFaceIDsNotInAnyCluster =
            await mlDataDB.getAllFileIDsOfFaceIDsNotInAnyCluster();

        fileIDsToAvoid.addAll(filesOfFaceIDsNotInAnyCluster);

        final result =
            intersectionOfSelectedFaceFiltersFileIDs.difference(fileIDsToAvoid);
        filter.matchedUploadedIDs.addAll(result);
      } catch (e) {
        logger.severe("Error in filtering only them filter: $e");
      }
    } else if (filter.matchedUploadedIDs.isEmpty) {
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
            filteredUploadedIDs.union(filters[i].matchedUploadedIDs);
      } else {
        filteredUploadedIDs =
            filteredUploadedIDs.intersection(filters[i].matchedUploadedIDs);
      }
    }

    filteredFiles = await FilesDB.instance.getFilesFromIDs(
      filteredUploadedIDs.toList(),
      dedupeByUploadId: true,
      collectionsToIgnore: ignoredCollections,
    );
  } catch (e) {
    Logger("HierarchicalSearchUtil").severe("Failed to get filtered files: $e");
  }

  return filteredFiles;
}

Future<void> curateFilters(
  SearchFilterDataProvider searchFilterDataProvider,
  List<EnteFile> files,
  BuildContext context,
) async {
  try {
    final albumFilters = await _curateAlbumFilters(files);
    final fileTypeFilters = _curateFileTypeFilters(files, context);
    final locationFilters = await _curateLocationFilters(
      files,
    );
    final contactsFilters = _curateContactsFilter(files);
    final uploaderFilters = _curateUploaderFilter(files);
    final faceFilters = await curateFaceFilters(files);
    final magicFilters = await curateMagicFilters(files, context);
    final onlyThemFilter = getOnlyThemFilter(
      searchFilterDataProvider,
      context,
    );

    searchFilterDataProvider.clearAndAddRecommendations(
      [
        ...onlyThemFilter,
        ...magicFilters,
        ...faceFilters,
        ...fileTypeFilters,
        ...contactsFilters,
        ...uploaderFilters,
        ...albumFilters,
        ...locationFilters,
      ],
    );
  } catch (e) {
    Logger("HierarchicalSearchUtil").severe("Failed to curate filters", e);
  }
}

List<OnlyThemFilter> getOnlyThemFilter(
  SearchFilterDataProvider searchFilterDataProvider,
  BuildContext context,
) {
  if (searchFilterDataProvider.initialGalleryFilter is FaceFilter &&
      searchFilterDataProvider.appliedFilters.isEmpty) {
    return [
      OnlyThemFilter(
        faceFilters: [
          searchFilterDataProvider.initialGalleryFilter as FaceFilter,
        ],
        onlyThemString: AppLocalizations.of(context).onlyThem,
        occurrence: kMostRelevantFilter,
      ),
    ];
  }

  final appliedFaceFilters =
      searchFilterDataProvider.appliedFilters.whereType<FaceFilter>().toList();
  if (appliedFaceFilters.isEmpty || appliedFaceFilters.length > 4) {
    return [];
  } else {
    final onlyThemFilter = OnlyThemFilter(
      faceFilters: appliedFaceFilters,
      onlyThemString: AppLocalizations.of(context).onlyThem,
      occurrence: kMostRelevantFilter,
    );
    return [onlyThemFilter];
  }
}

Future<List<AlbumFilter>> _curateAlbumFilters(
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
  List<EnteFile> files,
  BuildContext context,
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
        typeName: AppLocalizations.of(context).photos,
        occurrence: photosCount,
      ),
    );
  }
  if (videosCount > 0) {
    fileTypeFilters.add(
      FileTypeFilter(
        fileType: FileType.video,
        typeName: AppLocalizations.of(context).videos,
        occurrence: videosCount,
      ),
    );
  }
  if (livePhotosCount > 0) {
    fileTypeFilters.add(
      FileTypeFilter(
        fileType: FileType.livePhoto,
        typeName: AppLocalizations.of(context).livePhotos,
        occurrence: livePhotosCount,
      ),
    );
  }

  return fileTypeFilters;
}

Future<List<LocationFilter>> _curateLocationFilters(
  List<EnteFile> files,
) async {
  final locationFilters = <LocationFilter>[];
  final locationTagToOccurrence =
      await locationService.getLocationTagsToOccurance(files);

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
  List<EnteFile> files,
) {
  final contactsFilters = <ContactsFilter>[];
  final ownerIdToOccurrence = <int, int>{};

  for (EnteFile file in files) {
    if (file.ownerID == Configuration.instance.getUserID() ||
        file.uploadedFileID == null ||
        file.uploadedFileID == -1 ||
        file.ownerID == null) {
      continue;
    }
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

List<UploaderFilter> _curateUploaderFilter(
  List<EnteFile> files,
) {
  final uploaderFilter = <UploaderFilter>[];
  final ownerIdToOccurrence = <String, int>{};

  for (EnteFile file in files) {
    if (file.uploaderName == null) {
      continue;
    }
    ownerIdToOccurrence[file.uploaderName!] =
        (ownerIdToOccurrence[file.uploaderName!] ?? 0) + 1;
  }
  for (String uploader in ownerIdToOccurrence.keys) {
    uploaderFilter.add(
      UploaderFilter(
        uploaderName: uploader,
        occurrence: ownerIdToOccurrence[uploader]!,
      ),
    );
  }

  return uploaderFilter;
}

Future<List<FaceFilter>> curateFaceFilters(
  List<EnteFile> files,
) async {
  try {
    final mlDataDB = MLDataDB.instance;
    final faceFilters = <FaceFilter>[];
    final Map<int, Set<String>> fileIdToClusterID =
        await mlDataDB.getFileIdToClusterIds();
    final Map<String, PersonEntity> personIdToPerson =
        await PersonService.instance.getPersonsMap();
    final clusterIDToPersonID = await mlDataDB.getClusterIDToPersonID();

    final Map<String, List<EnteFile>> clusterIdToFiles = {};
    final Map<String, List<EnteFile>> personIdToFiles = {};
    for (final f in files) {
      if (!fileIdToClusterID.containsKey(f.uploadedFileID ?? -1)) {
        continue;
      }
      final clusterIds = fileIdToClusterID[f.uploadedFileID ?? -1]!;
      for (final clusterId in clusterIds) {
        final PersonEntity? p =
            personIdToPerson[clusterIDToPersonID[clusterId] ?? ""];
        if (p != null) {
          if (personIdToFiles.containsKey(p.remoteID)) {
            personIdToFiles[p.remoteID]!.add(f);
          } else {
            personIdToFiles[p.remoteID] = [f];
          }
        } else {
          if (clusterIdToFiles.containsKey(clusterId)) {
            clusterIdToFiles[clusterId]!.add(f);
          } else {
            clusterIdToFiles[clusterId] = [f];
          }
        }
      }
    }

    for (final personID in personIdToFiles.keys) {
      final files = personIdToFiles[personID]!;
      if (files.isEmpty) {
        continue;
      }
      final PersonEntity p = personIdToPerson[personID]!;
      if (p.data.isIgnored) continue;

      faceFilters.add(
        FaceFilter(
          personId: personID,
          clusterId: null,
          faceName: p.data.name,
          faceFile: files.first,
          occurrence: files.length,
        ),
      );
    }

    for (final clusterId in clusterIdToFiles.keys) {
      final files = clusterIdToFiles[clusterId]!;

      if (clusterIDToPersonID[clusterId] != null) {
        // This should not happen, means a faceID is assigned to multiple persons.
        Logger("hierarchical_search_util").severe(
          "`getAllFace`: Cluster $clusterId should not have person id ${clusterIDToPersonID[clusterId]}",
        );
      }
      if (files.length < kMinimumClusterSizeSearchResult) continue;

      faceFilters.add(
        FaceFilter(
          personId: null,
          clusterId: clusterId,
          faceName: null,
          faceFile: files.first,
          occurrence: files.length,
        ),
      );
    }

    return faceFilters;
  } catch (e, s) {
    Logger("hierarchical_search_util")
        .severe("Error in curating face filters", e, s);
    rethrow;
  }
}

Future<List<MagicFilter>> curateMagicFilters(
  List<EnteFile> files,
  BuildContext context,
) async {
  final magicFilters = <MagicFilter>[];

  final magicCaches = await magicCacheService.getMagicCache();
  final filesUploadedFileIDs = filesToUploadedFileIDs(files);
  for (MagicCache magicCache in magicCaches) {
    final uploadedIDs = magicCache.fileUploadedIDs.toSet();
    final intersection = uploadedIDs.intersection(filesUploadedFileIDs);
    final title = getLocalizedTitle(context, magicCache.title);

    if (intersection.length > 3) {
      magicFilters.add(
        MagicFilter(
          filterName: title,
          occurrence: intersection.length,
          matchedUploadedIDs: magicCache.fileUploadedIDs.toSet(),
        ),
      );
    }
  }

  return magicFilters;
}

Map<String, List<HierarchicalSearchFilter>> getFiltersForBottomSheet(
  SearchFilterDataProvider searchFilterDataProvider,
) {
  final onlyThemFilter = searchFilterDataProvider.appliedFilters
      .whereType<OnlyThemFilter>()
      .toList();
  onlyThemFilter.addAll(
    searchFilterDataProvider.recommendations.whereType<OnlyThemFilter>(),
  );

  final faceFilters =
      searchFilterDataProvider.appliedFilters.whereType<FaceFilter>().toList();
  faceFilters
      .addAll(searchFilterDataProvider.recommendations.whereType<FaceFilter>());

  final albumFilters =
      searchFilterDataProvider.appliedFilters.whereType<AlbumFilter>().toList();
  albumFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<AlbumFilter>(),
  );

  final fileTypeFilters = searchFilterDataProvider.appliedFilters
      .whereType<FileTypeFilter>()
      .toList();
  fileTypeFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<FileTypeFilter>(),
  );

  final locationFilters = searchFilterDataProvider.appliedFilters
      .whereType<LocationFilter>()
      .toList();
  locationFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<LocationFilter>(),
  );

  final contactsFilters = searchFilterDataProvider.appliedFilters
      .whereType<ContactsFilter>()
      .toList();
  contactsFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<ContactsFilter>(),
  );

  final uploaderFilters = searchFilterDataProvider.appliedFilters
      .whereType<UploaderFilter>()
      .toList();
  uploaderFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<UploaderFilter>(),
  );

  final magicFilters =
      searchFilterDataProvider.appliedFilters.whereType<MagicFilter>().toList();
  magicFilters.addAll(
    searchFilterDataProvider.recommendations.whereType<MagicFilter>(),
  );

  final topLevelGenericFilter = searchFilterDataProvider.appliedFilters
      .whereType<TopLevelGenericFilter>()
      .toList();

  return {
    "onlyThemFilter": onlyThemFilter,
    "faceFilters": faceFilters,
    "magicFilters": magicFilters,
    "locationFilters": locationFilters,
    "contactsFilters": contactsFilters,
    "uploaderFilters": uploaderFilters,
    "albumFilters": albumFilters,
    "fileTypeFilters": fileTypeFilters,
    "topLevelGenericFilter": topLevelGenericFilter,
  };
}

List<HierarchicalSearchFilter> getRecommendedFiltersForAppBar(
  SearchFilterDataProvider searchFilterDataProvider,
) {
  final recommendations = searchFilterDataProvider.recommendations;

  final mostRelevantFilterFromEachType = <HierarchicalSearchFilter>[];
  int index = 0;
  final totalRecommendations = recommendations.length;

  // Add the most relevant filter from each type available in the first half of
  // the recommendations list
  for (final filter in recommendations) {
    if (mostRelevantFilterFromEachType
        .every((element) => element.runtimeType != filter.runtimeType)) {
      mostRelevantFilterFromEachType.add(filter);
    }

    if (mostRelevantFilterFromEachType.length ==
            (FilterTypeNames.values.length) ||
        (index + 1) / totalRecommendations > 0.5) {
      break;
    }
    index++;
  }

  final curatedRecommendations = <HierarchicalSearchFilter>[
    ...mostRelevantFilterFromEachType,
  ];
  for (HierarchicalSearchFilter recommendation in recommendations) {
    if (curatedRecommendations.length >= kMaxAppbarFilters) {
      break;
    }
    if (mostRelevantFilterFromEachType.every(
      (element) => !element.isSameFilter(recommendation),
    )) {
      curatedRecommendations.add(recommendation);
    }
  }

  final faceReccos = <FaceFilter>[];
  final magicReccos = <MagicFilter>[];
  final locationReccos = <LocationFilter>[];
  final contactsReccos = <ContactsFilter>[];
  final uploaderReccos = <UploaderFilter>[];
  final albumReccos = <AlbumFilter>[];
  final fileTypeReccos = <FileTypeFilter>[];
  final onlyThemFilter = <OnlyThemFilter>[];

  for (var recommendation in curatedRecommendations) {
    if (recommendation is OnlyThemFilter) {
      onlyThemFilter.add(recommendation);
    } else if (recommendation is FaceFilter) {
      faceReccos.add(recommendation);
    } else if (recommendation is MagicFilter) {
      magicReccos.add(recommendation);
    } else if (recommendation is LocationFilter) {
      locationReccos.add(recommendation);
    } else if (recommendation is ContactsFilter) {
      contactsReccos.add(recommendation);
    } else if (recommendation is UploaderFilter) {
      uploaderReccos.add(recommendation);
    } else if (recommendation is AlbumFilter) {
      albumReccos.add(recommendation);
    } else if (recommendation is FileTypeFilter) {
      fileTypeReccos.add(recommendation);
    }
  }

  return [
    ...onlyThemFilter,
    ...faceReccos,
    ...magicReccos,
    ...locationReccos,
    ...contactsReccos,
    ...uploaderReccos,
    ...albumReccos,
    ...fileTypeReccos,
  ];
}
