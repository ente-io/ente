import 'dart:typed_data' show Float32List;

import 'package:logging/logging.dart';
import "package:onnx_dart/onnx_dart.dart";
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/ml_util.dart";

class MobileFaceNetInterpreterRunException implements Exception {}

/// This class is responsible for running the face embedding model (MobileFaceNet) on ONNX runtime, and can be accessed through the singleton instance [FaceEmbeddingService.instance].
class FaceEmbeddingService extends MlModel {
  static const kRemoteBucketModelPath = "mobilefacenet_opset15.onnx";
  static const String _modelName = "MobileFaceNet";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('FaceEmbeddingService');

  @override
  String get modelName => _modelName;

  static const int kInputSize = 112;
  static const int kEmbeddingSize = 192;
  static const int kNumChannels = 3;
  static const bool kPreWhiten = false;

  // Singleton pattern
  FaceEmbeddingService._privateConstructor();
  static final instance = FaceEmbeddingService._privateConstructor();
  factory FaceEmbeddingService() => instance;

  static Future<List<List<double>>> predict(
    Float32List input,
    int sessionAddress,
  ) async {
    if (!MlModel.usePlatformPlugin) {
      assert(sessionAddress != 0 && sessionAddress != -1);
    }
    try {
      if (MlModel.usePlatformPlugin) {
        return await _runPlatformPluginPredict(input);
      } else {
        return _runFFIBasedPredict(input, sessionAddress);
      }
    } catch (e, s) {
      _logger.severe(
        'Error while running inference (PlatformPlugin: ${MlModel.usePlatformPlugin})',
        e,
        s,
      );
      throw MobileFaceNetInterpreterRunException();
    }
  }

  static List<List<double>> _runFFIBasedPredict(
    Float32List input,
    int sessionAddress,
  ) {
    final runOptions = OrtRunOptions();
    final int numberOfFaces = input.length ~/ (kInputSize * kInputSize * 3);
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      input,
      [numberOfFaces, kInputSize, kInputSize, kNumChannels],
    );
    final inputs = {'img_inputs': inputOrt};
    final session = OrtSession.fromAddress(sessionAddress);
    final List<OrtValue?> outputs = session.run(runOptions, inputs);
    final embeddings = outputs[0]?.value as List<List<double>>;

    for (final embedding in embeddings) {
      normalizeEmbedding(embedding);
    }
    inputOrt.release();
    runOptions.release();
    for (var element in outputs) {
      element?.release();
    }

    return embeddings;
  }

  static Future<List<List<double>>> _runPlatformPluginPredict(
    Float32List inputImageList,
  ) async {
    final stopwatch = Stopwatch()..start();
    final OnnxDart plugin = OnnxDart();
    final int numberOfFaces =
        inputImageList.length ~/ (kInputSize * kInputSize * 3);
    final result = await plugin.predict(
      inputImageList,
      _modelName,
    );
    final List<List<double>> embeddings = [];
    for (int i = 0; i < numberOfFaces; i++) {
      embeddings
          .add(result!.sublist(i * kEmbeddingSize, (i + 1) * kEmbeddingSize));
    }
    for (final embedding in embeddings) {
      normalizeEmbedding(embedding);
    }
    _logger.info(
      'MobileFaceNetPlatformPlugin interpreter.run is finished, in ${stopwatch.elapsedMilliseconds}ms',
    );
    return embeddings;
  }
}
