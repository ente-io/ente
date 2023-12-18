import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/semantic_search/frameworks/ml_framework.dart";
import "package:photos/services/semantic_search/frameworks/onnx/onnx_image_encoder.dart";
import "package:photos/services/semantic_search/frameworks/onnx/onnx_text_encoder.dart";

class ONNX extends MLFramework {
  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kImageModel = "clip-image-vit-32-float32.onnx";
  static const kTextModel = "clip-text-vit-32-uint8.onnx";

  final _computer = Computer.shared();
  final _logger = Logger("ONNX");
  final _clipImage = OnnxImageEncoder();
  final _clipText = OnnxTextEncoder();
  int _textEncoderAddress = 0;
  int _imageEncoderAddress = 0;

  @override
  String getFrameworkName() {
    return "onnx";
  }

  @override
  String getImageModelRemotePath() {
    return "";
  }

  @override
  String getTextModelRemotePath() {
    return kModelBucketEndpoint + kTextModel;
  }

  @override
  Future<void> loadImageModel(String path) async {
    final startTime = DateTime.now();
    _imageEncoderAddress = await _computer.compute(
      _clipImage.loadModel,
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
    await _clipText.init();
    _textEncoderAddress = await _computer.compute(
      _clipText.loadModel,
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
        _clipImage.inferByImage,
        param: {
          "imagePath": imagePath,
          "address": _imageEncoderAddress,
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
        _clipText.infer,
        param: {
          "text": text,
          "address": _textEncoderAddress,
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

  @override
  Future<void> release() async {
    final session = OrtSession.fromAddress(_textEncoderAddress);
    session.release();
    OrtEnv.instance.release();
    _logger.info('Released');
  }
}
