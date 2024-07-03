import "dart:io";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import 'package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart';
import "package:photos/services/remote_assets_service.dart";

class ClipTextEncoder extends MlModel {
  static const kRemoteBucketModelPath = "clip-text-vit-32-float32-int32.onnx";
  // static const kRemoteBucketModelPath = "clip-text-vit-32-uint8.onnx";
  static const kRemoteBucketVocabPath = "bpe_simple_vocab_16e6.txt";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  String get kVocabRemotePath => kModelBucketEndpoint + kRemoteBucketVocabPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('ClipTextEncoder');

  @override
  String get modelName => "ClipTextEncoder";

  // Singleton pattern
  ClipTextEncoder._privateConstructor();
  static final instance = ClipTextEncoder._privateConstructor();
  factory ClipTextEncoder() => instance;

  final OnnxTextTokenizer _tokenizer = OnnxTextTokenizer();

  Future<void> initTokenizer() async {
    final File vocabFile =
        await RemoteAssetsService.instance.getAsset(kVocabRemotePath);
    final String vocab = await vocabFile.readAsString();
    await _tokenizer.init(vocab);
  }

  Future<List<double>> infer(Map args) async {
    final text = args["text"];
    final address = args["address"] as int;
    final runOptions = OrtRunOptions();
    final tokenize = _tokenizer.tokenize(text);
    final data = List.filled(1, Int32List.fromList(tokenize));
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

    return (embedding);
  }
}
