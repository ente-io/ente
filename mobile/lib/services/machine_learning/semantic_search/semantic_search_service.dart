import "dart:async" show unawaited;
import "dart:developer" as dev show log;
import "dart:math" show min;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/ml_computer.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  static final _logger = Logger("SemanticSearchService");
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();

  static final Computer _computer = Computer.shared();
  final LRUMap<String, List<double>> _queryEmbeddingCache = LRUMap(20);
  static const kMinimumSimilarityThreshold = 0.175;
  late final mlDataDB = MLDataDB.instance;

  bool _hasInitialized = false;
  bool _textModelIsLoaded = false;

  Future<List<EmbeddingVector>>? _cachedImageEmbeddingVectors;
  Future<(String, List<EnteFile>)>? _searchScreenRequest;
  String? _latestPendingQuery;

  Future<void> init() async {
    if (_hasInitialized) {
      _logger.info("Initialized already");
      return;
    }
    final hasGivenConsent = flagService.hasGrantedMLConsent;
    if (!hasGivenConsent) return;

    _logger.info("init called");
    _hasInitialized = true;

    // call getClipEmbeddings after 5 seconds
    Future.delayed(const Duration(seconds: 5), () async {
      await getClipVectors();
    });
    Bus.instance.on<EmbeddingUpdatedEvent>().listen((event) {
      _cachedImageEmbeddingVectors = null;
    });

    unawaited(_loadTextModel(delay: true));
  }

  bool isMagicSearchEnabledAndReady() {
    return flagService.hasGrantedMLConsent && _textModelIsLoaded;
  }

  // searchScreenQuery should only be used for the user initiate query on the search screen.
  // If there are multiple call tho this method, then for all the calls, the result will be the same as the last query.
  Future<(String, List<EnteFile>)> searchScreenQuery(String query) async {
    if (!isMagicSearchEnabledAndReady()) {
      if (flagService.internalUser) {
        _logger.info(
          "ML global consent: ${flagService.hasGrantedMLConsent}, loaded: $_textModelIsLoaded ",
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
    await mlDataDB.deleteClipIndexes();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("sync_time_embeddings_v3");
    _logger.info("Indexes cleared");
  }

  Future<List<EmbeddingVector>> getClipVectors() async {
    if (_cachedImageEmbeddingVectors != null) {
      return _cachedImageEmbeddingVectors!;
    }
    _cachedImageEmbeddingVectors ??= mlDataDB.getAllClipVectors();
    _logger.info("read all embeddings from DB");

    return _cachedImageEmbeddingVectors!;
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

    final similarityResults = await _getSimilarities(
      {query: textEmbedding},
      minimumSimilarityMap: {
        query: similarityThreshold ?? kMinimumSimilarityThreshold,
      },
    );
    final queryResults = similarityResults[query]!;
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
      unawaited(mlDataDB.deleteClipEmbeddings(deletedEntries));
    }

    return results;
  }

  Future<Map<String, List<int>>> getMatchingFileIDs(
    Map<String, double> queryToScore,
  ) async {
    final textEmbeddings = <String, List<double>>{};
    final minimumSimilarityMap = <String, double>{};
    for (final entry in queryToScore.entries) {
      final query = entry.key;
      final score = entry.value;
      final textEmbedding = await _getTextEmbedding(query);
      textEmbeddings[query] = textEmbedding;
      minimumSimilarityMap[query] = score;
    }

    final queryResults = await _getSimilarities(
      textEmbeddings,
      minimumSimilarityMap: minimumSimilarityMap,
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
    await mlDataDB.putClip([embedding]);
  }

  Future<void> storeEmptyClipImageResult(EnteFile entefile) async {
    final embedding = ClipEmbedding.empty(entefile.uploadedFileID!);
    await mlDataDB.putClip([embedding]);
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
  }) async {
    final startTime = DateTime.now();
    final imageEmbeddings = await getClipVectors();
    final Map<String, List<QueryResult>> queryResults = await _computer
        .compute<Map<String, dynamic>, Map<String, List<QueryResult>>>(
      computeBulkSimilarities,
      param: {
        "imageEmbeddings": imageEmbeddings,
        "textQueryToEmbeddingMap": textQueryToEmbeddingMap,
        "minimumSimilarityMap": minimumSimilarityMap,
      },
      taskName: "computeBulkSimilarities",
    );
    final endTime = DateTime.now();
    _logger.info(
      "computingSimilarities took for ${textQueryToEmbeddingMap.length} queries " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    return queryResults;
  }

  static Future<ClipResult> runClipImage(
    int enteFileID,
    Image image,
    Uint8List rawRgbaBytes,
    int clipImageAddress,
  ) async {
    final embedding = await ClipImageEncoder.predict(
      image,
      rawRgbaBytes,
      clipImageAddress,
      enteFileID,
    );

    final clipResult = ClipResult(fileID: enteFileID, embedding: embedding);

    return clipResult;
  }
}

Map<String, List<QueryResult>> computeBulkSimilarities(Map args) {
  final imageEmbeddings = args["imageEmbeddings"] as List<EmbeddingVector>;
  final textEmbedding =
      args["textQueryToEmbeddingMap"] as Map<String, List<double>>;
  final minimumSimilarityMap =
      args["minimumSimilarityMap"] as Map<String, double>;
  final result = <String, List<QueryResult>>{};
  for (final MapEntry<String, List<double>> entry in textEmbedding.entries) {
    final query = entry.key;
    final textVector = Vector.fromList(entry.value);
    final minimumSimilarity = minimumSimilarityMap[query]!;
    final queryResults = <QueryResult>[];
    if (!kDebugMode) {
      for (final imageEmbedding in imageEmbeddings) {
        final similarity = imageEmbedding.vector.dot(textVector);
        if (similarity >= minimumSimilarity) {
          queryResults.add(QueryResult(imageEmbedding.fileID, similarity));
        }
      }
    } else {
      double bestScore = 0.0;
      for (final imageEmbedding in imageEmbeddings) {
        final similarity = imageEmbedding.vector.dot(textVector);
        if (similarity >= minimumSimilarity) {
          queryResults.add(QueryResult(imageEmbedding.fileID, similarity));
        }
        if (similarity > bestScore) {
          bestScore = similarity;
        }
      }
      if (kDebugMode && queryResults.isEmpty) {
        dev.log("No results found for query with best score: $bestScore");
      }
    }
    queryResults.sort((first, second) => second.score.compareTo(first.score));
    result[query] = queryResults;
  }
  return result;
}

class QueryResult {
  final int id;
  final double score;

  QueryResult(this.id, this.score);
}
