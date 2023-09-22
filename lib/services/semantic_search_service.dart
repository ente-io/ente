import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();

  bool hasLoaded = false;
  final _logger = Logger("SemanticSearchService");

  Future<void> init() async {
    await _loadModel();
    _testJson();
  }

  Future<void> runInference(Uint8List image, String text) async {
    if (!hasLoaded) {
      return;
    }
    final imagePath = await _writeToFile(image, "input.jpg");
    final imageEmbedding = CLIP.createImageEmbedding(imagePath);
    final textEmbedding = CLIP.createTextEmbedding(text);
    final score = CLIP.computeScore(imageEmbedding, textEmbedding);
    _logger.info("Score: " + score.toString());
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

    _testJson();
  }

  Future<void> _testJson() async {
    final startTime = DateTime.now();
    final result = CLIP.createTextEmbedding("hello world");
    final endTime = DateTime.now();
    _logger.info(
      "Output: " +
          result.toString() +
          " (" +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms)",
    );
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
    final file = await File('${tempDir.path}/$fileName')
        .writeAsBytes(bytes);
    return file.path;
  }
}
