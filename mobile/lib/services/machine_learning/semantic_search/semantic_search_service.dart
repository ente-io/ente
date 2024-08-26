import "dart:async" show unawaited;
import "dart:developer" as dev show log;
import "dart:math" show min;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/clip_db.dart";
import "package:photos/db/ml/db.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/cosine_distance.dart";
import "package:photos/services/machine_learning/ml_computer.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  final _logger = Logger("SemanticSearchService");
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();

  static final Computer _computer = Computer.shared();
  final LRUMap<String, List<double>> _queryCache = LRUMap(20);
  static const kMinimumSimilarityThreshold = 0.175;

  bool _hasInitialized = false;
  bool _textModelIsLoaded = false;
  bool _isCacheRefreshPending = true;
  List<ClipEmbedding> _cachedImageEmbeddings = <ClipEmbedding>[];
  Future<(String, List<EnteFile>)>? _searchScreenRequest;
  String? _latestPendingQuery;

  Future<void> init() async {
    if (!localSettings.isMLIndexingEnabled) {
      return;
    }
    if (_hasInitialized) {
      _logger.info("Initialized already");
      return;
    }
    _hasInitialized = true;

    await _refreshClipCache();
    Bus.instance.on<EmbeddingUpdatedEvent>().listen((event) {
      _isCacheRefreshPending = true;
    });

    unawaited(_loadTextModel(delay: true));
  }

  bool isMagicSearchEnabledAndReady() {
    return localSettings.isMLIndexingEnabled &&
        _textModelIsLoaded &&
        _cachedImageEmbeddings.isNotEmpty;
  }

  // searchScreenQuery should only be used for the user initiate query on the search screen.
  // If there are multiple call tho this method, then for all the calls, the result will be the same as the last query.
  Future<(String, List<EnteFile>)> searchScreenQuery(String query) async {
    await _refreshClipCache();
    if (!isMagicSearchEnabledAndReady()) {
      if (flagService.internalUser) {
        _logger.info(
          "Magic search enabled ${localSettings.isMLIndexingEnabled}, loaded $_textModelIsLoaded cached ${_cachedImageEmbeddings.isNotEmpty}",
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
    await MLDataDB.instance.deleteClipIndexes();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("sync_time_embeddings_v3");
    _logger.info("Indexes cleared");
  }

  Future<void> _refreshClipCache() async {
    if (_isCacheRefreshPending == false) {
      return;
    }
    _isCacheRefreshPending = false;
    _logger.info("Pulling cached embeddings");
    final startTime = DateTime.now();
    _cachedImageEmbeddings = await MLDataDB.instance.getAll();
    final endTime = DateTime.now();
    _logger.info(
      "Loading ${_cachedImageEmbeddings.length} took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
    );
    Bus.instance.fire(EmbeddingCacheUpdatedEvent());
    _logger
        .info("Cached embeddings: " + _cachedImageEmbeddings.length.toString());
  }

  Future<List<EnteFile>> getMatchingFiles(
    String query, {
    double? scoreThreshold,
  }) async {
    bool showScore = false;
    // if the query starts with 0.xxx, the split the query to get score threshold and actual query
    if (query.startsWith(RegExp(r"0\.\d+"))) {
      final parts = query.split(" ");
      if (parts.length > 1) {
        scoreThreshold = double.parse(parts[0]);
        query = parts.sublist(1).join(" ");
        showScore = true;
      }
    }
    final textEmbedding = await _getTextEmbedding(query);

    final queryResults = await _getSimilarities(
      textEmbedding,
      minimumSimilarity: scoreThreshold,
    );

    // print query for top ten scores
    for (int i = 0; i < min(10, queryResults.length); i++) {
      final result = queryResults[i];
      dev.log("Query: $query, Score: ${result.score}, index $i");
    }

    final Map<int, double> fileIDToScoreMap = {};
    for (final result in queryResults) {
      fileIDToScoreMap[result.id] = result.score;
    }

    final filesMap = await FilesDB.instance
        .getFilesFromIDs(queryResults.map((e) => e.id).toList());

    final ignoredCollections =
        CollectionsService.instance.getHiddenCollectionIds();

    final deletedEntries = <int>[];
    final results = <EnteFile>[];

    for (final result in queryResults) {
      final file = filesMap[result.id];
      if (file != null && !ignoredCollections.contains(file.collectionID)) {
        if (showScore) {
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
      unawaited(MLDataDB.instance.deleteEmbeddings(deletedEntries));
    }

    return results;
  }

  Future<List<int>> getMatchingFileIDs(
    String query,
    double minimumSimilarity,
  ) async {
    final textEmbedding = await _getTextEmbedding(query);

    final queryResults = await _getSimilarities(
      textEmbedding,
      minimumSimilarity: minimumSimilarity,
    );

    final queryResultIds = <int>[];
    for (QueryResult result in queryResults) {
      queryResultIds.add(result.id);
    }

    final filesMap = await FilesDB.instance.getFilesFromIDs(
      queryResultIds,
    );
    final results = <EnteFile>[];

    final ignoredCollections =
        CollectionsService.instance.getHiddenCollectionIds();
    final deletedEntries = <int>[];
    for (final result in queryResults) {
      final file = filesMap[result.id];
      if (file != null && !ignoredCollections.contains(file.collectionID)) {
        results.add(file);
      }
      if (file == null) {
        deletedEntries.add(result.id);
      }
    }

    _logger.info(results.length.toString() + " results");

    if (deletedEntries.isNotEmpty) {
      unawaited(MLDataDB.instance.deleteEmbeddings(deletedEntries));
    }

    final matchingFileIDs = <int>[];
    for (EnteFile file in results) {
      matchingFileIDs.add(file.uploadedFileID!);
    }

    return matchingFileIDs;
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

  static Future<void> storeClipImageResult(ClipResult clipResult) async {
    final embedding = ClipEmbedding(
      fileID: clipResult.fileID,
      embedding: clipResult.embedding,
      version: clipMlVersion,
    );
    await MLDataDB.instance.put(embedding);
  }

  static Future<void> storeEmptyClipImageResult(EnteFile entefile) async {
    final embedding = ClipEmbedding.empty(entefile.uploadedFileID!);
    await MLDataDB.instance.put(embedding);
  }

  Future<List<double>> _getTextEmbedding(String query) async {
    _logger.info("Searching for " + query);
    final cachedResult = _queryCache.get(query);
    if (cachedResult != null) {
      return cachedResult;
    }
    final textEmbedding = await MLComputer.instance.runClipText(query);
    _queryCache.put(query, textEmbedding);
    return textEmbedding;
  }

  Future<List<QueryResult>> _getSimilarities(
    List<double> textEmbedding, {
    double? minimumSimilarity,
  }) async {
    final startTime = DateTime.now();
    final List<QueryResult> queryResults = await _computer.compute(
      computeBulkSimilarities,
      param: {
        "imageEmbeddings": _cachedImageEmbeddings,
        "textEmbedding": textEmbedding,
        "minimumSimilarity": minimumSimilarity,
      },
      taskName: "computeBulkScore",
    );
    final endTime = DateTime.now();
    _logger.info(
      "computingScores took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    return queryResults;
  }

  static Future<ClipResult> runClipImage(
    int enteFileID,
    Image image,
    ByteData imageByteData,
    int clipImageAddress,
  ) async {
    final startTime = DateTime.now();
    final embedding = await ClipImageEncoder.predict(
      image,
      imageByteData,
      clipImageAddress,
    );

    final clipResult = ClipResult(fileID: enteFileID, embedding: embedding);

    dev.log('Finished running ClipImage for $enteFileID in '
        '${DateTime.now().difference(startTime).inMilliseconds} ms');

    return clipResult;
  }
}

List<QueryResult> computeBulkSimilarities(Map args) {
  final queryResults = <QueryResult>[];
  final imageEmbeddings = args["imageEmbeddings"] as List<ClipEmbedding>;
  final textEmbedding = args["textEmbedding"] as List<double>;
  final minimumSimilarity = args["minimumSimilarity"] ??
      SemanticSearchService.kMinimumSimilarityThreshold;
  double bestScore = 0.0;
  for (final imageEmbedding in imageEmbeddings) {
    final score = computeCosineSimilarity(
      imageEmbedding.embedding,
      textEmbedding,
    );
    if (score >= minimumSimilarity) {
      queryResults.add(QueryResult(imageEmbedding.fileID, score));
    }
    if (score > bestScore) {
      bestScore = score;
    }
  }
  if (kDebugMode && queryResults.isEmpty) {
    dev.log("No results found for query with best score: $bestScore");
  }

  queryResults.sort((first, second) => second.score.compareTo(first.score));
  return queryResults;
}

class QueryResult {
  final int id;
  final double score;

  QueryResult(this.id, this.score);
}
