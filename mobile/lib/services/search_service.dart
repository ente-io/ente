import "dart:async";
import "dart:math";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:logging/logging.dart';
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
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";
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
import "package:photos/models/search/hierarchical/uploader_filter.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/states/location_screen_state.dart";
import "package:photos/ui/viewer/location/add_location_sheet.dart";
import "package:photos/ui/viewer/location/location_screen.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";
import 'package:photos/utils/standalone/date_time.dart';
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
    unawaited(memoriesCacheService.clearMemoriesCache());
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
    if (flagService.hasGrantedMLConsent) {
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
    final Map<String, List<EnteFile>> uploaderToFile = {};
    for (EnteFile eachFile in allFiles) {
      if (eachFile.caption != null && pattern.hasMatch(eachFile.caption!)) {
        captionMatch.add(eachFile);
      }
      if (pattern.hasMatch(eachFile.displayName)) {
        displayNameMatch.add(eachFile);
      }
      if (eachFile.uploaderName != null &&
          pattern.hasMatch(eachFile.uploaderName!)) {
        if (!uploaderToFile.containsKey(eachFile.uploaderName!)) {
          uploaderToFile[eachFile.uploaderName!] = [];
        }
        uploaderToFile[eachFile.uploaderName!]!.add(eachFile);
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
    if (uploaderToFile.isNotEmpty) {
      for (MapEntry<String, List<EnteFile>> entry in uploaderToFile.entries) {
        searchResults.add(
          GenericSearchResult(
            ResultType.uploader,
            entry.key,
            entry.value,
            hierarchicalSearchFilter: UploaderFilter(
              uploaderName: entry.key,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(entry.value),
            ),
          ),
        );
      }
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
      // Add the found base locations from the location/memories service
      // TODO: lau: Add base location names
      // if (limit == null || tagSearchResults.length < limit) {
      //   for (final BaseLocation base in locationService.baseLocations) {
      //     final a = (baseRadius * scaleFactor(base.location.latitude!)) /
      //         kilometersPerDegree;
      //     const b = baseRadius / kilometersPerDegree;
      //     tagSearchResults.add(
      //       GenericSearchResult(
      //         ResultType.location,
      //         "Base",
      //         base.files,
      //         onResultTap: (ctx) {
      //           showAddLocationSheet(
      //             ctx,
      //             base.location,
      //             name: "Base",
      //             radius: baseRadius,
      //           );
      //         },
      //         hierarchicalSearchFilter: LocationFilter(
      //           locationTag: LocationTag(
      //             name: "Base",
      //             radius: baseRadius,
      //             centerPoint: base.location,
      //             aSquare: a * a,
      //             bSquare: b * b,
      //           ),
      //           occurrence: kMostRelevantFilter,
      //           matchedUploadedIDs: filesToUploadedFileIDs(base.files),
      //         ),
      //       ),
      //     );
      //   }
      // }

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

  /// For debug purposes only, don't use this in production!
  Future<List<GenericSearchResult>> smartMemories(
    BuildContext context,
    int? limit,
  ) async {
    DateTime calcTime = DateTime.now();
    late List<SmartMemory> memories;
    if (limit != null) {
      memories = await memoriesCacheService.getMemories();
    } else {
      // await two seconds to let new page load first
      await Future.delayed(const Duration(seconds: 1));
      final DateTime? pickedTime = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (pickedTime != null) calcTime = pickedTime;

      final cache = await memoriesCacheService.debugCacheForTesting();
      final memoriesResult = await smartMemoriesService
          .calcMemories(calcTime, cache, debugSurfaceAll: true);
      locationService.baseLocations = memoriesResult.baseLocations;
      memories = memoriesResult.memories;
    }
    final searchResults = <GenericSearchResult>[];
    for (final memory in memories) {
      final files = Memory.filesFromMemories(memory.memories);
      searchResults.add(
        GenericSearchResult(
          ResultType.event,
          memory.title + "(I)",
          files,
          hierarchicalSearchFilter: TopLevelGenericFilter(
            filterName: memory.title,
            occurrence: kMostRelevantFilter,
            filterResultType: ResultType.event,
            matchedUploadedIDs: filesToUploadedFileIDs(files),
            filterIcon: Icons.event_outlined,
          ),
        ),
      );
    }
    return searchResults;
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
