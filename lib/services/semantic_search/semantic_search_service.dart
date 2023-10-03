import "dart:async";
import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/semantic_search/embedding_store.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();
  static final Computer _computer = Computer.shared();

  static const int batchSize = 1;

  bool hasLoaded = false;
  final _logger = Logger("SemanticSearchService");
  Future<List<EnteFile>>? _ongoingRequest;
  PendingQuery? _nextQuery;

  Future<void> init(SharedPreferences preferences) async {
    await _loadModel();
    await EmbeddingStore.instance.init(preferences);
    Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (event.status == SyncStatus.diffSynced) {
        EmbeddingStore.instance.fetchEmbeddings();
      }
    });

    _computeMissingEmbeddings();
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
      queryResults.add(QueryResult(embedding.id, score));
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
        .getFilesFromGeneratedIDs(queryResults.map((e) => e.id).toList());
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

  Future<void> _loadModel() async {
    const modelPath =
        "assets/models/clip/openai_clip-vit-base-patch32.ggmlv0.f16.bin";

    final path = await _getAccessiblePathForAsset(modelPath, "model.bin");
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

  Future<void> _computeMissingEmbeddings() async {
    final files = await FilesDB.instance.getFilesWithoutEmbeddings();
    _logger.info(files.length.toString() + " pending to be embedded");
    int counter = 0;
    final List<EnteFile> batch = [];
    for (final file in files) {
      if (counter < batchSize) {
        batch.add(file);
        counter++;
      } else {
        await _computeImageEmbeddings(batch);
        counter = 0;
        batch.clear();
      }
    }
  }

  Future<void> _computeImageEmbeddings(List<EnteFile> files) async {
    if (!hasLoaded) {
      return;
    }
    final List<String> filePaths = [];

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
    for (int i = 0; i < imageEmbeddings.length; i++) {
      await FilesDB.instance.insertEmbedding(
        Embedding(
          files[i].generatedID!,
          imageEmbeddings[i],
          -1,
        ),
      );
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
