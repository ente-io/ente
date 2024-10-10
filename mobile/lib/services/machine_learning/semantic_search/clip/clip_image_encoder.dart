import "dart:typed_data" show Int32List, Uint8List;
import "dart:ui" show Image;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/ml_util.dart";

class ClipImageEncoder extends MlModel {
  static const kRemoteBucketModelPath =
      "mobileclip_s2_image_opset18_rgba_opt.onnx"; // FP32 model
  // static const kRemoteBucketModelPath =
  //     "mobileclip_s2_image_opset18_fp16.onnx"; // FP16 model
  static const _modelName = "ClipImageEncoder";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('ClipImageEncoder');

  @override
  String get modelName => _modelName;

  // Singleton pattern
  ClipImageEncoder._privateConstructor();
  static final instance = ClipImageEncoder._privateConstructor();
  factory ClipImageEncoder() => instance;

  static Future<List<double>> predict(
    Image image,
    Uint8List rawRgbaBytes,
    int sessionAddress, [
    int? enteFileID,
  ]) async {
    final startTime = DateTime.now();
    final inputShape = <int>[image.height, image.width, 4]; // [H, W, C]
    late List<double> result;
    try {
      if (MlModel.usePlatformPlugin) {
        result = await _runPlatformPluginPredict(rawRgbaBytes, inputShape);
      } else {
        result = _runFFIBasedPredict(rawRgbaBytes, inputShape, sessionAddress);
      }
    } catch (e, stackTrace) {
      _logger.severe(
        "Clip image inference failed${enteFileID != null ? " with fileID $enteFileID" : ""}  (PlatformPlugin: ${MlModel.usePlatformPlugin})",
        e,
        stackTrace,
      );
      rethrow;
    }
    final totalMs = DateTime.now().difference(startTime).inMilliseconds;
    _logger.info(
      "Clip image predict took $totalMs ms${enteFileID != null ? " with fileID $enteFileID" : ""}",
    );
    return result;
  }

  static List<double> _runFFIBasedPredict(
    Uint8List inputImageList,
    List<int> inputImageShape,
    int sessionAddress,
  ) {
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      inputImageShape,
    );
    final inputs = {'input': inputOrt};
    final session = OrtSession.fromAddress(sessionAddress);
    final runOptions = OrtRunOptions();
    final outputs = session.run(runOptions, inputs);
    final embedding = (outputs[0]?.value as List<List<double>>)[0];
    inputOrt.release();
    runOptions.release();
    for (var element in outputs) {
      element?.release();
    }
    normalizeEmbedding(embedding);
    return embedding;
  }

  static Future<List<double>> _runPlatformPluginPredict(
    Uint8List inputImageList,
    List<int> inputImageShape,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predictRgba(
      inputImageList,
      Int32List.fromList(inputImageShape),
      _modelName,
    );
    final List<double> embedding = result!.sublist(0, 512);
    normalizeEmbedding(embedding);
    return embedding;
  }
}
