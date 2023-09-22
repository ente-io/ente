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
  bool isRunning = false;
  final _logger = Logger("SemanticSearchService");

  Future<void> init() async {
    await _loadModel();
  }

  Future<void> runInference(EnteFile file, String text) async {
    if (!hasLoaded || isRunning) {
      return;
    }
    isRunning = true;
    _logger.info("Running clip");
    final imagePath = (await getThumbnailFile(file))!.path;

    var startTime = DateTime.now();
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
    var endTime = DateTime.now();
    _logger.info(
      "createImageEmbedding took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    startTime = DateTime.now();
    final textEmbedding = await _computer.compute(
      createTextEmbedding,
      param: {
        "text": text,
      },
      taskName: "createTextEmbedding",
    );
    endTime = DateTime.now();
    _logger.info(
      "createTextEmbedding took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    startTime = DateTime.now();
    // final score = await _computer.compute(
    //   computeScore,
    //   param: {
    //     "imageEmbedding": imageEmbedding,
    //     "textEmbedding": textEmbedding,
    //   },
    //   taskName: "computeScore",
    // );
    final score = computeScore({
      "imageEmbedding": imageEmbedding,
      "textEmbedding": textEmbedding,
    });
    endTime = DateTime.now();
    _logger.info(
      "computeScore took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    _logger.info("Score: " + score.toString());
    isRunning = false;
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
