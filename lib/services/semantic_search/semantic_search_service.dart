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
import "package:photos/events/file_indexed_event.dart";
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/events/sync_status_update_event.dart";
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
    _cacheEmbeddings();
    Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (event.status == SyncStatus.diffSynced) {
        await EmbeddingStore.instance.pullEmbeddings();
        _cacheEmbeddings();
      }
    });
    if (Configuration.instance.hasConfiguredAccount()) {
      EmbeddingStore.instance.pushEmbeddings();
    }

    _loadModels().then((v) {
      startBackFill();
      _getTextEmbedding("warm up text encoder");
    });
    Bus.instance.on<FileUploadedEvent>().listen((event) async {
      addToQueue(event.file);
    });
  }

  Future<List<EnteFile>> search(String query) async {
    if (Platform.isIOS) {
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

  void addToQueue(EnteFile file) {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return;
    }
    _logger.info("Adding " + file.toString() + " to the queue");
    _queue.add(file);
    _pollQueue();
  }

  Future<IndexStatus> getIndexStatus() async {
    final embeddings = ObjectBox.instance.getEmbeddingBox().getAll();
    return IndexStatus(embeddings.length, _queue.length);
  }

  Future<void> _loadModels() async {
    await ModelLoader.instance.loadImageModel();
    await ModelLoader.instance.loadTextModel();
    hasLoaded = true;
  }

  Future<void> startBackFill() async {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return;
    }
    final uploadedFileIDs = await FilesDB.instance
        .getOwnedFileIDs(Configuration.instance.getUserID()!);
    final embeddedFileIDs = _cachedEmbeddings.map((e) => e.fileID).toSet();
    uploadedFileIDs.removeWhere((id) => embeddedFileIDs.contains(id));
    final files = await FilesDB.instance.getUploadedFiles(uploadedFileIDs);
    _logger.info(files.length.toString() + " pending to be embedded");
    _queue.addAll(files);
    _pollQueue();
  }

  Future<void> clearQueue() async {
    _queue.clear();
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

      Bus.instance.fire(FileIndexedEvent());
      _cachedEmbeddings.add(embedding);
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

  Future<void> _cacheEmbeddings() async {
    final startTime = DateTime.now();
    final embeddings = ObjectBox.instance.store.box<Embedding>().getAll();
    _cachedEmbeddings.clear();
    _cachedEmbeddings.addAll(embeddings);
    final endTime = DateTime.now();
    _logger.info(
      "Loading ${embeddings.length} embeddings took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
    );
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
