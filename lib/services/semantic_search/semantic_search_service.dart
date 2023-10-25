import "dart:async";
import "dart:collection";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
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

  final _logger = Logger("SemanticSearchService");
  final _queue = Queue<EnteFile>();

  bool hasLoaded = false;
  bool isComputingEmbeddings = false;
  Future<List<EnteFile>>? _ongoingRequest;
  PendingQuery? _nextQuery;

  Future<void> init(SharedPreferences preferences) async {
    await EmbeddingStore.instance.init(preferences);
    await ModelLoader.instance.init(_computer);
    Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (event.status == SyncStatus.diffSynced) {
        await EmbeddingStore.instance.pullEmbeddings();
      }
    });
    if (Configuration.instance.hasConfiguredAccount()) {
      EmbeddingStore.instance.pushEmbeddings();
    }
    _loadModels().then((v) {
      startBackFill();
    });
    Bus.instance.on<FileUploadedEvent>().listen((event) async {
      addToQueue(event.file);
    });
  }

  Future<List<EnteFile>> search(String query) async {
    if (_ongoingRequest == null) {
      _ongoingRequest = getMatchingFiles(query).then((result) {
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

  Future<List<EnteFile>> getMatchingFiles(String query) async {
    _logger.info("Searching for " + query);
    var startTime = DateTime.now();
    final textEmbedding = await _computer.compute(
      createTextEmbedding,
      param: {
        "text": query,
      },
      taskName: "createTextEmbedding",
    );
    var endTime = DateTime.now();
    _logger.info(
      "createTextEmbedding took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    startTime = DateTime.now();
    final embeddings = await FilesDB.instance.getAllEmbeddings();
    endTime = DateTime.now();
    _logger.info(
      "Fetching embeddings took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    startTime = DateTime.now();
    final queryResults = <QueryResult>[];
    for (final embedding in embeddings) {
      final score = computeScore({
        "imageEmbedding": embedding.embedding,
        "textEmbedding": textEmbedding,
      });
      queryResults.add(QueryResult(embedding.fileID, score));
    }
    queryResults.sort((first, second) => second.score.compareTo(first.score));
    queryResults.removeWhere((element) => element.score < 0.25);
    endTime = DateTime.now();
    _logger.info(
      "computingScores took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    startTime = DateTime.now();
    final filesMap = await FilesDB.instance
        .getFilesFromIDs(queryResults.map((e) => e.id).toList());
    final results = <EnteFile>[];
    for (final result in queryResults) {
      if (filesMap.containsKey(result.id)) {
        results.add(filesMap[result.id]!);
      }
    }
    endTime = DateTime.now();
    _logger.info(
      "Fetching files took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

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
    final embeddings = await FilesDB.instance.getAllEmbeddings();
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
    final files = await FilesDB.instance.getFilesWithoutEmbeddings();
    final ownerID = Configuration.instance.getUserID();
    files.removeWhere((f) => f.ownerID != ownerID);
    _logger.info(files.length.toString() + " pending to be embedded");
    _queue.addAll(files);
    _pollQueue();
  }

  Future<void> _pollQueue() async {
    if (isComputingEmbeddings) {
      return;
    }
    isComputingEmbeddings = true;

    while (_queue.isNotEmpty) {
      await _computeImageEmbedding(_queue.removeFirst());
    }

    isComputingEmbeddings = false;
  }

  Future<void> _computeImageEmbedding(EnteFile file) async {
    if (!hasLoaded) {
      return;
    }
    try {
      final filePath = (await getThumbnailFile(file))!.path;
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
      await EmbeddingStore.instance.storeEmbedding(
        file,
        Embedding(
          file.uploadedFileID!,
          kModelName,
          result,
        ),
      );

      Bus.instance.fire(FileIndexedEvent());
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }
}

List<double> createImageEmbedding(Map args) {
  return CLIP.createImageEmbedding(args["imagePath"]);
}

List<double> createTextEmbedding(Map args) {
  return CLIP.createTextEmbedding(args["text"]);
}

double computeScore(Map args) {
  return CLIP.computeScore(
    args["imageEmbedding"] as List<double>,
    args["textEmbedding"] as List<double>,
  );
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
