import 'dart:math' as math show sqrt;
import 'dart:typed_data' show Float32List;

import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/services/machine_learning/ml_model.dart";

class MobileFaceNetInterpreterRunException implements Exception {}

/// This class is responsible for running the face embedding model (MobileFaceNet) on ONNX runtime, and can be accessed through the singleton instance [FaceEmbeddingService.instance].
class FaceEmbeddingService extends MlModel {
  static const kRemoteBucketModelPath = "mobilefacenet_opset15.onnx";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('FaceEmbeddingService');

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
    assert(sessionAddress != 0 && sessionAddress != -1);
    try {
      final stopwatch = Stopwatch()..start();
      _logger.info('MobileFaceNet interpreter.run is called');
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
        double normalization = 0;
        for (int i = 0; i < kEmbeddingSize; i++) {
          normalization += embedding[i] * embedding[i];
        }
        final double sqrtNormalization = math.sqrt(normalization);
        for (int i = 0; i < kEmbeddingSize; i++) {
          embedding[i] = embedding[i] / sqrtNormalization;
        }
      }
      stopwatch.stop();
      _logger.info(
        'MobileFaceNet interpreter.run is finished, in ${stopwatch.elapsedMilliseconds}ms',
      );

      return embeddings;
    } catch (e) {
      _logger.info('MobileFaceNet Error while running inference: $e');
      throw MobileFaceNetInterpreterRunException();
    }
  }
}
