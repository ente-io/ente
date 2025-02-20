import "dart:math";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:logging/logging.dart';
import "package:ml_linalg/linalg.dart";
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/data/holidays.dart';
import 'package:photos/data/months.dart';
import 'package:photos/data/years.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/db/ml/db.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/base_location.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/generic_search_result.dart';
import "package:photos/models/search/hierarchical/contacts_filter.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/file_type_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/location_filter.dart";
import "package:photos/models/search/hierarchical/magic_filter.dart";
import "package:photos/models/search/hierarchical/top_level_generic_filter.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/models/trip_memory.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_computer.dart";
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/services/user_remote_flag_service.dart";
import "package:photos/services/user_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/ui/viewer/location/add_location_sheet.dart";
import "package:photos/ui/viewer/location/location_screen.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import 'package:photos/utils/date_time_util.dart';
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";
import 'package:tuple/tuple.dart';

class SearchService {
  Future<List<EnteFile>>? _cachedFilesFuture;
  Future<List<EnteFile>>? _cachedFilesForSearch;
  Future<List<EnteFile>>? _cachedFilesForHierarchicalSearch;
  Future<List<EnteFile>>? _cachedHiddenFilesFuture;
  final _logger = Logger((SearchService).toString());
  final _collectionService = CollectionsService.instance;
  static const _maximumResultsLimit = 20;
  late final mlDataDB = MLDataDB.instance;

  SearchService._privateConstructor();

  static final SearchService instance = SearchService._privateConstructor();

