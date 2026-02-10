import "dart:async" show Timer, unawaited;

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/clip_vector_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/offline_files_db.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/ml_computer.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/query_result.dart";
import "package:photos/services/search_service.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class SemanticSearchService {
  static final _logger = Logger("SemanticSearchService");
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();

  final LRUMap<String, List<double>> _queryEmbeddingCache = LRUMap(20);
  static const kMinimumSimilarityThreshold = 0.175;
  MLDataDB get _mlDataDB =>
      isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;

  bool _hasInitialized = false;
  bool _textModelIsLoaded = false;

  final _cacheLock = Lock();
  bool _imageEmbeddingsAreCached = false;
  bool? _cachedEmbeddingsOffline;
  Timer? _embeddingsCacheTimer;
  final Duration _embeddingsCacheDuration = const Duration(seconds: 60);

  Future<(String, List<EnteFile>)>? _searchScreenRequest;
  String? _latestPendingQuery;

  Future<void> init() async {
    if (_hasInitialized) {
      _logger.info("Initialized already");
      return;
    }
    final hasGivenConsent = hasGrantedMLConsent;
    if (!hasGivenConsent) return;

    _logger.info("init called");
    _hasInitialized = true;

    Bus.instance.on<EmbeddingUpdatedEvent>().listen((event) {
      if (_imageEmbeddingsAreCached) {
        MLComputer.instance.clearImageEmbeddingsCache();
        _imageEmbeddingsAreCached = false;
      }
    });

    if (flagService.usearchForSearch) {
      unawaited(_mlDataDB.checkMigrateFillClipVectorDB());
    }

    unawaited(_loadTextModel(delay: true));
  }

  bool isMagicSearchEnabledAndReady() {
    return hasGrantedMLConsent && _textModelIsLoaded;
  }

  // searchScreenQuery should only be used for the user initiate query on the search screen.
  // If there are multiple call tho this method, then for all the calls, the result will be the same as the last query.
  Future<(String, List<EnteFile>)> searchScreenQuery(String query) async {
    if (!isMagicSearchEnabledAndReady()) {
      if (flagService.internalUser) {
        _logger.info(
          "ML global consent: $hasGrantedMLConsent, loaded: $_textModelIsLoaded ",
        );
      }
      return (query, <EnteFile>[]);
    }
    // If there's an ongoing request, just update the last query and return its future.
    if (_searchScreenRequest != null) {
      _latestPendingQuery = query;
      return _searchScreenRequest!;
    } else {
      // No ongoing request, start a new search.
      _searchScreenRequest = getMatchingFiles(query).then((result) {
        // Search completed, reset the ongoing request.
        _searchScreenRequest = null;
        // If there was a new query during the last search, start a new search with the last query.
        if (_latestPendingQuery != null) {
          final String newQuery = _latestPendingQuery!;
          _latestPendingQuery = null; // Reset last query.
          // Recursively call search with the latest query.
          return searchScreenQuery(newQuery);
        }
        return (query, result);
      });
      return _searchScreenRequest!;
    }
  }

  Future<void> clearIndexes() async {
    await _mlDataDB.deleteClipIndexes();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("sync_time_embeddings_v3");
    _logger.info("Indexes cleared");
  }

  Future<void> _cacheClipVectors() async {
    return _cacheLock.synchronized(() async {
      _resetInactivityTimer();
      if (_imageEmbeddingsAreCached) {
        if (_cachedEmbeddingsOffline != isOfflineMode) {
          await MLComputer.instance.clearImageEmbeddingsCache();
          _imageEmbeddingsAreCached = false;
          _cachedEmbeddingsOffline = null;
        } else {
          return;
        }
      }
      if (_imageEmbeddingsAreCached) {
        return;
      }
      final now = DateTime.now();
      final imageEmbeddings = await _mlDataDB.getAllClipVectors();
      _logger.info(
        "read all ${imageEmbeddings.length} embeddings from DB in ${DateTime.now().difference(now).inMilliseconds} ms",
      );
      await MLComputer.instance.cacheImageEmbeddings(imageEmbeddings);
      _imageEmbeddingsAreCached = true;
      _cachedEmbeddingsOffline = isOfflineMode;
      return;
    });
  }

  Future<List<EnteFile>> getMatchingFiles(
    String query, {
    double? similarityThreshold,
  }) async {
    bool showThreshold = false;
    // if the query starts with 0.xxx, the split the query to get score threshold and actual query
    if (query.startsWith(RegExp(r"0\.\d+"))) {
      final parts = query.split(" ");
      if (parts.length > 1) {
        similarityThreshold = double.parse(parts[0]);
        query = parts.sublist(1).join(" ");
        showThreshold = true;
      }
    }
    final textEmbedding = await _getTextEmbedding(query);

    final minimumSimilarity =
        similarityThreshold ?? kMinimumSimilarityThreshold;
    final queryResults = await _getSimilaritiesForUserSearch(
      query,
      textEmbedding,
      minimumSimilarity,
    );
    // Uncomment if needed for debugging: print query for top ten scores
    // if (kDebugMode) {
    //   for (int i = 0; i < min(10, queryResults.length); i++) {
    //     final result = queryResults[i];
    //     dev.log("Query: $query, Score: ${result.score}, index $i");
    //   }
    // }

    final Map<int, double> fileIDToScoreMap = {};
    for (final result in queryResults) {
      fileIDToScoreMap[result.id] = result.score;
    }

    if (isOfflineMode) {
      return _getOfflineMatchingFiles(
        queryResults,
        fileIDToScoreMap,
        showThreshold,
      );
    }

    final filesMap = await FilesDB.instance
        .getFileIDToFileFromIDs(queryResults.map((e) => e.id).toList());

    final ignoredCollections =
        CollectionsService.instance.getHiddenCollectionIds();

    final deletedEntries = <int>[];
    final results = <EnteFile>[];

    for (final result in queryResults) {
      final file = filesMap[result.id];
      if (file != null && !ignoredCollections.contains(file.collectionID)) {
        if (showThreshold) {
          file.debugCaption =
              "${fileIDToScoreMap[result.id]?.toStringAsFixed(3)}";
        }
        results.add(file);
      }

      if (file == null) {
        deletedEntries.add(result.id);
      }
    }

    _logger.info(results.length.toString() + " results");

    if (deletedEntries.isNotEmpty) {
      unawaited(_mlDataDB.deleteClipEmbeddings(deletedEntries));
    }

    return results;
  }

  Future<List<EnteFile>> _getOfflineMatchingFiles(
    List<QueryResult> queryResults,
    Map<int, double> fileIDToScoreMap,
    bool showThreshold,
  ) async {
    final localIdMap = await OfflineFilesDB.instance.getLocalIdsForIntIds(
      queryResults.map((e) => e.id),
    );
    final allFiles = await SearchService.instance.getAllFilesForSearch();
    final ignoredCollections =
        CollectionsService.instance.getHiddenCollectionIds();
    final localIdToFile = <String, EnteFile>{};
    for (final file in allFiles) {
      final localId = file.localID;
      if (localId != null) {
        localIdToFile[localId] = file;
      }
    }

    final results = <EnteFile>[];
    final deletedEntries = <int>[];
    for (final result in queryResults) {
      final localId = localIdMap[result.id];
      final file = localId != null ? localIdToFile[localId] : null;
      if (file != null && !ignoredCollections.contains(file.collectionID)) {
        if (showThreshold) {
          file.debugCaption =
              "${fileIDToScoreMap[result.id]?.toStringAsFixed(3)}";
        }
        results.add(file);
      } else {
        deletedEntries.add(result.id);
      }
    }

    if (deletedEntries.isNotEmpty) {
      unawaited(_mlDataDB.deleteClipEmbeddings(deletedEntries));
    }

    return results;
  }

  /// Get matching file IDs for common repeated queries like smart memories and magic cache.
  /// WARNING: Use this method carefully - it uses persistent caching which is only
  /// beneficial for queries that are repeated across app sessions.
  /// For regular user searches, use getMatchingFiles instead.
  Future<Map<String, List<int>>> getMatchingFileIDsForCommonQueries(
    Map<String, double> queryToScore,
  ) async {
    final textEmbeddings = <String, List<double>>{};
    final minimumSimilarityMap = <String, double>{};

    for (final entry in queryToScore.entries) {
      final query = entry.key;
      final score = entry.value;
      // Use cache service instead of _getTextEmbedding
      final textEmbedding =
          await textEmbeddingsCacheService.getEmbedding(query);
      textEmbeddings[query] = textEmbedding;
      minimumSimilarityMap[query] = score;
    }

    final queryResults = await _getSimilarities(
      textEmbeddings,
      minimumSimilarityMap: minimumSimilarityMap,
      maxResults: 0,
    );

    final result = <String, List<int>>{};
    for (final entry in queryResults.entries) {
      final query = entry.key;
      final queryResult = entry.value;
      final fileIDs = <int>[];
      for (final result in queryResult) {
        fileIDs.add(result.id);
      }
      result[query] = fileIDs;
    }
    return result;
  }

  Future<void> _loadTextModel({bool delay = false}) async {
    _logger.info("Initializing ClipText");
    try {
      if (delay) await Future.delayed(const Duration(seconds: 5));
      await MLComputer.instance.runClipText("warm up text encoder");
      _textModelIsLoaded = true;
    } catch (e, s) {
      _logger.severe("Clip text loading failed", e, s);
    }
    _logger.info("Clip text model loaded");
  }

  Future<void> storeClipImageResult(ClipResult clipResult) async {
    final embedding = ClipEmbedding(
      fileID: clipResult.fileID,
      embedding: clipResult.embedding,
      version: clipMlVersion,
    );
    await _mlDataDB.putClip([embedding]);
  }

  Future<void> storeEmptyClipImageResult(EnteFile entefile) async {
    final embedding = ClipEmbedding.empty(entefile.uploadedFileID!);
    await _mlDataDB.putClip([embedding]);
  }

  Future<List<double>> _getTextEmbedding(String query) async {
    _logger.info("Searching for ${kDebugMode ? query : ''}");
    final cachedResult = _queryEmbeddingCache.get(query);
    if (cachedResult != null) {
      return cachedResult;
    }
    final textEmbedding = await MLComputer.instance.runClipText(query);
    _queryEmbeddingCache.put(query, textEmbedding);
    return textEmbedding;
  }

  Future<Map<String, List<QueryResult>>> _getSimilarities(
    Map<String, List<double>> textQueryToEmbeddingMap, {
    required Map<String, double> minimumSimilarityMap,
    int? maxResults,
  }) async {
    final startTime = DateTime.now();
    // Uncomment if needed for debugging: print query embeddings
    // if (kDebugMode) {
    //   for (final queryText in textQueryToEmbeddingMap.keys) {
    //     final embedding = textQueryToEmbeddingMap[queryText]!;
    //     dev.log("CLIPTEXT Query: $queryText, embedding: $embedding");
    //   }
    // }
    if (await _canUseVectorDbForSearch()) {
      final queryResults = await ClipVectorDB.instance.computeBulkSimilarities(
        textQueryToEmbeddingMap,
        minimumSimilarityMap,
        maxResults: maxResults,
      );
      final endTime = DateTime.now();
      _logger.info(
        "computingSimilarities (usearch) took for ${textQueryToEmbeddingMap.length} queries " +
            (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
                .toString() +
            "ms",
      );
      return queryResults;
    }

    await _cacheClipVectors();
    final Map<String, List<QueryResult>> queryResults =
        await MLComputer.instance.computeBulkSimilarities(
      textQueryToEmbeddingMap,
      minimumSimilarityMap,
    );
    final endTime = DateTime.now();
    _logger.info(
      "computingSimilarities (dot-product) took for ${textQueryToEmbeddingMap.length} queries " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    return queryResults;
  }

  Future<List<QueryResult>> _getSimilaritiesForUserSearch(
    String query,
    List<double> textEmbedding,
    double minimumSimilarity,
  ) async {
    final startTime = DateTime.now();
    if (await _canUseVectorDbForSearch()) {
      final queryResults =
          await ClipVectorDB.instance.searchExactSimilaritiesWithinThreshold(
        textEmbedding,
        minimumSimilarity,
      );
      final endTime = DateTime.now();
      _logger.info(
        "computingSimilarities (usearch exact) took for 1 query " +
            (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
                .toString() +
            "ms",
      );
      return queryResults;
    }

    await _cacheClipVectors();
    final queryResults = await MLComputer.instance.computeBulkSimilarities(
      {query: textEmbedding},
      {query: minimumSimilarity},
    );
    final endTime = DateTime.now();
    _logger.info(
      "computingSimilarities (dot-product) took for 1 query " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    return queryResults[query] ?? <QueryResult>[];
  }

  Future<bool> _canUseVectorDbForSearch() async {
    if (!flagService.usearchForSearch) return false;
    if (!flagService.hasGrantedMLConsent) return false;
    return ClipVectorDB.instance.checkIfMigrationDone();
  }

  void _resetInactivityTimer() {
    _embeddingsCacheTimer?.cancel();
    _embeddingsCacheTimer = Timer(_embeddingsCacheDuration, () {
      _logger.info(
        'Embeddings cache is unused for ${_embeddingsCacheDuration.inSeconds} seconds. Removing cache.',
      );
      if (_imageEmbeddingsAreCached) {
        MLComputer.instance.clearImageEmbeddingsCache();
        _imageEmbeddingsAreCached = false;
      }
    });
  }

  static Future<ClipResult> runClipImage(
    int enteFileID,
    Dimensions dimensions,
    Uint8List rawRgbaBytes,
    int clipImageAddress,
  ) async {
    final embedding = await ClipImageEncoder.predict(
      dimensions,
      rawRgbaBytes,
      clipImageAddress,
      enteFileID,
    );

    final clipResult = ClipResult(fileID: enteFileID, embedding: embedding);

    return clipResult;
  }
}
