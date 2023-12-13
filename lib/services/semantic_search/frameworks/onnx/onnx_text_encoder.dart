import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/semantic_search/frameworks/onnx/onnx_text_tokenizer.dart";

class OnnxTextEncoder {
  static const vocabFilePath = "assets/clip/bpe_simple_vocab_16e6.txt";
  final _logger = Logger("CLIPTextEncoder");
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;

  OnnxTextEncoder() {
    OrtEnv.instance.init();
    OrtEnv.instance.availableProviders().forEach((element) {
      print('onnx provider=$element');
    });
  }

  release() {
    _sessionOptions?.release();
    _sessionOptions = null;
    _session?.release();
    _session = null;
    OrtEnv.instance.release();
  }

  Future<void> loadModel(Map args) async {
    _sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

    try {
      final bytes = File(args["textModelPath"]).readAsBytesSync();
      _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
      _logger.info('text model loaded');
    } catch (e, s) {
      _logger.severe('text model not loaded', e, s);
    }
  }

  Future<List<double>> infer(Map args) async {
    final text = args["text"];
    final runOptions = OrtRunOptions();
    final tokenizer = OnnxTextTokenizer(vocabFilePath);
    await tokenizer.init();
    final data = List.filled(1, Int32List.fromList(tokenizer.tokenize(text)));
    final inputOrt = OrtValueTensor.createTensorWithDataList(data, [1, 77]);
    final inputs = {'input': inputOrt};
    final outputs = _session?.run(runOptions, inputs);
    final embedding = (outputs?[0]?.value as List<List<double>>)[0];
    double textNormalization = 0;
    for (int i = 0; i < 512; i++) {
      textNormalization += embedding[i] * embedding[i];
    }

    for (int i = 0; i < 512; i++) {
      embedding[i] = embedding[i] / sqrt(textNormalization);
    }

    inputOrt.release();
    runOptions.release();
    _session?.release();
    return (embedding);
  }
}
