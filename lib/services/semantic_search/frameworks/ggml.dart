import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:logging/logging.dart";
import 'package:photos/services/semantic_search/frameworks/ml_framework.dart';

class GGML extends MLFramework {
  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kImageModel = "clip-vit-base-patch32_ggml-vision-model-f16.gguf";
  static const kTextModel = "clip-vit-base-patch32_ggml-text-model-f16.gguf";

  final _computer = Computer.shared();
  final _logger = Logger("GGML");
  
  @override
  String getFrameworkName() {
    return "ggml";
  }

  @override
  String getImageModelRemotePath() {
    return kModelBucketEndpoint + kImageModel;
  }

  @override
  String getTextModelRemotePath() {
    return kModelBucketEndpoint + kTextModel;
  }

  @override
  Future<void> loadImageModel(String path) async {
    final startTime = DateTime.now();
    await _computer.compute(
      loadModel,
      param: {
        "imageModelPath": path,
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading image model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  @override
  Future<void> loadTextModel(String path) async {
    final startTime = DateTime.now();
    await _computer.compute(
      loadModel,
      param: {
        "textModelPath": path,
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading text model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  @override
  Future<List<double>> getImageEmbedding(String imagePath) async {
    try {
      final startTime = DateTime.now();
      final result = await _computer.compute(
        _createImageEmbedding,
        param: {
          "imagePath": imagePath,
        },
        taskName: "createImageEmbedding",
      ) as List<double>;
      final endTime = DateTime.now();
      _logger.info(
        "createImageEmbedding took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      return result;
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  @override
  Future<List<double>> getTextEmbedding(String text) async {
    try {
      final startTime = DateTime.now();
      final result = await _computer.compute(
        _createTextEmbedding,
        param: {
          "text": text,
        },
        taskName: "createTextEmbedding",
      ) as List<double>;
      final endTime = DateTime.now();
      _logger.info(
        "createTextEmbedding took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      return result;
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}

void loadModel(Map args) {
  if (args["imageModelPath"] != null) {
    CLIP.loadImageModel(args["imageModelPath"]);
  } else if (args["textModelPath"] != null) {
    CLIP.loadTextModel(args["textModelPath"]);
  }
}

List<double> _createImageEmbedding(Map args) {
  return CLIP.createImageEmbedding(args["imagePath"]);
}

List<double> _createTextEmbedding(Map args) {
  return CLIP.createTextEmbedding(args["text"]);
}
