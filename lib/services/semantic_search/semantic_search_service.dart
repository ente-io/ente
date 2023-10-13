import "dart:async";
import "dart:collection";
import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/file_indexed_event.dart";
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/semantic_search/embedding_store.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();
  static final Computer _computer = Computer.shared();

  static const int batchSize = 1;
  static const kModelPath =
      "assets/models/clip/openai_clip-vit-base-patch32.ggmlv0.f16.bin";

  final _logger = Logger("SemanticSearchService");
  final _queue = Queue<EnteFile>();

  bool hasLoaded = false;
  bool isComputingEmbeddings = false;
  Future<List<EnteFile>>? _ongoingRequest;
  PendingQuery? _nextQuery;

  Future<void> init(SharedPreferences preferences) async {
    await _loadModel();
    await EmbeddingStore.instance.init(preferences);
    startBackFill();

    await EmbeddingStore.instance.pushEmbeddings();
    Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (event.status == SyncStatus.diffSynced) {
        await EmbeddingStore.instance.pullEmbeddings();
      }
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

  Future<void> _loadModel() async {
    final path = await _getAccessiblePathForAsset(kModelPath, "model.bin");
    final startTime = DateTime.now();
    CLIP.loadModel(path);
    final endTime = DateTime.now();
    _logger.info(
      "Loading model took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
    hasLoaded = true;
  }

  Future<String> _getAccessiblePathForAsset(
    String assetPath,
    String tempName,
  ) async {
    final byteData = await rootBundle.load(assetPath);
    return _writeToFile(byteData.buffer.asUint8List(), tempName);
  }

  Future<String> _writeToFile(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$fileName').writeAsBytes(bytes);
    return file.path;
  }

  Future<void> startBackFill() async {
    if (!LocalSettings.instance.hasEnabledMagicSearch()) {
      return;
    }
    final files = await FilesDB.instance.getFilesWithoutEmbeddings();
    _logger.info(files.length.toString() + " pending to be embedded");
    _queue.addAll(files);
    _pollQueue();
  }

  Future<void> _pollQueue() async {
    if (isComputingEmbeddings) {
      return;
    }
    isComputingEmbeddings = true;

    final List<EnteFile> batch = [];
    while (_queue.isNotEmpty) {
      if (batch.length < batchSize) {
        batch.add(_queue.removeFirst());
      } else {
        await _computeImageEmbeddings(batch);
        batch.clear();
      }
    }
    await _computeImageEmbeddings(batch);

    isComputingEmbeddings = false;
  }

  Future<void> _computeImageEmbeddings(List<EnteFile> files) async {
    if (!hasLoaded || files.isEmpty) {
      return;
    }
    final List<String> filePaths = [];
    try {
      for (final file in files) {
        filePaths.add((await getThumbnailFile(file))!.path);
      }
      _logger.info("Running clip over " + files.length.toString() + " items");
      final startTime = DateTime.now();
      final List<List<double>> imageEmbeddings = [];
      if (filePaths.length == 1) {
        final result = await _computer.compute(
          createImageEmbedding,
          param: {
            "imagePath": filePaths.first,
          },
          taskName: "createImageEmbedding",
        ) as List<double>;
        imageEmbeddings.add(result);
      } else {
        final result = await _computer.compute(
          createImageEmbeddings,
          param: {
            "imagePaths": filePaths,
          },
          taskName: "createImageEmbeddings",
        ) as List<List<double>>;
        imageEmbeddings.addAll(result);
      }
      final endTime = DateTime.now();
      _logger.info(
        "createImageEmbeddings took: " +
            (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
                .toString() +
            "ms for " +
            imageEmbeddings.length.toString() +
            " items",
      );
      for (int i = 0; i < imageEmbeddings.length; i++) {
        await EmbeddingStore.instance.storeEmbedding(
          files[i],
          Embedding(
            files[i].uploadedFileID!,
            "c_uq",
            imageEmbeddings[i],
          ),
        );
      }

      Bus.instance.fire(FileIndexedEvent());
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }
}

List<List<double>> createImageEmbeddings(Map args) {
  return CLIP.createBatchImageEmbedding(args["imagePaths"]);
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
