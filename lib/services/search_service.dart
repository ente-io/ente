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
import 'package:photos/models/search/location_misc./place_and_bbox.dart';
import 'package:photos/models/search/location_misc./results_to_list_of_place_and_bbox.dart';
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
  static const _kMaximumResultsLimit = 20;

  SearchService._privateConstructor();
  static final SearchService instance = SearchService._privateConstructor();

  Future<void> init() async {
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () async {
      // In case home screen loads before 5 seconds and user starts search, future will not be null
      _future == null
          ? getAllFiles().then((value) {
              _cachedFiles = value;
            })
          : null;
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

  Future<List<File>> _fetchAllFiles() async {
    _cachedFiles = await FilesDB.instance.getAllFilesFromDB();
    return _cachedFiles;
  }

  Future<List<File>> getFilesOnFilenameSearch(String query) async {
    final List<File> matchedFiles = [];
    final List<File> files = await getAllFiles();
    for (int i = 0;
        (i < files.length) && (matchedFiles.length < _kMaximumResultsLimit);
        i++) {
      File file = files[i];
      if (file.title.contains(RegExp(query, caseSensitive: false))) {
        matchedFiles.add(file);
      }
    }
    return matchedFiles;
  }

  void clearCache() {
    _cachedFiles.clear();
  }

  Future<List<LocationSearchResult>> getLocationsAndMatchedFiles(
    String query,
  ) async {
    try {
      final List<File> allFiles = await SearchService.instance.getAllFiles();
      final List<LocationSearchResult> locationsAndMatchedFiles = [];

      final response = await _dio.get(
        _config.getHttpEndpoint() + "/search/location",
        queryParameters: {"query": query, "limit": 4},
        options: Options(
          headers: {"X-Auth-Token": _config.getToken()},
        ),
      );

      final matchedLocationNamesAndBboxs =
          ResultsToListOfPlaceAndBbox.fromMap(response.data);

      for (PlaceAndBbox locationAndBbox
          in matchedLocationNamesAndBboxs.results) {
        locationsAndMatchedFiles.add(
          LocationSearchResult(locationAndBbox.place, []),
        );
        for (File file in allFiles) {
          if (_isValidLocation(file.location)) {
            //format returned by the api is [lng,lat,lng,lat] where indexes 0 & 1 are southwest and 2 & 3 northeast
            if (file.location.longitude > locationAndBbox.bbox[0] &&
                file.location.latitude > locationAndBbox.bbox[1] &&
                file.location.longitude < locationAndBbox.bbox[2] &&
                file.location.latitude < locationAndBbox.bbox[3]) {
              locationsAndMatchedFiles.last.files.add(file);
            }
          }
        }
      }
      locationsAndMatchedFiles.removeWhere((e) => e.files.isEmpty);
      return locationsAndMatchedFiles;
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  bool _isValidLocation(Location location) {
    return location != null &&
        location.latitude != null &&
        location.latitude != 0 &&
        location.longitude != null &&
        location.longitude != 0;
  }

  // getFilteredCollectionsWithThumbnail removes deleted or archived or
  // collections which don't have a file from search result
  Future<List<CollectionWithThumbnail>> getFilteredCollectionsWithThumbnail(
    String query,
  ) async {
    // identify collections which have at least one file as we don't display
    // empty collection

    final List<File> latestCollectionFiles =
        await _collectionService.getLatestCollectionFiles();
    final Map<int, File> collectionIDToLatestFileMap = {
      for (File file in latestCollectionFiles) file.collectionID: file
    };

    /* Identify collections whose name matches the search query
      and is not archived
      and is not deleted
      and has at-least one file
     */

    final List<Collection> matchedCollection = _collectionService
        .getCollectionIDtoCollections()
        .values
        .where(
          (c) =>
              !c.isDeleted && // not deleted
              !c.isArchived() // not archived
              &&
              collectionIDToLatestFileMap.containsKey(c.id) && // the
              // collection is not empty
              c.name.contains(RegExp(query, caseSensitive: false)),
        )
        .toList();
    final List<CollectionWithThumbnail> result = [];
    final limit = matchedCollection.length < _kMaximumResultsLimit
        ? matchedCollection.length
        : _kMaximumResultsLimit;
    for (int i = 0; i < limit; i++) {
      Collection collection = matchedCollection[i];
      result.add(
        CollectionWithThumbnail(
          collection,
          collectionIDToLatestFileMap[collection.id],
        ),
      );
    }
    return result;
  }
}
