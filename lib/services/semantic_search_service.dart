import "dart:convert";
import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";

class SemanticSearchService {
  SemanticSearchService._privateConstructor();

  static final SemanticSearchService instance =
      SemanticSearchService._privateConstructor();

  late CLIP _clip;
  final _logger = Logger("SemanticSearchService");

  Future<void> init() async {
    _clip = CLIP();
    await _loadModel();
    _testJson();
  }

  Future<void> _loadModel() async {
    final clip = CLIP();
    const modelPath =
        "assets/models/clip/openai_clip-vit-base-patch32.ggmlv0.f16.bin";

    final path = await _getAccessiblePathForAsset(modelPath, "model.bin");
    final startTime = DateTime.now();
    clip.loadModel(path);
    final endTime = DateTime.now();
    _logger.info(
      "Loading model took: " +
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toString() +
          "ms",
    );

    _testJson();
  }

  Future<void> _testJson() async {
    final startTime = DateTime.now();
    final input = {
      "embedding": [1.1, 2.2],
    };
    _logger.info(jsonEncode(input));
    final result = _clip.createTextEmbedding("hello world");
    final endTime = DateTime.now();
    _logger.info(
      "Output: " +
          result +
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
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$tempName')
        .writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}
