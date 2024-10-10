import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import 'package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart';
import "package:photos/utils/ml_util.dart";

class ClipTextEncoder extends MlModel {
  static const kRemoteBucketModelPath =
      "mobileclip_s2_text_opset18_quant.onnx"; // Quantized model
  static const _kVocabRemotePath = "bpe_simple_vocab_16e6.txt";

  static const _modelName = "ClipTextEncoder";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;
  String get vocabRemotePath => kModelBucketEndpoint + _kVocabRemotePath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('ClipTextEncoder');

  @override
  String get modelName => _modelName;

  // Singleton pattern
  ClipTextEncoder._privateConstructor();
  static final instance = ClipTextEncoder._privateConstructor();
  factory ClipTextEncoder() => instance;

  static Future<List<double>> predict(Map args) async {
    final text = args["text"] as String;
    final address = args["address"] as int;
    final startTime = DateTime.now();
    final List<int> tokenize = await ClipTextTokenizer.instance.tokenize(text);
    final int32list = Int32List.fromList(tokenize);
    final tokenizeTime = DateTime.now();
    final tokenizeMs = tokenizeTime.difference(startTime).inMilliseconds;
    try {
      late List<double> embedding;
      if (MlModel.usePlatformPlugin) {
        embedding = await _runPlatformPluginPredict(int32list);
      } else {
        embedding = _runFFIBasedPredict(int32list, address);
      }
      final inferTime = DateTime.now();
      final inferMs = inferTime.difference(tokenizeTime).inMilliseconds;
      final totalMs = inferTime.difference(startTime).inMilliseconds;
      _logger.info(
        "Clip text predict took $totalMs ms (predict: $inferMs ms, tokenize: $tokenizeMs ms) for text: '$text'",
      );
      return embedding;
    } catch (e, s) {
      _logger.severe(
        "Clip text inference failed  (PlatformPlugin: ${MlModel.usePlatformPlugin})",
        e,
        s,
      );
      rethrow;
    }
  }

  static List<double> _runFFIBasedPredict(
    Int32List int32list,
    int address,
  ) {
    final runOptions = OrtRunOptions();
    final data = List.filled(1, int32list);
    final inputOrt = OrtValueTensor.createTensorWithDataList(data, [1, 77]);
    final inputs = {'input': inputOrt};
    final session = OrtSession.fromAddress(address);
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
    Int32List int32list,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predictInt(
      int32list,
      _modelName,
    );
    final List<double> embedding = result!.sublist(0, 512);
    normalizeEmbedding(embedding);
    return embedding;
  }
}
