import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/location.dart';
import 'package:photos/models/search/location_api_response.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/user_service.dart';

class SearchService {
  List<File> _cachedFiles;
  Future<List<File>> _future;
  final _dio = Network.instance.getDio();
  final _config = Configuration.instance;
  final _logger = Logger((UserService).toString());
  final _collectionService = CollectionsService.instance;
  static const _maximumResultsLimit = 20;

  SearchService._privateConstructor();
  static final SearchService instance = SearchService._privateConstructor();

  Future<void> init() async {
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () async {
      /* In case home screen loads before 5 seconds and user starts search,
       future will not be null.So here getAllFiles won't run again in that case. */
      if (_future == null) {
        getAllFiles();
      }
    });

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _cachedFiles = null;
      getAllFiles();
    });
  }

  Future<List<File>> getAllFiles() async {
    if (_cachedFiles != null) {
      return _cachedFiles;
    }
    if (_future != null) {
      return _future;
    }
    _future = _fetchAllFiles();
    return _future;
  }

  Future<List<File>> getFilesOnFilenameSearch(String query) async {
    final List<File> matchedFiles = [];
    final List<File> files = await getAllFiles();
    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);
    for (int i = 0;
        (i < files.length) && (matchedFiles.length < _maximumResultsLimit);
        i++) {
      final File file = files[i];
      if (file.title.contains(nonCaseSensitiveRegexForQuery)) {
        matchedFiles.add(file);
      }
    }
    return matchedFiles;
  }

  void clearCache() {
    _cachedFiles.clear();
  }

  Future<List<LocationSearchResult>> getLocationSearchResults(
    String query,
  ) async {
    try {
      final List<File> allFiles = await SearchService.instance.getAllFiles();
      final List<LocationSearchResult> locationSearchResults = [];

      final response = await _dio.get(
        _config.getHttpEndpoint() + "/search/location",
        queryParameters: {"query": query, "limit": 4},
        options: Options(
          headers: {"X-Auth-Token": _config.getToken()},
        ),
      );

      final matchedLocationSearchResults =
          LocationApiResponse.fromMap(response.data);

      for (LocationDataFromResponse locationData
          in matchedLocationSearchResults.results) {
        final List<File> filesInLocation = [];

        for (File file in allFiles) {
          if (_isValidLocation(file.location) &&
              _isLocationWithinBounds(file.location, locationData)) {
            filesInLocation.add(file);
          }
        }
        if (filesInLocation.isNotEmpty) {
          locationSearchResults.add(
            LocationSearchResult(locationData.place, filesInLocation),
          );
        }
      }
      return locationSearchResults;
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  // getFilteredCollectionsWithThumbnail removes deleted or archived or
  // collections which don't have a file from search result
  Future<List<CollectionWithThumbnail>> getFilteredCollectionsWithThumbnail(
    String query,
  ) async {
    final nonCaseSensitiveRegexForQuery = RegExp(query, caseSensitive: false);

    /*latestCollectionFiles is to identify collections which have at least one file as we don't display
     empty collections and to get the file to pass for tumbnail */
    final List<File> latestCollectionFiles =
        await _collectionService.getLatestCollectionFiles();

    final List<CollectionWithThumbnail> filteredCollectionsWithThumbnail = [];

    for (File file in latestCollectionFiles) {
      final Collection collection =
          CollectionsService.instance.getCollectionByID(file.collectionID);
      if (!collection.isArchived() &&
          collection.name.contains(nonCaseSensitiveRegexForQuery)) {
        filteredCollectionsWithThumbnail
            .add(CollectionWithThumbnail(collection, file));
      }
      if (filteredCollectionsWithThumbnail.length > _maximumResultsLimit) {
        break;
      }
    }

    return filteredCollectionsWithThumbnail;
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

  Future<List<File>> _fetchAllFiles() async {
    _cachedFiles = await FilesDB.instance.getAllFilesFromDB();
    return _cachedFiles;
  }
}
