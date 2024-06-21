import "dart:io" show File;
import 'dart:math' as math show sqrt;
import 'dart:typed_data' show Float32List;

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/services/remote_assets_service.dart";

class MobileFaceNetInterpreterRunException implements Exception {}

/// This class is responsible for running the face embedding model (MobileFaceNet) on ONNX runtime, and can be accessed through the singleton instance [FaceEmbeddingService.instance].
class FaceEmbeddingService {
  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kRemoteBucketModelPath = "mobilefacenet_opset15.onnx";
  static const modelRemotePath = kModelBucketEndpoint + kRemoteBucketModelPath;

  static const int kInputSize = 112;
  static const int kEmbeddingSize = 192;
  static const int kNumChannels = 3;
  static const bool kPreWhiten = false;

  static final _logger = Logger('FaceEmbeddingService');

  bool isInitialized = false;
  int sessionAddress = 0;

  final _computer = Computer.shared();

  // Singleton pattern
  FaceEmbeddingService._privateConstructor();
  static final instance = FaceEmbeddingService._privateConstructor();
  factory FaceEmbeddingService() => instance;

  /// Check if the interpreter is initialized, if not initialize it with `loadModel()`
  Future<void> init() async {
    if (!isInitialized) {
      _logger.info('init is called');
      final model =
          await RemoteAssetsService.instance.getAsset(modelRemotePath);
      final startTime = DateTime.now();
      // Doing this from main isolate since `rootBundle` cannot be accessed outside it
      sessionAddress = await _computer.compute(
        _loadModel,
        param: {
          "modelPath": model.path,
        },
      );
      final endTime = DateTime.now();
      _logger.info(
        "Face embedding model loaded, took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
      );
      if (sessionAddress != -1) {
        isInitialized = true;
      }
    }
  }

  Future<void> release() async {
    if (isInitialized) {
      await _computer
          .compute(_releaseModel, param: {'address': sessionAddress});
      isInitialized = false;
      sessionAddress = 0;
    }
  }

  static Future<int> _loadModel(Map args) async {
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      final session =
          OrtSession.fromFile(File(args["modelPath"]), sessionOptions);
      return session.address;
    } catch (e, s) {
      _logger.severe('Face embedding model not loaded', e, s);
    }
    return -1;
  }

  static Future<void> _releaseModel(Map args) async {
    final address = args['address'] as int;
    if (address == 0) {
      return;
    }
    final session = OrtSession.fromAddress(address);
    session.release();
    return;
  }

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
