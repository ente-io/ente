import "dart:typed_data" show Uint8List, Float32List;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

class ClipImageEncoder extends MlModel {
  static const kRemoteBucketModelPath = "mobileclip_s2_image.onnx";
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
    Dimensions dim,
    Uint8List rawRgbaBytes,
    int sessionAddress, [
    int? enteFileID,
  ]) async {
    final startTime = DateTime.now();
    final inputList = await preprocessImageClip(dim, rawRgbaBytes);
    final preprocessingTime = DateTime.now();
    final preprocessingMs =
        preprocessingTime.difference(startTime).inMilliseconds;
    late List<double> result;
    try {
      if (MlModel.usePlatformPlugin) {
        result = await _runPlatformPluginPredict(inputList);
      } else {
        result = _runFFIBasedPredict(inputList, sessionAddress);
      }
    } catch (e, stackTrace) {
      _logger.severe(
        "Clip image inference failed${enteFileID != null ? " with fileID $enteFileID" : ""}  (PlatformPlugin: ${MlModel.usePlatformPlugin})",
        e,
        stackTrace,
      );
      rethrow;
    }
    final inferTime = DateTime.now();
    final inferenceMs = inferTime.difference(preprocessingTime).inMilliseconds;
    final totalMs = inferTime.difference(startTime).inMilliseconds;
    _logger.info(
      "Clip image predict took $totalMs ms${enteFileID != null ? " with fileID $enteFileID" : ""} (inference: $inferenceMs ms, preprocessing: $preprocessingMs ms)",
    );
    return result;
  }

  static List<double> _runFFIBasedPredict(
    Float32List inputList,
    int sessionAddress,
  ) {
    final inputOrt =
        OrtValueTensor.createTensorWithDataList(inputList, [1, 3, 256, 256]);
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
    Float32List inputList,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predict(
      inputList,
      _modelName,
    );
    final List<double> embedding = result!.sublist(0, 512);
    normalizeEmbedding(embedding);
    return embedding;
  }
}
