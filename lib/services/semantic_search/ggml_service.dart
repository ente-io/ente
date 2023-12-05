import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/services/semantic_search/embedding_service.dart";

class GGMLService extends EmbeddingService {
  final _computer = Computer.shared();
  final _logger = Logger("GGMLService");

  @override
  Future<void> init() async {
    
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

List<double> _createImageEmbedding(Map args) {
  return CLIP.createImageEmbedding(args["imagePath"]);
}

List<double> _createTextEmbedding(Map args) {
  return CLIP.createTextEmbedding(args["text"]);
}
