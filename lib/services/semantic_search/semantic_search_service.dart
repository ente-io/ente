import "dart:async";
import "dart:collection";
import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/object_box.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/semantic_search/embedding_store.dart";
import "package:photos/services/semantic_search/model_loader.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();
  static final Computer _computer = Computer.shared();

  static const kModelName = "ggml-clip";
  static const kEmbeddingLength = 512;
  static const kScoreThreshold = 0.23;

  final _logger = Logger("SemanticSearchService");
  final _queue = Queue<EnteFile>();

  bool hasLoaded = false;
  bool isComputingEmbeddings = false;
  Future<List<EnteFile>>? _ongoingRequest;
  PendingQuery? _nextQuery;
  final _cachedEmbeddings = <Embedding>[];

  Future<void> init(SharedPreferences preferences) async {
    if (Platform.isIOS) {
      return;
    }
    await EmbeddingStore.instance.init(preferences);
    await ModelLoader.instance.init(_computer);
    _setupCachedEmbeddings();
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      // Diff sync is complete, we can now pull embeddings from remote
      sync();
    });
    if (Configuration.instance.hasConfiguredAccount()) {
      EmbeddingStore.instance.pushEmbeddings();
    }

    _loadModels().then((v) {
      _getTextEmbedding("warm up text encoder");
    });
    Bus.instance.on<FileUploadedEvent>().listen((event) async {
      _addToQueue(event.file);
    });
  }

  Future<void> sync() async {
    await EmbeddingStore.instance.pullEmbeddings();
    _backFill();
  }

  Future<List<EnteFile>> search(String query) async {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return [];
    }
    if (_ongoingRequest == null) {
      _ongoingRequest = _getMatchingFiles(query).then((result) {
        _ongoingRequest = null;
        if (_nextQuery != null) {
          final next = _nextQuery;
          _nextQuery = null;
          search(next!.query).then((nextResult) {
            next.completer.complete(nextResult);
          });
        }

        return result;
      });
      return _ongoingRequest!;
    } else {
      // If there's an ongoing request, create or replace the nextCompleter.
      _nextQuery?.completer.future
          .timeout(const Duration(seconds: 0)); // Cancels the previous future.
      _nextQuery = PendingQuery(query, Completer<List<EnteFile>>());
      return _nextQuery!.completer.future;
    }
  }

  Future<IndexStatus> getIndexStatus() async {
    return IndexStatus(
      _cachedEmbeddings.length,
      (await _getFileIDsToBeIndexed()).length,
    );
  }

  void _setupCachedEmbeddings() {
    ObjectBox.instance
        .getEmbeddingBox()
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find())
        .listen((embeddings) {
      _logger.info("Updated embeddings: " + embeddings.length.toString());
      _cachedEmbeddings.clear();
      _cachedEmbeddings.addAll(embeddings);
      Bus.instance.fire(EmbeddingUpdatedEvent());
    });
  }

  Future<void> _backFill() async {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return;
    }
    _logger.info("Attempting backfill");
    final fileIDs = await _getFileIDsToBeIndexed();
    final files = await FilesDB.instance.getUploadedFiles(fileIDs);
    _logger.info(files.length.toString() + " to be embedded");
    _queue.addAll(files);
    _pollQueue();
  }

  Future<List<int>> _getFileIDsToBeIndexed() async {
    final uploadedFileIDs = await FilesDB.instance
        .getOwnedFileIDs(Configuration.instance.getUserID()!);
    final embeddedFileIDs = _cachedEmbeddings.map((e) => e.fileID).toSet();
    final queuedFileIDs = _queue.map((e) => e.uploadedFileID).toSet();
    uploadedFileIDs.removeWhere(
      (id) => embeddedFileIDs.contains(id) || queuedFileIDs.contains(id),
    );
    return uploadedFileIDs;
  }

  Future<void> clearQueue() async {
    _queue.clear();
  }

  Future<List<EnteFile>> _getMatchingFiles(String query) async {
    final textEmbedding = await _getTextEmbedding(query);

    final queryResults = await _getScores(textEmbedding);

    final filesMap = await FilesDB.instance
        .getFilesFromIDs(queryResults.map((e) => e.id).toList());
    final results = <EnteFile>[];
    for (final result in queryResults) {
      if (filesMap.containsKey(result.id)) {
        results.add(filesMap[result.id]!);
      }
    }

    _logger.info(results.length.toString() + " results");

    return results;
  }

  void _addToQueue(EnteFile file) {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return;
    }
    _logger.info("Adding " + file.toString() + " to the queue");
    _queue.add(file);
    _pollQueue();
  }

  Future<void> _loadModels() async {
    await ModelLoader.instance.loadImageModel();
    await ModelLoader.instance.loadTextModel();
    hasLoaded = true;
  }

  Future<void> _pollQueue() async {
    if (isComputingEmbeddings) {
      return;
    }
    isComputingEmbeddings = true;

    while (_queue.isNotEmpty) {
      await _computeImageEmbedding(_queue.removeLast());
    }

    isComputingEmbeddings = false;
  }

  Future<void> _computeImageEmbedding(EnteFile file) async {
    if (!hasLoaded) {
      return;
    }
    try {
      final filePath = (await getThumbnailForUploadedFile(file))!.path;
      _logger.info("Running clip over $file");
      final startTime = DateTime.now();
      final result = await _computer.compute(
        createImageEmbedding,
        param: {
          "imagePath": filePath,
        },
        taskName: "createImageEmbedding",
      ) as List<double>;
      final endTime = DateTime.now();
      _logger.info(
        "createImageEmbedding took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      if (result.length != kEmbeddingLength) {
        _logger.severe("Discovered incorrect embedding for $file - $result");
        return;
      }
      final embedding = Embedding(
        fileID: file.uploadedFileID!,
        model: kModelName,
        embedding: result,
      );
      await EmbeddingStore.instance.storeEmbedding(
        file,
        embedding,
      );
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }

  Future<List<double>> _getTextEmbedding(String query) async {
    _logger.info("Searching for " + query);
    final startTime = DateTime.now();
    final embedding = await _computer.compute(
      createTextEmbedding,
      param: {
        "text": query,
      },
      taskName: "createTextEmbedding",
    );
    final endTime = DateTime.now();
    _logger.info(
      "createTextEmbedding took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    return embedding;
  }

  Future<List<QueryResult>> _getScores(List<double> textEmbedding) async {
    final startTime = DateTime.now();
    final List<QueryResult> queryResults = await _computer.compute(
      computeBulkScore,
      param: {
        "imageEmbeddings": _cachedEmbeddings,
        "textEmbedding": textEmbedding,
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
}

List<double> createImageEmbedding(Map args) {
  return CLIP.createImageEmbedding(args["imagePath"]);
}

List<double> createTextEmbedding(Map args) {
  return CLIP.createTextEmbedding(args["text"]);
}

List<QueryResult> computeBulkScore(Map args) {
  final queryResults = <QueryResult>[];
  final imageEmbeddings = args["imageEmbeddings"] as List<Embedding>;
  final textEmbedding = args["textEmbedding"] as List<double>;
  for (final imageEmbedding in imageEmbeddings) {
    final score = CLIP.computeScore(
      imageEmbedding.embedding,
      textEmbedding,
    );
    if (score >= SemanticSearchService.kScoreThreshold) {
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

class PendingQuery {
  final String query;
  final Completer<List<EnteFile>> completer;

  PendingQuery(this.query, this.completer);
}

class IndexStatus {
  final int indexedItems, pendingItems;

  IndexStatus(this.indexedItems, this.pendingItems);
}
