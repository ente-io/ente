import "dart:async";
import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/embedding.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/thumbnail_util.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();
  static final Computer _computer = Computer.shared();

  bool hasLoaded = false;
  final _logger = Logger("SemanticSearchService");
  Future<List<EnteFile>>? _ongoingRequest;
  PendingQuery? _nextQuery;

  Future<void> init() async {
    await _loadModel();
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
        "assets/models/clip/openai_clip-vit-base-patch32.ggmlv0.q4_0.bin";

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
    for (final file in files) {
      await _computeImageEmbedding(file);
    }
  }

  Future<void> _computeImageEmbedding(EnteFile file) async {
    if (!hasLoaded) {
      return;
    }
    // _logger.info("Running clip");
    final imagePath = (await getThumbnailFile(file))!.path;

    final startTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    var imageEmbedding;
    final embeddings = await FilesDB.instance.getAllEmbeddings();
    bool hasCachedEmbedding = false;
    for (final embedding in embeddings) {
      if (embedding.id == file.generatedID) {
        imageEmbedding = embedding.embedding;
        hasCachedEmbedding = true;
        _logger.info("Found cached embedding");
      }
    }
    if (!hasCachedEmbedding) {
      imageEmbedding ??= await _computer.compute(
        createImageEmbedding,
        param: {
          "imagePath": imagePath,
        },
        taskName: "createImageEmbedding",
      );
      await FilesDB.instance
          .insertEmbedding(Embedding(file.generatedID!, imageEmbedding, -1));
    }
    final endTime = DateTime.now();
    _logger.info(
      "createImageEmbedding took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );
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
