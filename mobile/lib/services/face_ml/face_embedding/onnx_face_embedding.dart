import "dart:io" show File;
import 'dart:math' as math show max, min, sqrt;
import 'dart:typed_data' show Float32List;

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import "package:photos/services/face_ml/face_detection/detection.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/image_ml_isolate.dart";
import "package:synchronized/synchronized.dart";

class FaceEmbeddingOnnx {
  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kRemoteBucketModelPath = "mobilefacenet_opset15.onnx";
  static const modelRemotePath = kModelBucketEndpoint + kRemoteBucketModelPath;

  static const int kInputSize = 112;
  static const int kEmbeddingSize = 192;

  static final _logger = Logger('FaceEmbeddingOnnx');

  bool isInitialized = false;
  int sessionAddress = 0;

  final _computer = Computer.shared();

  final _computerLock = Lock();

  // singleton pattern
  FaceEmbeddingOnnx._privateConstructor();

  /// Use this instance to access the FaceEmbedding service. Make sure to call `init()` before using it.
  /// e.g. `await FaceEmbedding.instance.init();`
  ///
  /// Then you can use `predict()` to get the embedding of a face, so `FaceEmbedding.instance.predict(imageData)`
  ///
  /// config options: faceEmbeddingEnte
  static final instance = FaceEmbeddingOnnx._privateConstructor();
  factory FaceEmbeddingOnnx() => instance;

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
      await _computer.compute(_releaseModel, param: {'address': sessionAddress});
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
      // _logger.info('Loading face embedding model');
      final session =
          OrtSession.fromFile(File(args["modelPath"]), sessionOptions);
      // _logger.info('Face embedding model loaded');
      return session.address;
    } catch (e, _) {
      // _logger.severe('Face embedding model not loaded', e, s);
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

  Future<(List<double>, bool, double)> predictFromImageDataInComputer(
    String imagePath,
    FaceDetectionRelative face,
  ) async {
    assert(sessionAddress != 0 && sessionAddress != -1 && isInitialized);

    try {
      final stopwatchDecoding = Stopwatch()..start();
      final (inputImageList, alignmentResults, isBlur, blurValue, _) =
          await ImageMlIsolate.instance.preprocessMobileFaceNetOnnx(
        imagePath,
        [face],
      );
      stopwatchDecoding.stop();
      _logger.info(
        'MobileFaceNet image decoding and preprocessing is finished, in ${stopwatchDecoding.elapsedMilliseconds}ms',
      );

      final stopwatch = Stopwatch()..start();
      _logger.info('MobileFaceNet interpreter.run is called');
      final embedding = await _computer.compute(
        inferFromMap,
        param: {
          'input': inputImageList,
          'address': sessionAddress,
          'inputSize': kInputSize,
        },
        taskName: 'createFaceEmbedding',
      ) as List<double>;
      stopwatch.stop();
      _logger.info(
        'MobileFaceNet interpreter.run is finished, in ${stopwatch.elapsedMilliseconds}ms',
      );

      _logger.info(
        'MobileFaceNet results (only first few numbers): embedding ${embedding.sublist(0, 5)}',
      );
      _logger.info(
        'Mean of embedding: ${embedding.reduce((a, b) => a + b) / embedding.length}',
      );
      _logger.info(
        'Max of embedding: ${embedding.reduce(math.max)}',
      );
      _logger.info(
        'Min of embedding: ${embedding.reduce(math.min)}',
      );

      return (embedding, isBlur[0], blurValue[0]);
    } catch (e) {
      _logger.info('MobileFaceNet Error while running inference: $e');
      rethrow;
    }
  }

  Future<List<List<double>>> predictInComputer(Float32List input) async {
    assert(sessionAddress != 0 && sessionAddress != -1 && isInitialized);
    return await _computerLock.synchronized(() async {
      try {
        final stopwatch = Stopwatch()..start();
        _logger.info('MobileFaceNet interpreter.run is called');
        final embeddings = await _computer.compute(
          inferFromMap,
          param: {
            'input': input,
            'address': sessionAddress,
            'inputSize': kInputSize,
          },
          taskName: 'createFaceEmbedding',
        ) as List<List<double>>;
        stopwatch.stop();
        _logger.info(
          'MobileFaceNet interpreter.run is finished, in ${stopwatch.elapsedMilliseconds}ms',
        );

        return embeddings;
      } catch (e) {
        _logger.info('MobileFaceNet Error while running inference: $e');
        rethrow;
      }
    });
  }

  static Future<List<List<double>>> predictSync(
    Float32List input,
    int sessionAddress,
  ) async {
    assert(sessionAddress != 0 && sessionAddress != -1);
    try {
      final stopwatch = Stopwatch()..start();
      _logger.info('MobileFaceNet interpreter.run is called');
      final embeddings = await infer(
        input,
        sessionAddress,
        kInputSize,
      );
      stopwatch.stop();
      _logger.info(
        'MobileFaceNet interpreter.run is finished, in ${stopwatch.elapsedMilliseconds}ms',
      );

      return embeddings;
    } catch (e) {
      _logger.info('MobileFaceNet Error while running inference: $e');
      rethrow;
    }
  }

  static Future<List<List<double>>> inferFromMap(Map args) async {
    final inputImageList = args['input'] as Float32List;
    final address = args['address'] as int;
    final inputSize = args['inputSize'] as int;
    return await infer(inputImageList, address, inputSize);
  }

  static Future<List<List<double>>> infer(
    Float32List inputImageList,
    int address,
    int inputSize,
  ) async {
    final runOptions = OrtRunOptions();
    final int numberOfFaces =
        inputImageList.length ~/ (inputSize * inputSize * 3);
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      [numberOfFaces, inputSize, inputSize, 3],
    );
    final inputs = {'img_inputs': inputOrt};
    final session = OrtSession.fromAddress(address);
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

    return embeddings;
  }
}
