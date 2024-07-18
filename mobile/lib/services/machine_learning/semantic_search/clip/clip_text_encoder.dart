import "dart:math";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import 'package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart';
import "package:photos/utils/ml_util.dart";

class ClipTextEncoder extends MlModel {
  static const kRemoteBucketModelPath = "clip-text-vit-32-float32-int32.onnx";

  // static const kRemoteBucketModelPath = "clip-text-vit-32-uint8.onnx";
  static const _modelName = "ClipTextEncoder";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('ClipTextEncoder');

  @override
  String get modelName => _modelName;

  // Singleton pattern
  ClipTextEncoder._privateConstructor();
  static final instance = ClipTextEncoder._privateConstructor();
  factory ClipTextEncoder() => instance;

  static Future<List<double>> infer(Map args) async {
    final text = args["text"];
    final address = args["address"] as int;
    final List<int> tokenize = await ClipTextTokenizer.instance.tokenize(text);
    final int32list = Int32List.fromList(tokenize);
    return _runFFIBasedPredict(int32list, address);
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
    double textNormalization = 0;
    for (int i = 0; i < 512; i++) {
      textNormalization += embedding[i] * embedding[i];
    }
    final double sqrtTextNormalization = sqrt(textNormalization);
    for (int i = 0; i < 512; i++) {
      embedding[i] = embedding[i] / sqrtTextNormalization;
    }
    return embedding;
  }

  static Future<List<double>> _runEntePlugin(Int32List int32list) async {
    final w = EnteWatch("ClipTextEncoder._runEntePlugin")..start();
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predictInt(
      int32list,
      _modelName,
    );
    final List<double> embedding = result!.sublist(0, 512);
    normalizeEmbedding(embedding);
    w.stopWithLog("done");
    return embedding;
  }
}
