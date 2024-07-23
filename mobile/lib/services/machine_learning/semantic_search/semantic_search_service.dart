import "dart:async";
import "dart:developer" as dev show log;
import "dart:io";
import "dart:math" show min;
import "dart:typed_data" show ByteData;
import "dart:ui" show Image;

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/embeddings_db.dart";
import "package:photos/db/files_db.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/face_ml/face_clustering/cosine_distance.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/utils/debouncer.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/ml_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();
  static final Computer _computer = Computer.shared();
  static final LRUMap<String, List<double>> _queryCache = LRUMap(20);

  static const kMinimumSimilarityThreshold = 0.20;
  static const kDebounceDuration = Duration(milliseconds: 4000);

  final _logger = Logger("SemanticSearchService");
  final _embeddingLoaderDebouncer =
      Debouncer(kDebounceDuration, executionInterval: kDebounceDuration);

  bool _hasInitialized = false;
  bool _textModelIsLoaded = false;
  List<ClipEmbedding> _cachedImageEmbeddings = <ClipEmbedding>[];
  Future<(String, List<EnteFile>)>? _searchScreenRequest;
  String? _latestPendingQuery;

  get hasInitialized => _hasInitialized;

  Future<void> init() async {
    if (!LocalSettings.instance.isFaceIndexingEnabled) {
      return;
    }
    if (_hasInitialized) {
      _logger.info("Initialized already");
      return;
    }
    _hasInitialized = true;
    await EmbeddingsDB.instance.init();
    await _loadImageEmbeddings();
    Bus.instance.on<EmbeddingUpdatedEvent>().listen((event) {
      if (!_hasInitialized) return;
      _embeddingLoaderDebouncer.run(() async {
        await _loadImageEmbeddings();
      });
    });

    // ignore: unawaited_futures
    _loadTextModel().then((_) async {
      try {
        _logger.info("Getting text embedding");
        await _getTextEmbedding("warm up text encoder");
        _logger.info("Got text embedding");
      } catch (e) {
        _logger.severe("Failed to get text embedding", e);
      }
    });
  }

  Future<void> dispose() async {
    if (!_hasInitialized) return;
    _hasInitialized = false;
    await ClipTextEncoder.instance.release();
    _cachedImageEmbeddings.clear();
  }

  bool isMagicSearchEnabledAndReady() {
    return LocalSettings.instance.isFaceIndexingEnabled &&
        _textModelIsLoaded &&
        _cachedImageEmbeddings.isNotEmpty;
  }

  // searchScreenQuery should only be used for the user initiate query on the search screen.
  // If there are multiple call tho this method, then for all the calls, the result will be the same as the last query.
  Future<(String, List<EnteFile>)> searchScreenQuery(String query) async {
    if (!isMagicSearchEnabledAndReady()) {
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

  Future<IndexStatus> getIndexStatus() async {
    final indexableFileIDs = await getIndexableFileIDs();
    return IndexStatus(
      min(_cachedImageEmbeddings.length, indexableFileIDs.length),
      (await _getFileIDsToBeIndexed()).length,
    );
  }

  Future<void> clearIndexes() async {
    await EmbeddingsDB.instance.deleteAll();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("sync_time_embeddings_v3");
    _logger.info("Indexes cleared");
  }

  Future<void> _loadImageEmbeddings() async {
    _logger.info("Pulling cached embeddings");
    final startTime = DateTime.now();
    _cachedImageEmbeddings = await EmbeddingsDB.instance.getAll();
    final endTime = DateTime.now();
    _logger.info(
      "Loading ${_cachedImageEmbeddings.length} took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
    );
    Bus.instance.fire(EmbeddingCacheUpdatedEvent());
    _logger
        .info("Cached embeddings: " + _cachedImageEmbeddings.length.toString());
  }

  Future<List<int>> _getFileIDsToBeIndexed() async {
    final uploadedFileIDs = await getIndexableFileIDs();
    final embeddedFileIDs = await EmbeddingsDB.instance.getIndexedFileIds();
    embeddedFileIDs.removeWhere((key, value) => value < clipMlVersion);

    return uploadedFileIDs.difference(embeddedFileIDs.keys.toSet()).toList();
  }

  Future<List<EnteFile>> getMatchingFiles(
    String query, {
    double? scoreThreshold,
  }) async {
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

    final filesMap = await FilesDB.instance
        .getFilesFromIDs(queryResults.map((e) => e.id).toList());

    final ignoredCollections =
        CollectionsService.instance.getHiddenCollectionIds();

    final deletedEntries = <int>[];
    final results = <EnteFile>[];

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
      unawaited(EmbeddingsDB.instance.deleteEmbeddings(deletedEntries));
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
      unawaited(EmbeddingsDB.instance.deleteEmbeddings(deletedEntries));
    }

    final matchingFileIDs = <int>[];
    for (EnteFile file in results) {
      matchingFileIDs.add(file.uploadedFileID!);
    }

    return matchingFileIDs;
  }

  Future<void> _loadTextModel() async {
    _logger.info("Initializing ML framework");
    try {
      await ClipTextEncoder.instance
          .loadModel(useEntePlugin: Platform.isAndroid);
      _textModelIsLoaded = true;
    } catch (e, s) {
      _logger.severe("Clip text loading failed", e, s);
    }
    _logger.info("Clip text model loaded");
  }

  static Future<void> storeClipImageResult(
    ClipResult clipResult,
    EnteFile entefile,
  ) async {
    final embedding = ClipEmbedding(
      fileID: clipResult.fileID,
      embedding: clipResult.embedding,
      version: clipMlVersion,
    );
    await EmbeddingsDB.instance.put(embedding);
  }

  static Future<void> storeEmptyClipImageResult(EnteFile entefile) async {
    final embedding = ClipEmbedding.empty(entefile.uploadedFileID!);
    await EmbeddingsDB.instance.put(embedding);
  }

  Future<List<double>> _getTextEmbedding(String query) async {
    _logger.info("Searching for " + query);
    final cachedResult = _queryCache.get(query);
    if (cachedResult != null) {
      return cachedResult;
    }
    try {
      final int clipAddress = ClipTextEncoder.instance.sessionAddress;
      late final List<double> textEmbedding;
      if (Platform.isAndroid) {
        textEmbedding = await ClipTextEncoder.infer(
          {"text": query, "address": clipAddress},
        );
      } else {
        textEmbedding = await _computer.compute(
          ClipTextEncoder.infer,
          param: {
            "text": query,
            "address": clipAddress,
          },
        ) as List<double>;
      }

      _queryCache.put(query, textEmbedding);
      return textEmbedding;
    } catch (e) {
      _logger.severe("Could not get text embedding", e);
      return [];
    }
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
    int clipImageAddress, {
    bool useEntePlugin = false,
  }) async {
    final embedding = await ClipImageEncoder.predict(
      image,
      imageByteData,
      clipImageAddress,
      useEntePlugin: useEntePlugin,
    );

    final clipResult = ClipResult(fileID: enteFileID, embedding: embedding);

    return clipResult;
  }
}

List<QueryResult> computeBulkSimilarities(Map args) {
  final queryResults = <QueryResult>[];
  final imageEmbeddings = args["imageEmbeddings"] as List<ClipEmbedding>;
  final textEmbedding = args["textEmbedding"] as List<double>;
  final minimumSimilarity = args["minimumSimilarity"] ??
      SemanticSearchService.kMinimumSimilarityThreshold;
  for (final imageEmbedding in imageEmbeddings) {
    final score = computeCosineSimilarity(
      imageEmbedding.embedding,
      textEmbedding,
    );
    if (score >= minimumSimilarity) {
      queryResults.add(QueryResult(imageEmbedding.fileID, score));
    }
  }

  queryResults.sort((first, second) => second.score.compareTo(first.score));
  return queryResults;
}

class QueryResult {
  final int id;
  final double score;

  QueryResult(this.id, this.score);
}