  void init() {
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      // only invalidate, let the load happen on demand
      _cachedFilesFuture = null;
      _cachedFilesForSearch = null;
      _cachedFilesForHierarchicalSearch = null;
      _cachedHiddenFilesFuture = null;
    });
  }

  Set<int> ignoreCollections() {
    return CollectionsService.instance.getHiddenCollectionIds();
  }

  Future<List<EnteFile>> getAllFilesForSearch() async {
    if (_cachedFilesFuture != null && _cachedFilesForSearch != null) {
      return _cachedFilesForSearch!;
    }

    if (_cachedFilesFuture == null) {
      _logger.fine("Reading all files from db");
      _cachedFilesFuture = FilesDB.instance.getAllFilesFromDB(
        ignoreCollections(),
        dedupeByUploadId: false,
      );
    }

    _cachedFilesForSearch = _cachedFilesFuture!.then((files) {
      return applyDBFilters(
        files,
        DBFilterOptions(
          dedupeUploadID: true,
        ),
      );
    });

    return _cachedFilesForSearch!;
  }

  Future<List<EnteFile>> getAllFilesForHierarchicalSearch() async {
    if (_cachedFilesFuture != null &&
        _cachedFilesForHierarchicalSearch != null) {
      return _cachedFilesForHierarchicalSearch!;
    }

    if (_cachedFilesFuture == null) {
      _logger.fine("Reading all files from db");
      _cachedFilesFuture = FilesDB.instance.getAllFilesFromDB(
        ignoreCollections(),
        dedupeByUploadId: false,
      );
    }

    _cachedFilesForHierarchicalSearch = _cachedFilesFuture!.then((files) {
      return applyDBFilters(
        files,
        DBFilterOptions(
          dedupeUploadID: false,
          onlyUploadedFiles: true,
        ),
      );
    });

    return _cachedFilesForHierarchicalSearch!;
  }

  Future<List<EnteFile>> getHiddenFiles() async {
    if (_cachedHiddenFilesFuture != null) {
      return _cachedHiddenFilesFuture!;
    }
    _logger.fine("Reading hidden files from db");
    final hiddenCollections =
        CollectionsService.instance.getHiddenCollectionIds();
    _cachedHiddenFilesFuture =
        FilesDB.instance.getAllFilesFromCollections(hiddenCollections);
    return _cachedHiddenFilesFuture!;
  }

  void clearCache() {
    _cachedFilesFuture = null;
    _cachedFilesForSearch = null;
    _cachedFilesForHierarchicalSearch = null;
    _cachedHiddenFilesFuture = null;
  }

  // getFilteredCollectionsWithThumbnail removes deleted or archived or
  // collections which don't have a file from search result
  Future<List<AlbumSearchResult>> getCollectionSearchResults(
    String query,
  ) async {
    final List<Collection> collections = _collectionService.getCollectionsForUI(
      includedShared: true,
    );

    final List<AlbumSearchResult> collectionSearchResults = [];

    for (var c in collections) {
      if (collectionSearchResults.length >= _maximumResultsLimit) {
        break;
      }

      if (!c.isHidden() &&
          c.type != CollectionType.uncategorized &&
          c.displayName.toLowerCase().contains(
                query.toLowerCase(),
              )) {
        final EnteFile? thumbnail = await _collectionService.getCover(c);
        collectionSearchResults
            .add(AlbumSearchResult(CollectionWithThumbnail(c, thumbnail)));
      }
    }

    return collectionSearchResults;
  }

  Future<List<AlbumSearchResult>> getAllCollectionSearchResults(
    int? limit,
  ) async {
    try {
      final List<Collection> collections =
          _collectionService.getCollectionsForUI(
        includedShared: true,
      );

      final List<AlbumSearchResult> collectionSearchResults = [];

      for (var c in collections) {
        if (limit != null && collectionSearchResults.length >= limit) {
          break;
        }

        if (!c.isHidden() && c.type != CollectionType.uncategorized) {
          final EnteFile? thumbnail = await _collectionService.getCover(c);
          collectionSearchResults
              .add(AlbumSearchResult(CollectionWithThumbnail(c, thumbnail)));
        }
      }

      return collectionSearchResults;
    } catch (e) {
      _logger.severe("error gettin allCollectionSearchResults", e);
      return [];
    }
  }

  Future<List<GenericSearchResult>> getYearSearchResults(
    String yearFromQuery,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    for (var yearData in YearsData.instance.yearsData) {
      if (yearData.year.startsWith(yearFromQuery)) {
        final List<EnteFile> filesInYear =
            await _getFilesInYear(yearData.duration);
        if (filesInYear.isNotEmpty) {
          searchResults.add(
            GenericSearchResult(
              ResultType.year,
              yearData.year,
              filesInYear,
              hierarchicalSearchFilter: TopLevelGenericFilter(
                filterName: yearData.year,
                occurrence: kMostRelevantFilter,
                filterResultType: ResultType.year,
                matchedUploadedIDs: filesToUploadedFileIDs(filesInYear),
                filterIcon: Icons.calendar_month_outlined,
              ),
            ),
          );
        }
      }
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getMagicSectionResults(
    BuildContext context,
  ) async {
    if (userRemoteFlagService
        .getCachedBoolValue(UserRemoteFlagService.mlEnabled)) {
      return magicCacheService.getMagicGenericSearchResult(context);
    } else {
      return <GenericSearchResult>[];
    }
  }

  Future<List<GenericSearchResult>> getRandomMomentsSearchResults(
    BuildContext context,
  ) async {
    try {
      final nonNullSearchResults = <GenericSearchResult>[];
      final randomYear = getRadomYearSearchResult();
      final randomMonth = getRandomMonthSearchResult(context);
      final randomDate = getRandomDateResults(context);
      final randomHoliday = getRandomHolidaySearchResult(context);

      final searchResults = await Future.wait(
        [randomYear, randomMonth, randomDate, randomHoliday],
      );

      for (GenericSearchResult? searchResult in searchResults) {
        if (searchResult != null) {
          nonNullSearchResults.add(searchResult);
        }
      }

      return nonNullSearchResults;
    } catch (e) {
      _logger.severe("Error getting RandomMomentsSearchResult", e);
      return [];
    }
  }

  Future<GenericSearchResult?> getRadomYearSearchResult() async {
    for (var yearData in YearsData.instance.yearsData..shuffle()) {
      final List<EnteFile> filesInYear =
          await _getFilesInYear(yearData.duration);
      if (filesInYear.isNotEmpty) {
        return GenericSearchResult(
          ResultType.year,
          yearData.year,
          filesInYear,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: yearData.year,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.year,
            matchedUploadedIDs: filesToUploadedFileIDs(filesInYear),
            filterIcon: Icons.calendar_month_outlined,
          ),
        );
      }
    }
    //todo this throws error
    return null;
  }

  Future<List<GenericSearchResult>> getMonthSearchResults(
    BuildContext context,
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    for (var month in _getMatchingMonths(context, query)) {
      final matchedFiles =
          await FilesDB.instance.getFilesCreatedWithinDurations(
        _getDurationsOfMonthInEveryYear(month.monthNumber),
        ignoreCollections(),
        order: 'DESC',
      );
      if (matchedFiles.isNotEmpty) {
        searchResults.add(
          GenericSearchResult(
            ResultType.month,
            month.name,
            matchedFiles,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: month.name,
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.month,
              matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
              filterIcon: Icons.calendar_month_outlined,
            ),
          ),
        );
      }
    }
    return searchResults;
  }

  Future<GenericSearchResult?> getRandomMonthSearchResult(
    BuildContext context,
  ) async {
    final months = getMonthData(context)..shuffle();
    for (MonthData month in months) {
      final matchedFiles =
          await FilesDB.instance.getFilesCreatedWithinDurations(
        _getDurationsOfMonthInEveryYear(month.monthNumber),
        ignoreCollections(),
        order: 'DESC',
      );
      if (matchedFiles.isNotEmpty) {
        return GenericSearchResult(
          ResultType.month,
          month.name,
          matchedFiles,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: month.name,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.month,
            matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
            filterIcon: Icons.calendar_month_outlined,
          ),
        );
      }
    }
    return null;
  }

  Future<List<GenericSearchResult>> getHolidaySearchResults(
    BuildContext context,
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    if (query.isEmpty) {
      return searchResults;
    }
    final holidays = getHolidays(context);

    for (var holiday in holidays) {
      if (holiday.name.toLowerCase().contains(query.toLowerCase())) {
        final matchedFiles =
            await FilesDB.instance.getFilesCreatedWithinDurations(
          _getDurationsForCalendarDateInEveryYear(holiday.day, holiday.month),
          ignoreCollections(),
          order: 'DESC',
        );
        if (matchedFiles.isNotEmpty) {
          searchResults.add(
            GenericSearchResult(
              ResultType.event,
              holiday.name,
              matchedFiles,
              hierarchicalSearchFilter: TopLevelGenericFilter(
                filterName: holiday.name,
                occurrence: kMostRelevantFilter,
                filterResultType: ResultType.event,
                matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
                filterIcon: Icons.event_outlined,
              ),
            ),
          );
        }
      }
    }
    return searchResults;
  }

  Future<GenericSearchResult?> getRandomHolidaySearchResult(
    BuildContext context,
  ) async {
    final holidays = getHolidays(context)..shuffle();
    for (var holiday in holidays) {
      final matchedFiles =
          await FilesDB.instance.getFilesCreatedWithinDurations(
        _getDurationsForCalendarDateInEveryYear(holiday.day, holiday.month),
        ignoreCollections(),
        order: 'DESC',
      );
      if (matchedFiles.isNotEmpty) {
        return GenericSearchResult(
          ResultType.event,
          holiday.name,
          matchedFiles,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: holiday.name,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.event,
            matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
            filterIcon: Icons.event_outlined,
          ),
        );
      }
    }
    return null;
  }

  Future<List<GenericSearchResult>> getFileTypeResults(
    BuildContext context,
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final List<EnteFile> allFiles = await getAllFilesForSearch();
    for (var fileType in FileType.values) {
      final String fileTypeString = getHumanReadableString(context, fileType);
      if (fileTypeString.toLowerCase().startsWith(query.toLowerCase())) {
        final matchedFiles =
            allFiles.where((e) => e.fileType == fileType).toList();
        if (matchedFiles.isNotEmpty) {
          searchResults.add(
            GenericSearchResult(
              ResultType.fileType,
              fileTypeString,
              matchedFiles,
              hierarchicalSearchFilter: FileTypeFilter(
                fileType: fileType,
                typeName: fileTypeString,
                occurrence: kMostRelevantFilter,
                matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
              ),
            ),
          );
        }
      }
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getAllFileTypesAndExtensionsResults(
    BuildContext context,
    int? limit,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final List<EnteFile> allFiles = await getAllFilesForSearch();
    final fileTypesAndMatchingFiles = <FileType, List<EnteFile>>{};
    final extensionsAndMatchingFiles = <String, List<EnteFile>>{};
    try {
      for (EnteFile file in allFiles) {
        if (!fileTypesAndMatchingFiles.containsKey(file.fileType)) {
          fileTypesAndMatchingFiles[file.fileType] = <EnteFile>[];
        }
        fileTypesAndMatchingFiles[file.fileType]!.add(file);

        final String fileName = file.displayName;
        late final String ext;
        //Noticed that some old edited files do not have extensions and a '.'
        ext = fileName.contains(".")
            ? fileName.split(".").last.toUpperCase()
            : "";

        if (ext != "") {
          if (!extensionsAndMatchingFiles.containsKey(ext)) {
            extensionsAndMatchingFiles[ext] = <EnteFile>[];
          }
          extensionsAndMatchingFiles[ext]!.add(file);
        }
      }

      fileTypesAndMatchingFiles.forEach((key, value) {
        final name = getHumanReadableString(context, key);
        searchResults.add(
          GenericSearchResult(
            ResultType.fileType,
            name,
            value,
            hierarchicalSearchFilter: FileTypeFilter(
              fileType: key,
              typeName: name,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(value),
            ),
          ),
        );
      });

      extensionsAndMatchingFiles.forEach((key, value) {
        searchResults.add(
          GenericSearchResult(
            ResultType.fileExtension,
            key + "s",
            value,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: key + "s",
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.fileExtension,
              matchedUploadedIDs: filesToUploadedFileIDs(value),
              filterIcon: CupertinoIcons.doc_text,
            ),
          ),
        );
      });

      if (limit != null) {
        return searchResults.sublist(0, min(limit, searchResults.length));
      } else {
        return searchResults;
      }
    } catch (e) {
      _logger.severe("Error getting allFileTypesAndExtensionsResults", e);
      return [];
    }
  }

  Future<List<GenericSearchResult>> getCaptionAndNameResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    if (query.isEmpty) {
      return searchResults;
    }
    final RegExp pattern = RegExp(query, caseSensitive: false);
    final List<EnteFile> allFiles = await getAllFilesForSearch();
    final List<EnteFile> captionMatch = <EnteFile>[];
    final List<EnteFile> displayNameMatch = <EnteFile>[];
    for (EnteFile eachFile in allFiles) {
      if (eachFile.caption != null && pattern.hasMatch(eachFile.caption!)) {
        captionMatch.add(eachFile);
      }
      if (pattern.hasMatch(eachFile.displayName)) {
        displayNameMatch.add(eachFile);
      }
    }
    if (captionMatch.isNotEmpty) {
      searchResults.add(
        GenericSearchResult(
          ResultType.fileCaption,
          query,
          captionMatch,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: query,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.fileCaption,
            matchedUploadedIDs: filesToUploadedFileIDs(captionMatch),
            filterIcon: Icons.description_outlined,
          ),
        ),
      );
    }
    if (displayNameMatch.isNotEmpty) {
      searchResults.add(
        GenericSearchResult(
          ResultType.file,
          query,
          displayNameMatch,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: query,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.file,
            matchedUploadedIDs: filesToUploadedFileIDs(displayNameMatch),
          ),
        ),
      );
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getFileExtensionResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    if (!query.startsWith(".")) {
      return searchResults;
    }

    final List<EnteFile> allFiles = await getAllFilesForSearch();
    final Map<String, List<EnteFile>> resultMap = <String, List<EnteFile>>{};

    for (EnteFile eachFile in allFiles) {
      final String fileName = eachFile.displayName;
      if (fileName.contains(query)) {
        final String exnType = fileName.split(".").last.toUpperCase();
        if (!resultMap.containsKey(exnType)) {
          resultMap[exnType] = <EnteFile>[];
        }
        resultMap[exnType]!.add(eachFile);
      }
    }
    for (MapEntry<String, List<EnteFile>> entry in resultMap.entries) {
      searchResults.add(
        GenericSearchResult(
          ResultType.fileExtension,
          entry.key.toUpperCase(),
          entry.value,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: entry.key.toUpperCase(),
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.fileExtension,
            matchedUploadedIDs: filesToUploadedFileIDs(entry.value),
            filterIcon: CupertinoIcons.doc_text,
          ),
        ),
      );
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getLocationResults(String query) async {
    final locationTagEntities = (await locationService.getLocationTags());
    final Map<LocalEntity<LocationTag>, List<EnteFile>> result = {};
    final bool showNoLocationTag = query.length > 2 &&
        "No Location Tag".toLowerCase().startsWith(query.toLowerCase());

    final List<GenericSearchResult> searchResults = [];

    for (LocalEntity<LocationTag> tag in locationTagEntities) {
      if (tag.item.name.toLowerCase().contains(query.toLowerCase())) {
        result[tag] = [];
      }
    }
    final allFiles = await getAllFilesForSearch();
    for (EnteFile file in allFiles) {
      if (file.hasLocation) {
        for (LocalEntity<LocationTag> tag in result.keys) {
          if (isFileInsideLocationTag(
            tag.item.centerPoint,
            file.location!,
            tag.item.radius,
          )) {
            result[tag]!.add(file);
          }
        }
      }
    }
    if (showNoLocationTag) {
      _logger.fine("finding photos with no location");
      // find files that have location but the file's location is not inside
      // any location tag
      final noLocationTagFiles = allFiles.where((file) {
        if (!file.hasLocation) {
          return false;
        }
        for (LocalEntity<LocationTag> tag in locationTagEntities) {
          if (isFileInsideLocationTag(
            tag.item.centerPoint,
            file.location!,
            tag.item.radius,
          )) {
            return false;
          }
        }
        return true;
      }).toList();
      if (noLocationTagFiles.isNotEmpty) {
        searchResults.add(
          GenericSearchResult(
            ResultType.fileType,
            "No Location Tag",
            noLocationTagFiles,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: "No Location Tag",
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.fileType,
              matchedUploadedIDs: filesToUploadedFileIDs(noLocationTagFiles),
              filterIcon: Icons.not_listed_location_outlined,
            ),
          ),
        );
      }
    }
    final locationTagNames = <String>{};
    for (MapEntry<LocalEntity<LocationTag>, List<EnteFile>> entry
        in result.entries) {
      if (entry.value.isNotEmpty) {
        final name = entry.key.item.name;
        locationTagNames.add(name);
        searchResults.add(
          GenericSearchResult(
            ResultType.location,
            name,
            entry.value,
            onResultTap: (ctx) {
              routeToPage(
                ctx,
                LocationScreenStateProvider(
                  entry.key,
                  const LocationScreen(),
                ),
              );
            },
            hierarchicalSearchFilter: LocationFilter(
              locationTag: entry.key.item,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(entry.value),
            ),
          ),
        );
      }
    }
    //todo: remove this later, this hack is for interval+external evaluation
    // for suggestions
    final allCitiesSearch = query == '__city';
    if (allCitiesSearch) {
      query = '';
    }
    final results = await locationService.getFilesInCity(allFiles, query);
    final List<City> sortedByResultCount = results.keys.toList()
      ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
    for (final city in sortedByResultCount) {
      // If the location tag already exists for a city, don't add it again
      if (!locationTagNames.contains(city.city)) {
        final a =
            (defaultCityRadius * scaleFactor(city.lat)) / kilometersPerDegree;
        const b = defaultCityRadius / kilometersPerDegree;
        searchResults.add(
          GenericSearchResult(
            ResultType.location,
            city.city,
            results[city]!,
            hierarchicalSearchFilter: LocationFilter(
              locationTag: LocationTag(
                name: city.city,
                radius: defaultCityRadius,
                centerPoint: Location(latitude: city.lat, longitude: city.lng),
                aSquare: a * a,
                bSquare: b * b,
              ),
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(results[city]!),
            ),
          ),
        );
      }
    }
    return searchResults;
  }

  Future<Map<String, List<EnteFile>>> getClusterFilesForPersonID(
    String personID,
  ) async {
    _logger.info('getClusterFilesForPersonID $personID');
    final Map<int, Set<String>> fileIdToClusterID =
        await mlDataDB.getFileIdToClusterIDSet(personID);
    _logger.info('faceDbDone getClusterFilesForPersonID $personID');
    final Map<String, List<EnteFile>> clusterIDToFiles = {};
    final allFiles = await getAllFilesForSearch();
    for (final f in allFiles) {
      if (!fileIdToClusterID.containsKey(f.uploadedFileID ?? -1)) {
        continue;
      }
      final cluserIds = fileIdToClusterID[f.uploadedFileID ?? -1]!;
      for (final cluster in cluserIds) {
        if (clusterIDToFiles.containsKey(cluster)) {
          clusterIDToFiles[cluster]!.add(f);
        } else {
          clusterIDToFiles[cluster] = [f];
        }
      }
    }
    _logger.info('done getClusterFilesForPersonID $personID');
    return clusterIDToFiles;
  }

  Future<List<GenericSearchResult>> getAllFace(
    int? limit, {
    int minClusterSize = kMinimumClusterSizeSearchResult,
  }) async {
    try {
      debugPrint("getting faces");
      final Map<int, Set<String>> fileIdToClusterID =
          await mlDataDB.getFileIdToClusterIds();
      final Map<String, PersonEntity> personIdToPerson =
          await PersonService.instance.getPersonsMap();
      final clusterIDToPersonID = await mlDataDB.getClusterIDToPersonID();

      final List<GenericSearchResult> facesResult = [];
      final Map<String, List<EnteFile>> clusterIdToFiles = {};
      final Map<String, List<EnteFile>> personIdToFiles = {};
      final allFiles = await getAllFilesForSearch();
      for (final f in allFiles) {
        if (!fileIdToClusterID.containsKey(f.uploadedFileID ?? -1)) {
          continue;
        }
        final clusterIds = fileIdToClusterID[f.uploadedFileID ?? -1]!;
        for (final cluster in clusterIds) {
          final PersonEntity? p =
              personIdToPerson[clusterIDToPersonID[cluster] ?? ""];
          if (p != null) {
            if (personIdToFiles.containsKey(p.remoteID)) {
              personIdToFiles[p.remoteID]!.add(f);
            } else {
              personIdToFiles[p.remoteID] = [f];
            }
          } else {
            if (clusterIdToFiles.containsKey(cluster)) {
              clusterIdToFiles[cluster]!.add(f);
            } else {
              clusterIdToFiles[cluster] = [f];
            }
          }
        }
      }
      // get sorted personId by files count
      final sortedPersonIds = personIdToFiles.keys.toList()
        ..sort(
          (a, b) => personIdToFiles[b]!.length.compareTo(
                personIdToFiles[a]!.length,
              ),
        );
      for (final personID in sortedPersonIds) {
        final files = personIdToFiles[personID]!;
        if (files.isEmpty) {
          continue;
        }
        final PersonEntity p = personIdToPerson[personID]!;
        if (p.data.isIgnored) continue;
        facesResult.add(
          GenericSearchResult(
            ResultType.faces,
            p.data.name,
            files,
            params: {
              kPersonWidgetKey: p.data.avatarFaceID ?? p.hashCode.toString(),
              kPersonParamID: personID,
              kFileID: files.first.uploadedFileID,
            },
            onResultTap: (ctx) {
              routeToPage(
                ctx,
                PeoplePage(
                  tagPrefix: "${ResultType.faces.toString()}_${p.data.name}",
                  person: p,
                  searchResult: GenericSearchResult(
                    ResultType.faces,
                    p.data.name,
                    files,
                    params: {
                      kPersonWidgetKey:
                          p.data.avatarFaceID ?? p.hashCode.toString(),
                      kPersonParamID: personID,
                      kFileID: files.first.uploadedFileID,
                    },
                    hierarchicalSearchFilter: FaceFilter(
                      personId: p.remoteID,
                      clusterId: null,
                      faceName: p.data.name,
                      faceFile: files.first,
                      occurrence: kMostRelevantFilter,
                      matchedUploadedIDs: filesToUploadedFileIDs(files),
                    ),
                  ),
                ),
              );
            },
            hierarchicalSearchFilter: FaceFilter(
              personId: p.remoteID,
              clusterId: null,
              faceName: p.data.name,
              faceFile: files.first,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(files),
            ),
          ),
        );
      }
      final sortedClusterIds = clusterIdToFiles.keys.toList()
        ..sort(
          (a, b) => clusterIdToFiles[b]!
              .length
              .compareTo(clusterIdToFiles[a]!.length),
        );

      for (final clusterId in sortedClusterIds) {
        final files = clusterIdToFiles[clusterId]!;
        // final String clusterName = "ID:$clusterId,  ${files.length}";
        // final String clusterName = "${files.length}";
        // const String clusterName = "";
        final String clusterName = clusterId;

        if (clusterIDToPersonID[clusterId] != null) {
          final String personID = clusterIDToPersonID[clusterId]!;
          final PersonEntity? p = personIdToPerson[personID];
          if (p != null) {
            // This should not be possible since it should be handled in the above loop, logging just in case
            _logger.severe(
              "`getAllFace`: Something unexpected happened, Cluster $clusterId should not have person id $personID",
              Exception(
                'Some unexpected error occurred in getAllFace wrt cluster to person mapping',
              ),
            );
          } else {
            // This should not happen, means a clusterID is still assigned to a personID of a person that no longer exists
            // Logging the error and deleting the clusterID to personID mapping
            _logger.severe(
              "`getAllFace`: Cluster $clusterId should not have person id ${clusterIDToPersonID[clusterId]}, deleting the mapping",
              Exception('ClusterID assigned to a person that no longer exists'),
            );
            await mlDataDB.removeClusterToPerson(
              personID: personID,
              clusterID: clusterId,
            );
          }
        }
        if (files.length < minClusterSize) continue;
        facesResult.add(
          GenericSearchResult(
            ResultType.faces,
            "",
            files,
            params: {
              kClusterParamId: clusterId,
              kFileID: files.first.uploadedFileID,
            },
            onResultTap: (ctx) {
              routeToPage(
                ctx,
                ClusterPage(
                  files,
                  tagPrefix: "${ResultType.faces.toString()}_$clusterName",
                  clusterID: clusterId,
                ),
              );
            },
            hierarchicalSearchFilter: FaceFilter(
              personId: null,
              clusterId: clusterId,
              faceName: null,
              faceFile: files.first,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(files),
            ),
          ),
        );
      }
      if (facesResult.isEmpty) {
        int newMinimum = minClusterSize;
        for (final int minimum in kLowerMinimumClusterSizes) {
          if (minimum < minClusterSize) {
            newMinimum = minimum;
            break;
          }
        }
        if (newMinimum < minClusterSize) {
          return getAllFace(limit, minClusterSize: newMinimum);
        } else {
          return [];
        }
      }
      if (limit != null) {
        return facesResult.sublist(0, min(limit, facesResult.length));
      } else {
        return facesResult;
      }
    } catch (e, s) {
      _logger.severe("Error in getAllFace", e, s);
      rethrow;
    }
  }

  Future<List<GenericSearchResult>> getAllLocationTags(int? limit) async {
    try {
      final Map<LocalEntity<LocationTag>, List<EnteFile>> tagToItemsMap = {};
      final List<GenericSearchResult> tagSearchResults = [];
      final locationTagEntities = (await locationService.getLocationTags());
      final allFiles = await getAllFilesForSearch();
      final List<EnteFile> filesWithNoLocTag = [];

      for (int i = 0; i < locationTagEntities.length; i++) {
        if (limit != null && i >= limit) break;
        tagToItemsMap[locationTagEntities.elementAt(i)] = [];
      }

      for (EnteFile file in allFiles) {
        if (file.hasLocation) {
          bool hasLocationTag = false;
          for (LocalEntity<LocationTag> tag in tagToItemsMap.keys) {
            if (isFileInsideLocationTag(
              tag.item.centerPoint,
              file.location!,
              tag.item.radius,
            )) {
              hasLocationTag = true;
              tagToItemsMap[tag]!.add(file);
            }
          }
          // If the location tag already exists for a city, do not consider
          // it for the city suggestions
          if (!hasLocationTag) {
            filesWithNoLocTag.add(file);
          }
        }
      }

      for (MapEntry<LocalEntity<LocationTag>, List<EnteFile>> entry
          in tagToItemsMap.entries) {
        if (entry.value.isNotEmpty) {
          tagSearchResults.add(
            GenericSearchResult(
              ResultType.location,
              entry.key.item.name,
              entry.value,
              onResultTap: (ctx) {
                routeToPage(
                  ctx,
                  LocationScreenStateProvider(
                    entry.key,
                    LocationScreen(
                      //this is SearchResult.heroTag()
                      tagPrefix:
                          "${ResultType.location.toString()}_${entry.key.item.name}",
                    ),
                  ),
                );
              },
              hierarchicalSearchFilter: LocationFilter(
                locationTag: entry.key.item,
                occurrence: kMostRelevantFilter,
                matchedUploadedIDs: filesToUploadedFileIDs(entry.value),
              ),
            ),
          );
        }
      }
      if (limit == null || tagSearchResults.length < limit) {
        final results =
            await locationService.getFilesInCity(filesWithNoLocTag, '');
        final List<City> sortedByResultCount = results.keys.toList()
          ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
        for (final city in sortedByResultCount) {
          if (results[city]!.length <= 1) continue;
          final a =
              (defaultCityRadius * scaleFactor(city.lat)) / kilometersPerDegree;
          const b = defaultCityRadius / kilometersPerDegree;
          tagSearchResults.add(
            GenericSearchResult(
              ResultType.locationSuggestion,
              city.city,
              results[city]!,
              onResultTap: (ctx) {
                showAddLocationSheet(
                  ctx,
                  Location(latitude: city.lat, longitude: city.lng),
                  name: city.city,
                  radius: defaultCityRadius,
                );
              },
              hierarchicalSearchFilter: LocationFilter(
                locationTag: LocationTag(
                  name: city.city,
                  radius: defaultCityRadius,
                  centerPoint:
                      Location(latitude: city.lat, longitude: city.lng),
                  aSquare: a * a,
                  bSquare: b * b,
                ),
                occurrence: kMostRelevantFilter,
                matchedUploadedIDs: filesToUploadedFileIDs(results[city]!),
              ),
            ),
          );
        }
      }
      return tagSearchResults;
    } catch (e) {
      _logger.severe("Error in getAllLocationTags", e);
      return [];
    }
  }

  Future<List<GenericSearchResult>> getDateResults(
    BuildContext context,
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final potentialDates = _getPossibleEventDate(context, query);

    for (var potentialDate in potentialDates) {
      final int day = potentialDate.item1;
      final int month = potentialDate.item2.monthNumber;
      final int? year = potentialDate.item3; // nullable
      final matchedFiles =
          await FilesDB.instance.getFilesCreatedWithinDurations(
        _getDurationsForCalendarDateInEveryYear(day, month, year: year),
        ignoreCollections(),
        order: 'DESC',
      );
      if (matchedFiles.isNotEmpty) {
        final name = '$day ${potentialDate.item2.name} ${year ?? ''}';
        searchResults.add(
          GenericSearchResult(
            ResultType.event,
            name,
            matchedFiles,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: name,
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.event,
              matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
              filterIcon: Icons.event_outlined,
            ),
          ),
        );
      }
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getMagicSearchResults(
    BuildContext context,
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    late List<EnteFile> files;
    late String resultForQuery;
    try {
      (resultForQuery, files) =
          await SemanticSearchService.instance.searchScreenQuery(query);
    } catch (e, s) {
      _logger.severe("Error occurred during magic search", e, s);
      return searchResults;
    }
    if (files.isNotEmpty && resultForQuery == query) {
      searchResults.add(
        GenericSearchResult(
          ResultType.magic,
          query,
          files,
          onResultTap: (context) {
            routeToPage(
              context,
              MagicResultScreen(
                files,
                name: query,
                enableGrouping: false,
                heroTag: GenericSearchResult(
                  ResultType.magic,
                  query,
                  files,
                  hierarchicalSearchFilter: MagicFilter(
                    filterName: query,
                    occurrence: kMostRelevantFilter,
                    matchedUploadedIDs: filesToUploadedFileIDs(files),
                  ),
                ).heroTag(),
                magicFilter: MagicFilter(
                  filterName: query,
                  occurrence: kMostRelevantFilter,
                  matchedUploadedIDs: filesToUploadedFileIDs(files),
                ),
              ),
            );
          },
          hierarchicalSearchFilter: MagicFilter(
            filterName: query,
            occurrence: kMostRelevantFilter,
            matchedUploadedIDs: filesToUploadedFileIDs(files),
          ),
        ),
      );
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getTripsResults(
    BuildContext context,
    int? limit,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final allFiles = await getAllFilesForSearch();
    final Iterable<LocalEntity<LocationTag>> locationTagEntities =
        (await locationService.getLocationTags());
    if (allFiles.isEmpty) return [];
    final currentTime = DateTime.now().toLocal();
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));

    final Map<LocalEntity<LocationTag>, List<EnteFile>> tagToItemsMap = {};
    for (int i = 0; i < locationTagEntities.length; i++) {
      tagToItemsMap[locationTagEntities.elementAt(i)] = [];
    }
    final List<(List<EnteFile>, Location)> smallRadiusClusters = [];
    final List<(List<EnteFile>, Location)> wideRadiusClusters = [];
    // Go through all files and cluster the ones not inside any location tag
    for (EnteFile file in allFiles) {
      if (!file.hasLocation ||
          file.uploadedFileID == null ||
          !file.isOwner ||
          file.creationTime == null) {
        continue;
      }
      // Check if the file is inside any location tag
      bool hasLocationTag = false;
      for (LocalEntity<LocationTag> tag in tagToItemsMap.keys) {
        if (isFileInsideLocationTag(
          tag.item.centerPoint,
          file.location!,
          tag.item.radius,
        )) {
          hasLocationTag = true;
          tagToItemsMap[tag]!.add(file);
        }
      }
      // Cluster the files not inside any location tag (incremental clustering)
      if (!hasLocationTag) {
        // Small radius clustering for base locations
        bool foundSmallCluster = false;
        for (final cluster in smallRadiusClusters) {
          final clusterLocation = cluster.$2;
          if (isFileInsideLocationTag(
            clusterLocation,
            file.location!,
            0.6,
          )) {
            cluster.$1.add(file);
            foundSmallCluster = true;
            break;
          }
        }
        if (!foundSmallCluster) {
          smallRadiusClusters.add(([file], file.location!));
        }
        // Wide radius clustering for trip locations
        bool foundWideCluster = false;
        for (final cluster in wideRadiusClusters) {
          final clusterLocation = cluster.$2;
          if (isFileInsideLocationTag(
            clusterLocation,
            file.location!,
            100.0,
          )) {
            cluster.$1.add(file);
            foundWideCluster = true;
            break;
          }
        }
        if (!foundWideCluster) {
          wideRadiusClusters.add(([file], file.location!));
        }
      }
    }

    // Identify base locations
    final List<BaseLocation> baseLocations = [];
    for (final cluster in smallRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      // Check that the photos are distributed over a longer time range (3+ months)
      final creationTimes = <int>[];
      final Set<int> uniqueDays = {};
      for (final file in files) {
        creationTimes.add(file.creationTime!);
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final dayStamp =
            DateTime(date.year, date.month, date.day).microsecondsSinceEpoch;
        uniqueDays.add(dayStamp);
      }
      creationTimes.sort();
      if (creationTimes.length < 10) continue;
      final firstCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.first,
      );
      final lastCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.last,
      );
      if (lastCreationTime.difference(firstCreationTime).inDays < 90) {
        continue;
      }
      // Check for a minimum average number of days photos are clicked in range
      final daysRange = lastCreationTime.difference(firstCreationTime).inDays;
      if (uniqueDays.length < daysRange * 0.1) continue;
      // Check if it's a current or old base location
      final bool isCurrent = lastCreationTime.isAfter(
        DateTime.now().subtract(
          const Duration(days: 90),
        ),
      );
      baseLocations.add(BaseLocation(files, location, isCurrent));
    }

    // Identify trip locations
    final List<TripMemory> tripLocations = [];
    clusteredLocations:
    for (final cluster in wideRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      // Check that it's at least 10km away from any base or tag location
      bool tooClose = false;
      for (final baseLocation in baseLocations) {
        if (isFileInsideLocationTag(
          baseLocation.location,
          location,
          10.0,
        )) {
          tooClose = true;
          break;
        }
      }
      for (final tag in tagToItemsMap.keys) {
        if (isFileInsideLocationTag(
          tag.item.centerPoint,
          location,
          10.0,
        )) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue clusteredLocations;

      // Check that the photos are distributed over a short time range (2-30 days) or multiple short time ranges only
      files.sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
      // Find distinct time blocks (potential trips)
      List<EnteFile> currentBlockFiles = [files.first];
      int blockStart = files.first.creationTime!;
      int lastTime = files.first.creationTime!;
      DateTime lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);

      for (int i = 1; i < files.length; i++) {
        final currentFile = files[i];
        final currentTime = currentFile.creationTime!;
        final gap = DateTime.fromMicrosecondsSinceEpoch(currentTime)
            .difference(lastDateTime)
            .inDays;

        // If gap is too large, end current block and check if it's a valid trip
        if (gap > 15) {
          // 10 days gap to separate trips. If gap is small, it's likely not a trip
          if (gap < 90) continue clusteredLocations;

          final blockDuration = lastDateTime
              .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
              .inDays;

          // Check if current block is a valid trip (2-30 days)
          if (blockDuration >= 2 && blockDuration <= 30) {
            tripLocations.add(
              TripMemory(
                List.from(currentBlockFiles),
                location,
                blockStart,
                lastTime,
              ),
            );
          }

          // Start new block
          currentBlockFiles = [];
          blockStart = currentTime;
        }

        currentBlockFiles.add(currentFile);
        lastTime = currentTime;
        lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);
      }
      // Check final block
      final lastBlockDuration = lastDateTime
          .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
          .inDays;
      if (lastBlockDuration >= 2 && lastBlockDuration <= 30) {
        tripLocations.add(
          TripMemory(
            List.from(currentBlockFiles),
            location,
            blockStart,
            lastTime,
          ),
        );
      }
    }

    // Check if any trip locations should be merged
    final List<TripMemory> mergedTrips = [];
    for (final trip in tripLocations) {
      final tripFirstTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.firstCreationTime,
      );
      final tripLastTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.lastCreationTime,
      );
      bool merged = false;
      for (int idx = 0; idx < mergedTrips.length; idx++) {
        final otherTrip = mergedTrips[idx];
        final otherTripFirstTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.firstCreationTime);
        final otherTripLastTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.lastCreationTime);
        if (tripFirstTime
                .isBefore(otherTripLastTime.add(const Duration(days: 3))) &&
            tripLastTime.isAfter(
              otherTripFirstTime.subtract(const Duration(days: 3)),
            )) {
          mergedTrips[idx] = TripMemory(
            otherTrip.files + trip.files,
            otherTrip.location,
            min(otherTrip.firstCreationTime, trip.firstCreationTime),
            max(otherTrip.lastCreationTime, trip.lastCreationTime),
          );
          _logger.finest('Merged two trip locations');
          merged = true;
          break;
        }
      }
      if (merged) continue;
      mergedTrips.add(
        TripMemory(
          trip.files,
          trip.location,
          trip.firstCreationTime,
          trip.lastCreationTime,
        ),
      );
    }

    // Remove too small and too recent trips
    final List<TripMemory> validTrips = [];
    for (final trip in mergedTrips) {
      if (trip.files.length >= 20 &&
          trip.averageCreationTime < cutOffTime.microsecondsSinceEpoch) {
        validTrips.add(trip);
      }
    }

    // For now for testing let's just surface all base locations
    for (final baseLocation in baseLocations) {
      String name = "Base (${baseLocation.isCurrentBase ? 'current' : 'old'})";
      final String? locationName = await _tryFindLocationName(
        baseLocation.files,
        base: true,
      );
      if (locationName != null) {
        name =
            "$locationName (Base, ${baseLocation.isCurrentBase ? 'current' : 'old'})";
      }
      searchResults.add(
        GenericSearchResult(
          ResultType.event,
          name,
          baseLocation.files,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: name,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.event,
            matchedUploadedIDs: filesToUploadedFileIDs(baseLocation.files),
            filterIcon: Icons.event_outlined,
          ),
        ),
      );
    }

    // For now we surface the two most recent trips of current month, and if none, the earliest upcoming redundant trip
    // Group the trips per month and then year
    final Map<int, Map<int, List<TripMemory>>> tripsByMonthYear = {};
    for (final trip in validTrips) {
      final tripDate =
          DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime);
      tripsByMonthYear
          .putIfAbsent(tripDate.month, () => {})
          .putIfAbsent(tripDate.year, () => [])
          .add(trip);
    }

    // Flatten trips for the current month and annotate with their average date.
    final List<TripMemory> currentMonthTrips = [];
    if (tripsByMonthYear.containsKey(currentMonth)) {
      for (final trips in tripsByMonthYear[currentMonth]!.values) {
        for (final trip in trips) {
          currentMonthTrips.add(trip);
        }
      }
    }

    // If there are past trips this month, show the one or two most recent ones.
    if (currentMonthTrips.isNotEmpty) {
      currentMonthTrips.sort(
        (a, b) => b.averageCreationTime.compareTo(a.averageCreationTime),
      );
      final tripsToShow = currentMonthTrips.take(2);
      for (final trip in tripsToShow) {
        final year =
            DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime).year;
        final String? locationName = await _tryFindLocationName(trip.files);
        String name = "Trip in $year";
        if (locationName != null) {
          name = "Trip to $locationName";
        } else if (year == currentTime.year - 1) {
          name = "Last year's trip";
        }
        final photoSelection = await _bestSelection(trip.files);
        searchResults.add(
          GenericSearchResult(
            ResultType.event,
            name,
            photoSelection,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: name,
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.event,
              matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
              filterIcon: Icons.event_outlined,
            ),
          ),
        );
        if (limit != null && searchResults.length >= limit) {
          return searchResults;
        }
      }
    }
    // Otherwise, if no trips happened in the current month,
    // look for the earliest upcoming trip in another month that has 3+ trips.
    else {
      // TODO lau: make sure the same upcoming trip isn't shown multiple times over multiple months
      final sortedUpcomingMonths =
          List<int>.generate(12, (i) => ((currentMonth + i) % 12) + 1);
      checkUpcomingMonths:
      for (final month in sortedUpcomingMonths) {
        if (tripsByMonthYear.containsKey(month)) {
          final List<TripMemory> thatMonthTrips = [];
          for (final trips in tripsByMonthYear[month]!.values) {
            for (final trip in trips) {
              thatMonthTrips.add(trip);
            }
          }
          if (thatMonthTrips.length >= 3) {
            // take and use the third earliest trip
            thatMonthTrips.sort(
              (a, b) => a.averageCreationTime.compareTo(b.averageCreationTime),
            );
            final trip = thatMonthTrips[2];
            final year =
                DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime)
                    .year;
            final String? locationName = await _tryFindLocationName(trip.files);
            String name = "Trip in $year";
            if (locationName != null) {
              name = "Trip to $locationName";
            } else if (year == currentTime.year - 1) {
              name = "Last year's trip";
            }
            final photoSelection = await _bestSelection(trip.files);
            searchResults.add(
              GenericSearchResult(
                ResultType.event,
                name,
                photoSelection,
                hierarchicalSearchFilter: TopLevelGenericFilter(
                  filterName: name,
                  occurrence: kMostRelevantFilter,
                  filterResultType: ResultType.event,
                  matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
                  filterIcon: Icons.event_outlined,
                ),
              ),
            );
            break checkUpcomingMonths;
          }
        }
      }
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> onThisDayOrWeekResults(
    BuildContext context,
    int? limit,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final trips = await getTripsResults(context, limit);
    if (trips.isNotEmpty) {
      searchResults.addAll(trips);
    }
    final allFiles = await getAllFilesForSearch();
    if (allFiles.isEmpty) return [];

    final currentTime = DateTime.now().toLocal();
    final currentDayMonth = currentTime.month * 100 + currentTime.day;
    final currentWeek = _getWeekNumber(currentTime);
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));
    final averageDailyPhotos = allFiles.length / 365;
    final significantDayThreshold = averageDailyPhotos * 0.25;
    final significantWeekThreshold = averageDailyPhotos * 0.40;

    // Group files by day-month and year
    final dayMonthYearGroups = <int, Map<int, List<EnteFile>>>{};

    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final dayMonth = creationTime.month * 100 + creationTime.day;
      final year = creationTime.year;

      dayMonthYearGroups
          .putIfAbsent(dayMonth, () => {})
          .putIfAbsent(year, () => [])
          .add(file);
    }

    // Process each nearby day-month to find significant days
    for (final dayMonth in dayMonthYearGroups.keys) {
      final dayDiff = dayMonth - currentDayMonth;
      if (dayDiff < 0 || dayDiff > 2) continue;
      // TODO: lau: this doesn't cover month changes properly

      final yearGroups = dayMonthYearGroups[dayMonth]!;
      final significantDays = yearGroups.entries
          .where((e) => e.value.length > significantDayThreshold)
          .map((e) => e.key)
          .toList();

      if (significantDays.length >= 3) {
        // Combine all years for this day-month
        final date =
            DateTime(currentTime.year, dayMonth ~/ 100, dayMonth % 100);
        final allPhotos = yearGroups.values.expand((x) => x).toList();
        final photoSelection = await _bestSelection(allPhotos);

        searchResults.add(
          GenericSearchResult(
            ResultType.event,
            "${DateFormat('MMMM d').format(date)} through the years",
            photoSelection,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: DateFormat('MMMM d').format(date),
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.event,
              matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
              filterIcon: Icons.event_outlined,
            ),
          ),
        );
      } else {
        // Individual entries for significant years
        for (final year in significantDays) {
          final date = DateTime(year, dayMonth ~/ 100, dayMonth % 100);
          final files = yearGroups[year]!;
          final photoSelection = await _bestSelection(files);
          String name =
              DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                  .format(date);
          if (date.day == currentTime.day && date.month == currentTime.month) {
            name = "This day, ${currentTime.year - date.year} years back";
          }

          searchResults.add(
            GenericSearchResult(
              ResultType.event,
              name,
              photoSelection,
              hierarchicalSearchFilter: TopLevelGenericFilter(
                filterName: name,
                occurrence: kMostRelevantFilter,
                filterResultType: ResultType.event,
                matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
                filterIcon: Icons.event_outlined,
              ),
            ),
          );
        }
      }

      if (limit != null && searchResults.length >= limit) return searchResults;
    }

    // process to find significant weeks (only if there are no significant days)
    if (searchResults.isEmpty) {
      // Group files by week and year
      final currentWeekYearGroups = <int, List<EnteFile>>{};
      for (final file in allFiles) {
        if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

        final creationTime =
            DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final week = _getWeekNumber(creationTime);
        if (week != currentWeek) continue;
        final year = creationTime.year;

        currentWeekYearGroups.putIfAbsent(year, () => []).add(file);
      }

      // Process the week and see if it's significant
      if (currentWeekYearGroups.isNotEmpty) {
        final significantWeeks = currentWeekYearGroups.entries
            .where((e) => e.value.length > significantWeekThreshold)
            .map((e) => e.key)
            .toList();
        if (significantWeeks.length >= 3) {
          // Combine all years for this week
          final allPhotos =
              currentWeekYearGroups.values.expand((x) => x).toList();
          final photoSelection = await _bestSelection(allPhotos);

          searchResults.add(
            GenericSearchResult(
              ResultType.event,
              "This week through the years",
              photoSelection,
              hierarchicalSearchFilter: TopLevelGenericFilter(
                filterName: "Week $currentWeek",
                occurrence: kMostRelevantFilter,
                filterResultType: ResultType.event,
                matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
                filterIcon: Icons.event_outlined,
              ),
            ),
          );
        } else {
          // Individual entries for significant years
          for (final year in significantWeeks) {
            final date = DateTime(year, 1, 1).add(
              Duration(days: (currentWeek - 1) * 7),
            );
            final files = currentWeekYearGroups[year]!;
            final photoSelection = await _bestSelection(files);
            final name =
                "This week, ${currentTime.year - date.year} years back";

            searchResults.add(
              GenericSearchResult(
                ResultType.event,
                name,
                photoSelection,
                hierarchicalSearchFilter: TopLevelGenericFilter(
                  filterName: name,
                  occurrence: kMostRelevantFilter,
                  filterResultType: ResultType.event,
                  matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
                  filterIcon: Icons.event_outlined,
                ),
              ),
            );
          }
        }
      }
    }

    if (limit != null && searchResults.length >= limit) return searchResults;

    // process to find fillers (months)
    const wantedMemories = 3;
    final neededMemories = wantedMemories - searchResults.length;
    if (neededMemories <= 0) return searchResults;
    const monthSelectionSize = 20;

    // Group files by month and year
    final currentMonthYearGroups = <int, List<EnteFile>>{};
    for (final file in allFiles) {
      if (file.creationTime! > cutOffTime.microsecondsSinceEpoch) continue;

      final creationTime =
          DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final month = creationTime.month;
      if (month != currentMonth) continue;
      final year = creationTime.year;

      currentMonthYearGroups.putIfAbsent(year, () => []).add(file);
    }

    // Add the largest two months plus the month through the years
    final sortedYearsForCurrentMonth = currentMonthYearGroups.keys.toList()
      ..sort(
        (a, b) => currentMonthYearGroups[b]!.length.compareTo(
              currentMonthYearGroups[a]!.length,
            ),
      );
    if (neededMemories > 1) {
      for (int i = neededMemories; i > 1; i--) {
        if (sortedYearsForCurrentMonth.isEmpty) break;
        final year = sortedYearsForCurrentMonth.removeAt(0);
        final monthYearFiles = currentMonthYearGroups[year]!;
        final photoSelection = await _bestSelection(
          monthYearFiles,
          prefferedSize: monthSelectionSize,
        );
        final monthName =
            DateFormat.MMMM(Localizations.localeOf(context).languageCode)
                .format(DateTime(year, currentMonth));
        final name = monthName + ", ${currentTime.year - year} years back";
        searchResults.add(
          GenericSearchResult(
            ResultType.event,
            name,
            photoSelection,
            hierarchicalSearchFilter: TopLevelGenericFilter(
              filterName: name,
              occurrence: kMostRelevantFilter,
              filterResultType: ResultType.event,
              matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
              filterIcon: Icons.event_outlined,
            ),
          ),
        );
      }
    }
    // Show the month through the remaining years
    if (sortedYearsForCurrentMonth.isEmpty) return searchResults;
    final allPhotos = sortedYearsForCurrentMonth
        .expand((year) => currentMonthYearGroups[year]!)
        .toList();
    final photoSelection =
        await _bestSelection(allPhotos, prefferedSize: monthSelectionSize);
    final monthName =
        DateFormat.MMMM(Localizations.localeOf(context).languageCode)
            .format(DateTime(currentTime.year, currentMonth));
    final name = monthName + " through the years";
    searchResults.add(
      GenericSearchResult(
        ResultType.event,
        name,
        photoSelection,
        hierarchicalSearchFilter: TopLevelGenericFilter(
          filterName: name,
          occurrence: kMostRelevantFilter,
          filterResultType: ResultType.event,
          matchedUploadedIDs: filesToUploadedFileIDs(photoSelection),
          filterIcon: Icons.event_outlined,
        ),
      ),
    );

    return searchResults;
  }

  int _getWeekNumber(DateTime date) {
    // Get day of year (1-366)
    final int dayOfYear = int.parse(DateFormat('D').format(date));
    // Integer division by 7 and add 1 to start from week 1
    return ((dayOfYear - 1) ~/ 7) + 1;
  }

  Future<String?> _tryFindLocationName(
    List<EnteFile> files, {
    bool base = false,
  }) async {
    final results = await locationService.getFilesInCity(files, '');
    final List<City> sortedByResultCount = results.keys.toList()
      ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
    if (sortedByResultCount.isEmpty) return null;
    final biggestPlace = sortedByResultCount.first;
    if (results[biggestPlace]!.length > files.length / 2) {
      return biggestPlace.city;
    }
    if (results.length > 2 &&
        results.keys.map((city) => city.country).toSet().length == 1 &&
        !base) {
      return biggestPlace.country;
    }
    return null;
  }

  /// Returns the best selection of files from the given list.
  /// Makes sure that the selection is not more than [prefferedSize] or 10 files,
  /// and that each year of the original list is represented.
  Future<List<EnteFile>> _bestSelection(
    List<EnteFile> files, {
    int? prefferedSize,
  }) async {
    final fileCount = files.length;
    int targetSize = prefferedSize ?? 10;
    if (fileCount <= targetSize) return files;
    final safeFiles =
        files.where((file) => file.uploadedFileID != null).toList();
    final safeCount = safeFiles.length;
    final fileIDs = safeFiles.map((e) => e.uploadedFileID!).toSet();
    final fileIdToFace = await MLDataDB.instance.getFacesForFileIDs(fileIDs);
    final faceIDs =
        fileIdToFace.values.expand((x) => x.map((face) => face.faceID)).toSet();
    final faceIDsToPersonID =
        await MLDataDB.instance.getFaceIdToPersonIdForFaces(faceIDs);
    final fileIdToClip =
        await MLDataDB.instance.getClipVectorsForFileIDs(fileIDs);
    final allYears = safeFiles.map((e) {
      final creationTime = DateTime.fromMicrosecondsSinceEpoch(e.creationTime!);
      return creationTime.year;
    }).toSet();

    // Get clip scores for each file
    const query =
        'Photo of a precious memory radiating warmth, vibrant energy, or quiet beauty — alive with color, light, or emotion';
    // TODO: lau: optimize this later so we don't keep computing embedding
    final textEmbedding = await MLComputer.instance.runClipText(query);
    final textVector = Vector.fromList(textEmbedding);
    const clipThreshold = 0.75;
    final fileToScore = <int, double>{};
    for (final file in safeFiles) {
      final clip = fileIdToClip[file.uploadedFileID!];
      if (clip == null) {
        fileToScore[file.uploadedFileID!] = 0;
        continue;
      }
      final score = clip.vector.dot(textVector);
      fileToScore[file.uploadedFileID!] = score;
    }

    // Get face scores for each file
    final fileToFaceCount = <int, int>{};
    for (final file in safeFiles) {
      final fileID = file.uploadedFileID!;
      fileToFaceCount[fileID] = 0;
      final faces = fileIdToFace[fileID];
      if (faces == null || faces.isEmpty) {
        continue;
      }
      for (final face in faces) {
        if (faceIDsToPersonID.containsKey(face.faceID)) {
          fileToFaceCount[fileID] = fileToFaceCount[fileID]! + 10;
        } else {
          fileToFaceCount[fileID] = fileToFaceCount[fileID]! + 1;
        }
      }
    }

    final filteredFiles = <EnteFile>[];
    if (allYears.length <= 1) {
      // TODO: lau: eventually this sorting might have to be replaced with some scoring system
      // sort first on clip embeddings score (descending)
      safeFiles.sort(
        (a, b) => fileToScore[b.uploadedFileID!]!
            .compareTo(fileToScore[a.uploadedFileID!]!),
      );
      // then sort on faces (descending), heavily prioritizing named faces
      safeFiles.sort(
        (a, b) => fileToFaceCount[b.uploadedFileID!]!
            .compareTo(fileToFaceCount[a.uploadedFileID!]!),
      );

      // then filter out similar images as much as possible
      filteredFiles.add(safeFiles.first);
      int skipped = 0;
      filesLoop:
      for (final file in safeFiles.sublist(1)) {
        if (filteredFiles.length >= targetSize) break;
        final clip = fileIdToClip[file.uploadedFileID!];
        if (clip != null && (safeCount - skipped) > targetSize) {
          for (final filteredFile in filteredFiles) {
            final fClip = fileIdToClip[filteredFile.uploadedFileID!];
            if (fClip == null) continue;
            final similarity = clip.vector.dot(fClip.vector);
            if (similarity > clipThreshold) {
              skipped++;
              continue filesLoop;
            }
          }
        }
        filteredFiles.add(file);
      }
    } else {
      // Multiple years, each represented and roughly equally distributed
      if (prefferedSize == null && (allYears.length * 2) > 10) {
        targetSize = allYears.length * 3;
        if (safeCount < targetSize) return safeFiles;
      }

      // Group files by year and sort each year's list by CLIP then face count
      final yearToFiles = <int, List<EnteFile>>{};
      for (final file in safeFiles) {
        final creationTime =
            DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final year = creationTime.year;
        yearToFiles.putIfAbsent(year, () => []).add(file);
      }

      for (final year in yearToFiles.keys) {
        final yearFiles = yearToFiles[year]!;
        // sort first on clip embeddings score (descending)
        yearFiles.sort(
          (a, b) => fileToScore[b.uploadedFileID!]!
              .compareTo(fileToScore[a.uploadedFileID!]!),
        );
        // then sort on faces (descending), heavily prioritizing named faces
        yearFiles.sort(
          (a, b) => fileToFaceCount[b.uploadedFileID!]!
              .compareTo(fileToFaceCount[a.uploadedFileID!]!),
        );
      }

      // Then join the years together one by one and filter similar images
      final years = yearToFiles.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Recent years first
      int round = 0;
      int skipped = 0;
      whileLoop:
      while (filteredFiles.length + skipped < safeCount) {
        yearLoop:
        for (final year in years) {
          final yearFiles = yearToFiles[year]!;
          if (yearFiles.isEmpty) continue;
          final newFile = yearFiles.removeAt(0);
          if (round != 0 && (safeCount - skipped) > targetSize) {
            // check for filtering
            final clip = fileIdToClip[newFile.uploadedFileID!];
            if (clip != null) {
              for (final filteredFile in filteredFiles) {
                final fClip = fileIdToClip[filteredFile.uploadedFileID!];
                if (fClip == null) continue;
                final similarity = clip.vector.dot(fClip.vector);
                if (similarity > clipThreshold) {
                  skipped++;
                  continue yearLoop;
                }
              }
            }
          }
          filteredFiles.add(newFile);
          if (filteredFiles.length >= targetSize ||
              filteredFiles.length + skipped >= safeCount) {
            break whileLoop;
          }
        }
        round++;
        // Extra safety to prevent infinite loops
        if (round > safeCount) break;
      }
    }

    // Order the final selection chronologically
    filteredFiles.sort((a, b) => b.creationTime!.compareTo(a.creationTime!));
    return filteredFiles;
  }

  Future<GenericSearchResult?> getRandomDateResults(
    BuildContext context,
  ) async {
    final allFiles = await getAllFilesForSearch();
    if (allFiles.isEmpty) return null;

    final length = allFiles.length;
    final randomFile = allFiles[Random().nextInt(length)];
    final creationTime = randomFile.creationTime!;

    final originalDateTime = DateTime.fromMicrosecondsSinceEpoch(creationTime);
    final startOfDay = DateTime(
      originalDateTime.year,
      originalDateTime.month,
      originalDateTime.day,
    );

    final endOfDay = DateTime(
      originalDateTime.year,
      originalDateTime.month,
      originalDateTime.day + 1,
    );

    final durationOfDay = [
      startOfDay.microsecondsSinceEpoch,
      endOfDay.microsecondsSinceEpoch,
    ];

    final matchedFiles = await FilesDB.instance.getFilesCreatedWithinDurations(
      [durationOfDay],
      ignoreCollections(),
      order: 'DESC',
    );

    final name = DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
        .format(originalDateTime.toLocal());
    return GenericSearchResult(
      ResultType.event,
      name,
      matchedFiles,
      hierarchicalSearchFilter: TopLevelGenericFilter(
        filterName: name,
        occurrence: kMostRelevantFilter,
        filterResultType: ResultType.event,
        matchedUploadedIDs: filesToUploadedFileIDs(matchedFiles),
        filterIcon: Icons.event_outlined,
      ),
    );
  }

  Future<List<GenericSearchResult>> getContactSearchResults(
    String query,
  ) async {
    final lowerCaseQuery = query.toLowerCase();
    final searchResults = <GenericSearchResult>[];
    final allFiles = await getAllFilesForSearch();
    final peopleToSharedFiles = <User, List<EnteFile>>{};
    final existingEmails = <String>{};
    for (EnteFile file in allFiles) {
      if (file.isOwner) continue;

      final fileOwner = CollectionsService.instance
          .getFileOwner(file.ownerID!, file.collectionID);

      if (fileOwner.email.toLowerCase().contains(lowerCaseQuery) ||
          ((fileOwner.displayName?.toLowerCase().contains(lowerCaseQuery)) ??
              false)) {
        if (peopleToSharedFiles.containsKey(fileOwner)) {
          peopleToSharedFiles[fileOwner]!.add(file);
        } else {
          peopleToSharedFiles[fileOwner] = [file];
          existingEmails.add(fileOwner.email);
        }
      }
    }

    final relevantContactEmails =
        UserService.instance.getEmailIDsOfRelevantContacts();

    for (final email in relevantContactEmails.difference(existingEmails)) {
      final user = User(email: email);
      if (user.email.toLowerCase().contains(lowerCaseQuery) ||
          ((user.displayName?.toLowerCase().contains(lowerCaseQuery)) ??
              false)) {
        peopleToSharedFiles[user] = [];
      }
    }

    peopleToSharedFiles.forEach((key, value) {
      searchResults.add(
        GenericSearchResult(
          ResultType.shared,
          key.displayName != null && key.displayName!.isNotEmpty
              ? key.displayName!
              : key.email,
          value,
          hierarchicalSearchFilter: ContactsFilter(
            user: key,
            occurrence: kMostRelevantFilter,
            matchedUploadedIDs: filesToUploadedFileIDs(value),
          ),
          params: {
            kPersonParamID: key.linkedPersonID,
            kContactEmail: key.email,
          },
        ),
      );
    });

    return searchResults;
  }

  Future<List<GenericSearchResult>> getAllContactsSearchResults(
    int? limit,
  ) async {
    try {
      final searchResults = <GenericSearchResult>[];
      final allFiles = await getAllFilesForSearch();
      final peopleToSharedFiles = <User, List<EnteFile>>{};
      final existingEmails = <String>{};

      int peopleCount = 0;
      for (EnteFile file in allFiles) {
        if (file.isOwner) continue;

        final fileOwner = CollectionsService.instance
            .getFileOwner(file.ownerID!, file.collectionID);
        if (peopleToSharedFiles.containsKey(fileOwner)) {
          peopleToSharedFiles[fileOwner]!.add(file);
        } else {
          if (limit != null && limit <= peopleCount) continue;
          peopleToSharedFiles[fileOwner] = [file];
          existingEmails.add(fileOwner.email);
          peopleCount++;
        }
      }

      final allRelevantEmails =
          UserService.instance.getEmailIDsOfRelevantContacts();

      int? remainingLimit = limit != null ? limit - peopleCount : null;
      if (remainingLimit != null) {
        // limit - peopleCount will never be negative as of writing this.
        // Just in case if something changes in future, we are handling it here.
        remainingLimit = max(remainingLimit, 0);
      }
      final emailsWithNoSharedFiles =
          allRelevantEmails.difference(existingEmails);

      if (remainingLimit == null) {
        for (final email in emailsWithNoSharedFiles) {
          final user = User(email: email);
          peopleToSharedFiles[user] = [];
        }
      } else {
        for (final email in emailsWithNoSharedFiles) {
          if (remainingLimit == 0) break;
          final user = User(email: email);
          peopleToSharedFiles[user] = [];
          remainingLimit = remainingLimit! - 1;
        }
      }

      peopleToSharedFiles.forEach((key, value) {
        final name = key.displayName != null && key.displayName!.isNotEmpty
            ? key.displayName!
            : key.email;
        searchResults.add(
          GenericSearchResult(
            ResultType.shared,
            name,
            value,
            hierarchicalSearchFilter: ContactsFilter(
              user: key,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(value),
            ),
            params: {
              kPersonParamID: key.linkedPersonID,
              kContactEmail: key.email,
            },
          ),
        );
      });

      return searchResults;
    } catch (e) {
      _logger.severe("Error in getAllLocationTags", e);
      return [];
    }
  }

  List<MonthData> _getMatchingMonths(BuildContext context, String query) {
    return getMonthData(context)
        .where(
          (monthData) =>
              monthData.name.toLowerCase().startsWith(query.toLowerCase()),
        )
        .toList();
  }

  Future<List<EnteFile>> _getFilesInYear(List<int> durationOfYear) async {
    return await FilesDB.instance.getFilesCreatedWithinDurations(
      [durationOfYear],
      ignoreCollections(),
      order: "DESC",
    );
  }

  List<List<int>> _getDurationsForCalendarDateInEveryYear(
    int day,
    int month, {
    int? year,
  }) {
    final List<List<int>> durationsOfHolidayInEveryYear = [];
    final int startYear = year ?? searchStartYear;
    final int endYear = year ?? currentYear;
    for (var yr = startYear; yr <= endYear; yr++) {
      if (isValidGregorianDate(day: day, month: month, year: yr)) {
        durationsOfHolidayInEveryYear.add([
          DateTime(yr, month, day).microsecondsSinceEpoch,
          DateTime(yr, month, day + 1).microsecondsSinceEpoch,
        ]);
      }
    }
    return durationsOfHolidayInEveryYear;
  }

  List<List<int>> _getDurationsOfMonthInEveryYear(int month) {
    final List<List<int>> durationsOfMonthInEveryYear = [];
    for (var year = searchStartYear; year <= currentYear; year++) {
      durationsOfMonthInEveryYear.add([
        DateTime.utc(year, month, 1).microsecondsSinceEpoch,
        month == 12
            ? DateTime(year + 1, 1, 1).microsecondsSinceEpoch
            : DateTime(year, month + 1, 1).microsecondsSinceEpoch,
      ]);
    }
    return durationsOfMonthInEveryYear;
  }

  List<Tuple3<int, MonthData, int?>> _getPossibleEventDate(
    BuildContext context,
    String query,
  ) {
    final List<Tuple3<int, MonthData, int?>> possibleEvents = [];
    if (query.trim().isEmpty) {
      return possibleEvents;
    }
    final result = query
        .trim()
        .split(RegExp('[ ,-/]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final resultCount = result.length;
    if (resultCount < 1 || resultCount > 4) {
      return possibleEvents;
    }

    final int? day = int.tryParse(result[0]);
    if (day == null || day < 1 || day > 31) {
      return possibleEvents;
    }
    final List<MonthData> potentialMonth = resultCount > 1
        ? _getMatchingMonths(context, result[1])
        : getMonthData(context);
    final int? parsedYear = resultCount >= 3 ? int.tryParse(result[2]) : null;
    final List<int> matchingYears = [];
    if (parsedYear != null) {
      bool foundMatch = false;
      for (int i = searchStartYear; i <= currentYear; i++) {
        if (i.toString().startsWith(parsedYear.toString())) {
          matchingYears.add(i);
          foundMatch = foundMatch || (i == parsedYear);
        }
      }
      if (!foundMatch && parsedYear > 1000 && parsedYear <= currentYear) {
        matchingYears.add(parsedYear);
      }
    }
    for (var element in potentialMonth) {
      if (matchingYears.isEmpty) {
        possibleEvents.add(Tuple3(day, element, null));
      } else {
        for (int yr in matchingYears) {
          possibleEvents.add(Tuple3(day, element, yr));
        }
      }
    }
    return possibleEvents;
  }
}
