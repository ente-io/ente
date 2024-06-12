import "dart:convert";
import "dart:math";

import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import 'package:logging/logging.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/data/holidays.dart';
import 'package:photos/data/months.dart';
import 'package:photos/data/years.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/extensions/string_ext.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/generic_search_result.dart';
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/services/remote_assets_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/ui/viewer/location/add_location_sheet.dart";
import "package:photos/ui/viewer/location/location_screen.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import 'package:photos/utils/date_time_util.dart';
import "package:photos/utils/navigation_util.dart";
import 'package:tuple/tuple.dart';

class SearchService {
  Future<List<EnteFile>>? _cachedFilesFuture;
  Future<List<EnteFile>>? _cachedHiddenFilesFuture;
  final _logger = Logger((SearchService).toString());
  final _collectionService = CollectionsService.instance;
  static const _maximumResultsLimit = 20;
  static const _kMagicPromptsDataUrl = "https://discover.ente.io/v1.json";

  var magicPromptsData = [];

  SearchService._privateConstructor();

  static final SearchService instance = SearchService._privateConstructor();

  void init() {
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      // only invalidate, let the load happen on demand
      _cachedFilesFuture = null;
      _cachedHiddenFilesFuture = null;
    });
    if (flagService.internalUser) {
      _loadMagicPrompts();
    }
  }

  Future<dynamic> _loadMagicPrompts() async {
    final file = await RemoteAssetsService.instance
        .getAsset(_kMagicPromptsDataUrl, refetch: true);

    final json = jsonDecode(await file.readAsString());
    magicPromptsData = json["prompts"];
  }

  Set<int> ignoreCollections() {
    return CollectionsService.instance.getHiddenCollectionIds();
  }

  Future<List<EnteFile>> getAllFiles() async {
    if (_cachedFilesFuture != null) {
      return _cachedFilesFuture!;
    }
    _logger.fine("Reading all files from db");
    _cachedFilesFuture = FilesDB.instance.getAllFilesFromDB(
      ignoreCollections(),
      dedupeByUploadId: true,
    );
    return _cachedFilesFuture!;
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
            ),
          );
        }
      }
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getMagicSectionResutls() async {
    if (!SemanticSearchService.instance.isMagicSearchEnabledAndReady()) {
      return <GenericSearchResult>[];
    }
    final searchResuts = <GenericSearchResult>[];
    for (Map<String, dynamic> magicPrompt in magicPromptsData) {
      final files = await SemanticSearchService.instance.getMatchingFiles(
        magicPrompt["prompt"],
        scoreThreshold: magicPrompt["minimumScore"],
      );
      if (files.isNotEmpty) {
        searchResuts.add(
          GenericSearchResult(
            ResultType.magic,
            magicPrompt["title"],
            files,
          ),
        );
      }
    }
    return searchResuts;
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
            GenericSearchResult(ResultType.event, holiday.name, matchedFiles),
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
    final List<EnteFile> allFiles = await getAllFiles();
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
    final List<EnteFile> allFiles = await getAllFiles();
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
        searchResults.add(
          GenericSearchResult(
            ResultType.fileType,
            getHumanReadableString(context, key),
            value,
          ),
        );
      });

      extensionsAndMatchingFiles.forEach((key, value) {
        searchResults.add(
          GenericSearchResult(
            ResultType.fileExtension,
            key + "s",
            value,
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

  ///Todo: Optimise + make this function more readable
  //This can be furthur optimized by not just limiting keys to 0 and 1. Use key
  //0 for single word, 1 for 2 word, 2 for 3 ..... and only check the substrings
  //in higher key if there are matches in the lower key.
  Future<List<GenericSearchResult>> getAllDescriptionSearchResults(
    //todo: use limit
    int? limit,
  ) async {
    try {
      final List<GenericSearchResult> searchResults = [];
      final List<EnteFile> allFiles = await getAllFiles();

      //each list element will be substrings from a description mapped by
      //word count = 1 and word count > 1
      //New items will be added to [orderedSubDescriptions] list for every
      //distinct description.
      //[orderedSubDescriptions[x]] has two keys, 0 & 1. Value of key 0 will be single
      //word substrings. Value of key 1 will be multi word subStrings. When
      //iterating through [allFiles], we check for matching substrings from
      //[orderedSubDescriptions[x]] with the file's description. Starts from value
      //of key 0 (x=0). If there are no substring matches from key 0, there will
      //be none from key 1 as well. So these two keys are for avoiding unnecessary
      //checking of all subDescriptions with file description.
      final orderedSubDescs = <Map<int, List<String>>>[];
      final descAndMatchingFiles = <String, Set<EnteFile>>{};
      int distinctFullDescCount = 0;
      final allDistinctFullDescs = <String>[];

      for (EnteFile file in allFiles) {
        if (file.caption != null && file.caption!.isNotEmpty) {
          //This limit doesn't necessarily have to be the limit parameter of the
          //method. Using the same variable to avoid unwanted iterations when
          //iterating over [orderedSubDescriptions] in case there is a limit
          //passed. Using the limit passed here so that there will be almost
          //always be more than 7 descriptionAndMatchingFiles and can shuffle
          //and choose only limited elements from it. Without shuffling,
          //result will be ["hello", "world", "hello world"] for the string
          //"hello world"

          if (limit == null || distinctFullDescCount < limit) {
            final descAlreadyRecorded = allDistinctFullDescs
                .any((element) => element.contains(file.caption!.trim()));

            if (!descAlreadyRecorded) {
              distinctFullDescCount++;
              allDistinctFullDescs.add(file.caption!.trim());
              final words = file.caption!.trim().split(" ");
              orderedSubDescs.add({0: <String>[], 1: <String>[]});

              for (int i = 1; i <= words.length; i++) {
                for (int j = 0; j <= words.length - i; j++) {
                  final subList = words.sublist(j, j + i);
                  final substring = subList.join(" ").toLowerCase();
                  if (i == 1) {
                    orderedSubDescs.last[0]!.add(substring);
                  } else {
                    orderedSubDescs.last[1]!.add(substring);
                  }
                }
              }
            }
          }

          for (Map<int, List<String>> orderedSubDescription
              in orderedSubDescs) {
            bool matchesSingleWordSubString = false;
            for (String subDescription in orderedSubDescription[0]!) {
              if (file.caption!.toLowerCase().contains(subDescription)) {
                matchesSingleWordSubString = true;

                //continue only after setting [matchesSingleWordSubString] to true
                if (subDescription.isAllConnectWords ||
                    subDescription.isLastWordConnectWord) continue;

                if (descAndMatchingFiles.containsKey(subDescription)) {
                  descAndMatchingFiles[subDescription]!.add(file);
                } else {
                  descAndMatchingFiles[subDescription] = {file};
                }
              }
            }
            if (matchesSingleWordSubString) {
              for (String subDescription in orderedSubDescription[1]!) {
                if (subDescription.isAllConnectWords ||
                    subDescription.isLastWordConnectWord) continue;

                if (file.caption!.toLowerCase().contains(subDescription)) {
                  if (descAndMatchingFiles.containsKey(subDescription)) {
                    descAndMatchingFiles[subDescription]!.add(file);
                  } else {
                    descAndMatchingFiles[subDescription] = {file};
                  }
                }
              }
            }
          }
        }
      }

      ///[relevantDescAndFiles] will be a filterd version of [descriptionAndMatchingFiles]
      ///In [descriptionAndMatchingFiles], there will be descriptions with the same
      ///set of matching files. These descriptions will be substrings of a full
      ///description. [relevantDescAndFiles] will keep only the entry which has the
      ///longest description among enties with matching set of files.
      final relevantDescAndFiles = <String, Set<EnteFile>>{};
      while (descAndMatchingFiles.isNotEmpty) {
        final baseEntry = descAndMatchingFiles.entries.first;
        final descsWithSameFiles = <String, Set<EnteFile>>{};
        final baseUploadedFileIDs =
            baseEntry.value.map((e) => e.uploadedFileID).toSet();

        descAndMatchingFiles.forEach((desc, files) {
          final uploadedFileIDs = files.map((e) => e.uploadedFileID).toSet();

          final hasSameFiles =
              uploadedFileIDs.containsAll(baseUploadedFileIDs) &&
                  baseUploadedFileIDs.containsAll(uploadedFileIDs);
          if (hasSameFiles) {
            descsWithSameFiles.addAll({desc: files});
          }
        });
        descAndMatchingFiles
            .removeWhere((desc, files) => descsWithSameFiles.containsKey(desc));
        final longestDescription = descsWithSameFiles.keys.reduce(
          (desc1, desc2) => desc1.length > desc2.length ? desc1 : desc2,
        );
        relevantDescAndFiles.addAll(
          {longestDescription: descsWithSameFiles[longestDescription]!},
        );
      }

      relevantDescAndFiles.forEach((key, value) {
        searchResults.add(
          GenericSearchResult(ResultType.fileCaption, key, value.toList()),
        );
      });
      if (limit != null) {
        return searchResults.sublist(0, min(limit, searchResults.length));
      } else {
        return searchResults;
      }
    } catch (e) {
      _logger.severe("Error in getAllDescriptionSearchResults", e);
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
    final List<EnteFile> allFiles = await getAllFiles();
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
        ),
      );
    }
    if (displayNameMatch.isNotEmpty) {
      searchResults.add(
        GenericSearchResult(
          ResultType.file,
          query,
          displayNameMatch,
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

    final List<EnteFile> allFiles = await getAllFiles();
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
        ),
      );
    }
    return searchResults;
  }

  Future<List<GenericSearchResult>> getLocationResults(String query) async {
    final locationTagEntities =
        (await LocationService.instance.getLocationTags());
    final Map<LocalEntity<LocationTag>, List<EnteFile>> result = {};
    final bool showNoLocationTag = query.length > 2 &&
        "No Location Tag".toLowerCase().startsWith(query.toLowerCase());

    final List<GenericSearchResult> searchResults = [];

    for (LocalEntity<LocationTag> tag in locationTagEntities) {
      if (tag.item.name.toLowerCase().contains(query.toLowerCase())) {
        result[tag] = [];
      }
    }
    final allFiles = await getAllFiles();
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
    final results =
        await LocationService.instance.getFilesInCity(allFiles, query);
    final List<City> sortedByResultCount = results.keys.toList()
      ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
    for (final city in sortedByResultCount) {
      // If the location tag already exists for a city, don't add it again
      if (!locationTagNames.contains(city.city)) {
        searchResults.add(
          GenericSearchResult(
            ResultType.location,
            city.city,
            results[city]!,
          ),
        );
      }
    }
    return searchResults;
  }

  Future<Map<int, List<EnteFile>>> getClusterFilesForPersonID(
    String personID,
  ) async {
    _logger.info('getClusterFilesForPersonID $personID');
    final Map<int, Set<int>> fileIdToClusterID =
        await FaceMLDataDB.instance.getFileIdToClusterIDSet(personID);
    _logger.info('faceDbDone getClusterFilesForPersonID $personID');
    final Map<int, List<EnteFile>> clusterIDToFiles = {};
    final allFiles = await getAllFiles();
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

  Future<List<GenericSearchResult>> getAllFace(int? limit) async {
    try {
      debugPrint("getting faces");
      final Map<int, Set<int>> fileIdToClusterID =
          await FaceMLDataDB.instance.getFileIdToClusterIds();
      final Map<String, PersonEntity> personIdToPerson =
          await PersonService.instance.getPersonsMap();
      final clusterIDToPersonID =
          await FaceMLDataDB.instance.getClusterIDToPersonID();

      final List<GenericSearchResult> facesResult = [];
      final Map<int, List<EnteFile>> clusterIdToFiles = {};
      final Map<String, List<EnteFile>> personIdToFiles = {};
      final allFiles = await getAllFiles();
      for (final f in allFiles) {
        if (!fileIdToClusterID.containsKey(f.uploadedFileID ?? -1)) {
          continue;
        }
        final cluserIds = fileIdToClusterID[f.uploadedFileID ?? -1]!;
        for (final cluster in cluserIds) {
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
              kPersonParamID: personID,
              kFileID: files.first.uploadedFileID,
            },
            onResultTap: (ctx) {
              routeToPage(
                ctx,
                PeoplePage(
                  tagPrefix: "${ResultType.faces.toString()}_${p.data.name}",
                  person: p,
                ),
              );
            },
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
        final String clusterName = "$clusterId";

        if (clusterIDToPersonID[clusterId] != null) {
          // This should not happen, means a faceID is assigned to multiple persons.
          _logger.severe(
            "`getAllFace`: Cluster $clusterId should not have person id ${clusterIDToPersonID[clusterId]}",
          );
        }
        if (files.length < kMinimumClusterSizeSearchResult &&
            sortedClusterIds.length > 3) {
          continue;
        }
        facesResult.add(
          GenericSearchResult(
            ResultType.faces,
            clusterName,
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
          ),
        );
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
      final locationTagEntities =
          (await LocationService.instance.getLocationTags());
      final allFiles = await getAllFiles();
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
            ),
          );
        }
      }
      if (limit == null || tagSearchResults.length < limit) {
        final results = await LocationService.instance
            .getFilesInCity(filesWithNoLocTag, '');
        final List<City> sortedByResultCount = results.keys.toList()
          ..sort((a, b) => results[b]!.length.compareTo(results[a]!.length));
        for (final city in sortedByResultCount) {
          if (results[city]!.length <= 1) continue;
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
        searchResults.add(
          GenericSearchResult(
            ResultType.event,
            '$day ${potentialDate.item2.name} ${year ?? ''}',
            matchedFiles,
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
      searchResults.add(GenericSearchResult(ResultType.magic, query, files));
    }
    return searchResults;
  }

  Future<GenericSearchResult?> getRandomDateResults(
    BuildContext context,
  ) async {
    final allFiles = await getAllFiles();
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

    return GenericSearchResult(
      ResultType.event,
      DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(
        DateTime.fromMicrosecondsSinceEpoch(creationTime).toLocal(),
      ),
      matchedFiles,
    );
  }

  Future<List<GenericSearchResult>> getContactSearchResults(
    String query,
  ) async {
    final lowerCaseQuery = query.toLowerCase();
    final searchResults = <GenericSearchResult>[];
    final allFiles = await getAllFiles();
    final peopleToSharedFiles = <User, List<EnteFile>>{};
    for (EnteFile file in allFiles) {
      if (file.isOwner) continue;

      final fileOwner = CollectionsService.instance
          .getFileOwner(file.ownerID!, file.collectionID);

      if (fileOwner.email.toLowerCase().contains(lowerCaseQuery) ||
          ((fileOwner.name?.toLowerCase().contains(lowerCaseQuery)) ?? false)) {
        if (peopleToSharedFiles.containsKey(fileOwner)) {
          peopleToSharedFiles[fileOwner]!.add(file);
        } else {
          peopleToSharedFiles[fileOwner] = [file];
        }
      }
    }

    peopleToSharedFiles.forEach((key, value) {
      searchResults.add(
        GenericSearchResult(
          ResultType.shared,
          key.name != null && key.name!.isNotEmpty ? key.name! : key.email,
          value,
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
      final allFiles = await getAllFiles();
      final peopleToSharedFiles = <User, List<EnteFile>>{};
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
          peopleCount++;
        }
      }

      peopleToSharedFiles.forEach((key, value) {
        searchResults.add(
          GenericSearchResult(
            ResultType.shared,
            key.name != null && key.name!.isNotEmpty
                ? key.name!
                : key.email.split("@")[0],
            value,
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
