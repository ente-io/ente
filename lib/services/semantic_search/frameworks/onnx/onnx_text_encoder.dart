import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/semantic_search/frameworks/onnx/onnx_text_tokenizer.dart";

class OnnxTextEncoder {
  static const kVocabFilePath = "assets/models/clip/bpe_simple_vocab_16e6.txt";
  final _logger = Logger("OnnxTextEncoder");
  final OnnxTextTokenizer _tokenizer = OnnxTextTokenizer();

  // Do not run in an isolate since rootBundle can only be accessed in the main isolate
  Future<void> initTokenizer() async {
    final vocab = await rootBundle.loadString(kVocabFilePath);
    await _tokenizer.init(vocab);
  }

  Future<int> loadModel(Map args) async {
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      _logger.info("Loading text model");
      final session =
          OrtSession.fromFile(File(args["textModelPath"]), sessionOptions);
      _logger.info('text model loaded');
      return session.address;
    } catch (e, s) {
      _logger.severe('text model not loaded', e, s);
    }
    return -1;
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
