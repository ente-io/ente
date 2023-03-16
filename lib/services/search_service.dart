import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/data/holidays.dart';
import 'package:photos/data/months.dart';
import 'package:photos/data/years.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/generic_search_result.dart';
import 'package:photos/models/search/location_api_response.dart';
import 'package:photos/models/search/search_result.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:tuple/tuple.dart';

class SearchService {
  Future<List<File>>? _cachedFilesFuture;
  final _logger = Logger((SearchService).toString());
  final _collectionService = CollectionsService.instance;
  static const _maximumResultsLimit = 20;

  SearchService._privateConstructor();

  static final SearchService instance = SearchService._privateConstructor();

  void init() {
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      // only invalidate, let the load happen on demand
      _cachedFilesFuture = null;
    });
  }

  Set<int> ignoreCollections() {
    return CollectionsService.instance.getHiddenCollections();
  }

  Future<List<File>> _getAllFiles() async {
    if (_cachedFilesFuture != null) {
      return _cachedFilesFuture!;
    }
    _logger.fine("Reading all files from db");
    _cachedFilesFuture =
        FilesDB.instance.getAllFilesFromDB(ignoreCollections());
    return _cachedFilesFuture!;
  }

  void clearCache() {
    _cachedFilesFuture = null;
  }

  Future<List<GenericSearchResult>> getLocationSearchResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    try {
      final List<File> allFiles = await _getAllFiles();
      // This code used an deprecated API earlier. We've retained the
      // scaffolding for when we implement a client side location search, and
      // meanwhile have replaced the API response.data with an empty map here.
      final matchedLocationSearchResults = LocationApiResponse.fromMap({});

      for (var locationData in matchedLocationSearchResults.results) {
        final List<File> filesInLocation = [];

        for (var file in allFiles) {
          if (_isValidLocation(file.location) &&
              _isLocationWithinBounds(file.location!, locationData)) {
            filesInLocation.add(file);
          }
        }
        filesInLocation.sort(
          (first, second) =>
              second.creationTime!.compareTo(first.creationTime!),
        );
        if (filesInLocation.isNotEmpty) {
          searchResults.add(
            GenericSearchResult(
              ResultType.location,
              locationData.place,
              filesInLocation,
            ),
          );
        }
      }
    } catch (e) {
      _logger.severe(e);
    }
    return searchResults;
  }

  // getFilteredCollectionsWithThumbnail removes deleted or archived or
  // collections which don't have a file from search result
  Future<List<AlbumSearchResult>> getCollectionSearchResults(
    String query,
  ) async {
    final List<CollectionWithThumbnail> collectionWithThumbnails =
        await _collectionService.getCollectionsWithThumbnails(
      includedOwnedByOthers: true,
    );

    final List<AlbumSearchResult> collectionSearchResults = [];

    for (var c in collectionWithThumbnails) {
      if (collectionSearchResults.length >= _maximumResultsLimit) {
        break;
      }

      if (!c.collection.isHidden() &&
          c.collection.type != CollectionType.uncategorized &&
          c.collection.name!.toLowerCase().contains(
                query.toLowerCase(),
              )) {
        collectionSearchResults.add(AlbumSearchResult(c));
      }
    }

    return collectionSearchResults;
  }

  Future<List<GenericSearchResult>> getYearSearchResults(
    String yearFromQuery,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    for (var yearData in YearsData.instance.yearsData) {
      if (yearData.year.startsWith(yearFromQuery)) {
        final List<File> filesInYear = await _getFilesInYear(yearData.duration);
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

  Future<List<GenericSearchResult>> getHolidaySearchResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];

    for (var holiday in allHolidays) {
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

  Future<List<GenericSearchResult>> getFileTypeResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final List<File> allFiles = await _getAllFiles();
    for (var fileType in FileType.values) {
      final String fileTypeString = getHumanReadableString(fileType);
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

  Future<List<GenericSearchResult>> getCaptionAndNameResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    if (query.isEmpty) {
      return searchResults;
    }
    final RegExp pattern = RegExp(query, caseSensitive: false);
    final List<File> allFiles = await _getAllFiles();
    final List<File> captionMatch = <File>[];
    final List<File> displayNameMatch = <File>[];
    for (File eachFile in allFiles) {
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

    final List<File> allFiles = await _getAllFiles();
    final Map<String, List<File>> resultMap = <String, List<File>>{};

    for (File eachFile in allFiles) {
      final String fileName = eachFile.displayName;
      if (fileName.contains(query)) {
        final String exnType = fileName.split(".").last.toUpperCase();
        if (!resultMap.containsKey(exnType)) {
          resultMap[exnType] = <File>[];
        }
        resultMap[exnType]!.add(eachFile);
      }
    }
    for (MapEntry<String, List<File>> entry in resultMap.entries) {
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

  Future<List<GenericSearchResult>> getMonthSearchResults(String query) async {
    final List<GenericSearchResult> searchResults = [];
    for (var month in _getMatchingMonths(query)) {
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

  Future<List<GenericSearchResult>> getDateResults(
    String query,
  ) async {
    final List<GenericSearchResult> searchResults = [];
    final potentialDates = _getPossibleEventDate(query);

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

  List<MonthData> _getMatchingMonths(String query) {
    return allMonths
        .where(
          (monthData) =>
              monthData.name.toLowerCase().startsWith(query.toLowerCase()),
        )
        .toList();
  }

  Future<List<File>> _getFilesInYear(List<int> durationOfYear) async {
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
      if (isValidDate(day: day, month: month, year: yr)) {
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

  bool _isValidLocation(Location? location) {
    return location != null &&
        location.latitude != null &&
        location.latitude != 0 &&
        location.longitude != null &&
        location.longitude != 0;
  }

  bool _isLocationWithinBounds(
    Location location,
    LocationDataFromResponse locationData,
  ) {
    //format returned by the api is [lng,lat,lng,lat] where indexes 0 & 1 are southwest and 2 & 3 northeast
    return location.longitude! > locationData.bbox[0] &&
        location.latitude! > locationData.bbox[1] &&
        location.longitude! < locationData.bbox[2] &&
        location.latitude! < locationData.bbox[3];
  }

  List<Tuple3<int, MonthData, int?>> _getPossibleEventDate(String query) {
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
    final List<MonthData> potentialMonth =
        resultCount > 1 ? _getMatchingMonths(result[1]) : allMonths;
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
