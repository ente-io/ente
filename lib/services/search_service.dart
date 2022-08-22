import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/data/holidays.dart';
import 'package:photos/data/months.dart';
import 'package:photos/data/years.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/holiday_search_result.dart';
import 'package:photos/models/search/location_api_response.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/models/search/month_search_result.dart';
import 'package:photos/models/search/year_search_result.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/date_time_util.dart';

class SearchService {
  Future<List<File>> _cachedFilesFuture;
  final _dio = Network.instance.getDio();
  final _config = Configuration.instance;
  final _logger = Logger((SearchService).toString());
  final _collectionService = CollectionsService.instance;
  static const _maximumResultsLimit = 20;

  SearchService._privateConstructor();
  static final SearchService instance = SearchService._privateConstructor();

  Future<void> init() async {
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () async {
      /* In case home screen loads before 5 seconds and user starts search,
       future will not be null.So here getAllFiles won't run again in that case. */
      if (_cachedFilesFuture == null) {
        getAllFiles();
      }
    });

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _cachedFilesFuture = null;
      getAllFiles();
    });
  }

  Future<List<File>> getAllFiles() async {
    if (_cachedFilesFuture != null) {
      return _cachedFilesFuture;
    }
    _cachedFilesFuture = FilesDB.instance.getAllFilesFromDB();
    return _cachedFilesFuture;
  }

  Future<List<File>> getFileSearchResults(String query) async {
    final List<File> fileSearchResults = [];
    final List<File> files = await getAllFiles();
    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);
    for (var file in files) {
      if (fileSearchResults.length >= _maximumResultsLimit) {
        break;
      }
      if (file.title.contains(nonCaseSensitiveRegexForQuery)) {
        fileSearchResults.add(file);
      }
    }
    return fileSearchResults;
  }

  void clearCache() {
    _cachedFilesFuture = null;
  }

  Future<List<LocationSearchResult>> getLocationSearchResults(
    String query,
  ) async {
    final List<LocationSearchResult> locationSearchResults = [];
    try {
      final List<File> allFiles = await SearchService.instance.getAllFiles();

      final response = await _dio.get(
        _config.getHttpEndpoint() + "/search/location",
        queryParameters: {"query": query, "limit": 10},
        options: Options(
          headers: {"X-Auth-Token": _config.getToken()},
        ),
      );

      final matchedLocationSearchResults =
          LocationApiResponse.fromMap(response.data);

      for (var locationData in matchedLocationSearchResults.results) {
        final List<File> filesInLocation = [];

        for (var file in allFiles) {
          if (_isValidLocation(file.location) &&
              _isLocationWithinBounds(file.location, locationData)) {
            filesInLocation.add(file);
          }
        }
        filesInLocation.sort(
          (first, second) => second.creationTime.compareTo(first.creationTime),
        );
        if (filesInLocation.isNotEmpty) {
          locationSearchResults.add(
            LocationSearchResult(locationData.place, filesInLocation),
          );
        }
      }
    } catch (e) {
      _logger.severe(e);
    }
    return locationSearchResults;
  }

  // getFilteredCollectionsWithThumbnail removes deleted or archived or
  // collections which don't have a file from search result
  Future<List<AlbumSearchResult>> getCollectionSearchResults(
    String query,
  ) async {
    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);

    /*latestCollectionFiles is to identify collections which have at least one file as we don't display
     empty collections and to get the file to pass for tumbnail */
    final List<File> latestCollectionFiles =
        await _collectionService.getLatestCollectionFiles();

    final List<AlbumSearchResult> collectionSearchResults = [];

    for (var file in latestCollectionFiles) {
      if (collectionSearchResults.length >= _maximumResultsLimit) {
        break;
      }
      final Collection collection =
          CollectionsService.instance.getCollectionByID(file.collectionID);
      if (!collection.isArchived() &&
          collection.name.contains(nonCaseSensitiveRegexForQuery)) {
        collectionSearchResults
            .add(AlbumSearchResult(CollectionWithThumbnail(collection, file)));
      }
    }

    return collectionSearchResults;
  }

  Future<List<YearSearchResult>> getYearSearchResults(
    String yearFromQuery,
  ) async {
    final List<YearSearchResult> yearSearchResults = [];
    for (var yearData in YearsData.instance.yearsData) {
      if (yearData.year.startsWith(yearFromQuery)) {
        final List<File> filesInYear = await _getFilesInYear(yearData.duration);
        if (filesInYear.isNotEmpty) {
          yearSearchResults.add(
            YearSearchResult(
              yearData.year,
              filesInYear,
            ),
          );
        }
      }
    }
    return yearSearchResults;
  }

  Future<List<HolidaySearchResult>> getHolidaySearchResults(
    String query,
  ) async {
    final List<HolidaySearchResult> holidaySearchResults = [];

    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);

    for (var holiday in allHolidays) {
      if (holiday.name.contains(nonCaseSensitiveRegexForQuery)) {
        final matchedFiles =
            await FilesDB.instance.getFilesCreatedWithinDurations(
          _getDurationsOfHolidayInEveryYear(holiday.day, holiday.month),
          null,
          order: 'DESC',
        );
        if (matchedFiles.isNotEmpty) {
          holidaySearchResults.add(
            HolidaySearchResult(holiday.name, matchedFiles),
          );
        }
      }
    }
    return holidaySearchResults;
  }

  Future<List<MonthSearchResult>> getMonthSearchResults(String query) async {
    final List<MonthSearchResult> monthSearchResults = [];
    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);

    for (var month in allMonths) {
      if (month.name.startsWith(nonCaseSensitiveRegexForQuery)) {
        monthSearchResults.add(
          MonthSearchResult(
            month.name,
            await FilesDB.instance.getFilesCreatedWithinDurations(
              _getDurationsOfMonthInEveryYear(month.monthNumber),
              null,
              order: 'DESC',
            ),
          ),
        );
      }
    }

    return monthSearchResults;
  }

  Future<List<File>> _getFilesInYear(List<int> durationOfYear) async {
    return await FilesDB.instance.getFilesCreatedWithinDurations(
      [durationOfYear],
      null,
      order: "DESC",
    );
  }

  List<List<int>> _getDurationsOfHolidayInEveryYear(int day, int month) {
    final List<List<int>> durationsOfHolidayInEveryYear = [];
    for (var year = 1970; year <= currentYear; year++) {
      durationsOfHolidayInEveryYear.add([
        DateTime(year, month, day).microsecondsSinceEpoch,
        DateTime(year, month, day + 1).microsecondsSinceEpoch,
      ]);
    }
    return durationsOfHolidayInEveryYear;
  }

  List<List<int>> _getDurationsOfMonthInEveryYear(int month) {
    final List<List<int>> durationsOfMonthInEveryYear = [];
    for (var year = 1970; year < currentYear; year++) {
      durationsOfMonthInEveryYear.add([
        DateTime.utc(year, month, 1).microsecondsSinceEpoch,
        month == 12
            ? DateTime(year + 1, 1, 1).microsecondsSinceEpoch
            : DateTime(year, month + 1, 1).microsecondsSinceEpoch,
      ]);
    }
    return durationsOfMonthInEveryYear;
  }

  bool _isValidLocation(Location location) {
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
    return location.longitude > locationData.bbox[0] &&
        location.latitude > locationData.bbox[1] &&
        location.longitude < locationData.bbox[2] &&
        location.latitude < locationData.bbox[3];
  }
}
