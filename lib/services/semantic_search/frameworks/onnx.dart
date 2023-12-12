import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:computer/computer.dart";
import "package:flutter/services.dart";
import "package:html_unescape/html_unescape.dart";
import 'package:image/image.dart' as img;
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/semantic_search/frameworks/ml_framework.dart";
import "package:tuple/tuple.dart";

class ONNX extends MLFramework {
  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kImageModel = "clip-vit-base-patch32_ggml-vision-model-f16.gguf";
  static const kTextModel = "clip-vit-base-patch32_ggml-text-model-f16.gguf";
  final _computer = Computer.shared();
  final _logger = Logger("ONNX");
  final _clipImage = ClipImageEncoder();
  final _clipText = ClipTextEncoder();

  @override
  String getImageModelRemotePath() {
    return kModelBucketEndpoint + kImageModel;
  }

  @override
  String getTextModelRemotePath() {
    return kModelBucketEndpoint + kTextModel;
  }

  @override
  Future<void> loadImageModel(String path) async {
    final startTime = DateTime.now();
    await _computer.compute(
      _clipImage.loadModel,
      param: {
        "imageModelPath": path,
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading image model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  @override
  Future<void> loadTextModel(String path) async {
    final startTime = DateTime.now();
    await _computer.compute(
      _clipText.loadModel,
      param: {
        "textModelPath": path,
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading text model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  @override
  Future<List<double>> getImageEmbedding(String imagePath) async {
    try {
      final startTime = DateTime.now();
      final result = await _computer.compute(
        _clipImage.inferByImage,
        param: {
          "imagePath": imagePath,
        },
        taskName: "createImageEmbedding",
      ) as List<double>;
      final endTime = DateTime.now();
      _logger.info(
        "createImageEmbedding took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      return result;
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  @override
  Future<List<double>> getTextEmbedding(String text) async {
    try {
      final startTime = DateTime.now();
      final result = await _computer.compute(
        _clipText.infer,
        param: {
          "text": text,
        },
        taskName: "createTextEmbedding",
      ) as List<double>;
      final endTime = DateTime.now();
      _logger.info(
        "createTextEmbedding took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      return result;
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }
}


class ClipImageEncoder {
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;

  ClipImageEncoder() {
    OrtEnv.instance.init();
  }

  release() {
    _sessionOptions?.release();
    _sessionOptions = null;
    _session?.release();
    _session = null;
    OrtEnv.instance.release();
  }

  loadModel(Map args) async {
    _sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      //const assetFileName = 'assets/models/clip-image-vit-32-float32.onnx';
      // Check if the path exists locally
      final rawAssetFile = await rootBundle.load(args["imageModelPath"]);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
      print('image model loaded');
    } catch (e, s) {
      print('image model not loaded');
    }
  }

  List<double> inferByImage(Map args) {
    final runOptions = OrtRunOptions();
    //Check the existence of imagePath locally
    final rgb = img.decodeImage(File(args["imagePath"]).readAsBytesSync())!;

    dynamic inputImage;
    if (rgb.height >= rgb.width) {
      inputImage = img.copyResize(rgb,
          width: 224, interpolation: img.Interpolation.linear,);
      inputImage = img.copyCrop(inputImage,
          x: 0, y: (inputImage.height - 224) ~/ 2, width: 224, height: 224,);
    } else {
      inputImage = img.copyResize(rgb,
          height: 224, interpolation: img.Interpolation.linear,);
      inputImage = img.copyCrop(inputImage,
          x: (inputImage.width - 224) ~/ 2, y: 0, width: 224, height: 224,);
    }

    final mean = [0.48145466, 0.4578275, 0.40821073];
    final std = [0.26862954, 0.26130258, 0.27577711];
    final processedImage = imageToByteListFloat32(rgb, 224, mean, std);

    final inputOrt = OrtValueTensor.createTensorWithDataList(
        processedImage, [1, 3, 224, 224],);
    final inputs = {'input': inputOrt};
    final outputs = _session?.run(runOptions, inputs);
    final finalembedding = (outputs?[0]?.value as List<List<double>>)[0];
    double imageNormalization = 0;
    for (int i = 0; i < 512; i++) {
      imageNormalization += finalembedding[i] * finalembedding[i];
    }
    for (int i = 0; i < 512; i++) {
      finalembedding[i] = finalembedding[i] / sqrt(imageNormalization);
    }
    inputOrt.release();
    runOptions.release();
    return finalembedding;
  }

  Float32List imageToByteListFloat32(
      img.Image image, int inputSize, List<double> mean, List<double> std,) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    assert(mean.length == 3);
    assert(std.length == 3);

    //TODO: rewrite this part 
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(i, j);
        buffer[pixelIndex++] = ((pixel.r / 255) - mean[0]) / std[0];
        buffer[pixelIndex++] = ((pixel.g / 255) - mean[1]) / std[1];
        buffer[pixelIndex++] = ((pixel.b / 255) - mean[2]) / std[2];
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}

class ClipTextEncoder {
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;

  ClipTextEncoder() {
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

  loadModel(Map args) async {
    _sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    
    try {
      //const assetFileName = 'assets/models/clip-text-vit-32-float32-int32.onnx';
      // Check if path exists locally
      final rawAssetFile = await rootBundle.load(args["textModelPath"]);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
      print('text model loaded');
    } catch (e, s) {
      print('text model not loaded');
    }
  }

  Future<List<double>> infer(Map args) async {
    final text = args["text"];
    final runOptions = OrtRunOptions();
    final tokenizer = CLIPTokenizer();
    await tokenizer.init();
    final data = List.filled(1, Int32List.fromList(tokenizer.tokenize(text)));
    final inputOrt = OrtValueTensor.createTensorWithDataList(data, [1, 77]);
    final inputs = {'input': inputOrt};
    final outputs = _session?.run(runOptions, inputs);
    final finalembedding = (outputs?[0]?.value as List<List<double>>)[0];
    double textNormalization = 0;
    for (int i = 0; i < 512; i++) {
      textNormalization += finalembedding[i] * finalembedding[i];
    }

    for (int i = 0; i < 512; i++) {
      finalembedding[i] = finalembedding[i] / sqrt(textNormalization);
    }
    
    inputOrt.release();
    runOptions.release();
    _session?.release();
    return(finalembedding);
  }
}

class CLIPTokenizer {
  String bpePath = "assets/vocab/bpe_simple_vocab_16e6.txt";
  late Map<int, String> byteEncoder;
  late Map<String, int> byteDecoder;
  late Map<int, String> decoder;
  late Map<String, int> encoder;
  late Map<Tuple2<String, String>, int> bpeRanks;
  Map<String, String> cache = <String, String>{'<|startoftext|>':'<|startoftext|>', '<|endoftext|>':'<|endoftext|>'};

  // Dart RegExpt does not support Unicode identifiers (\p{L} and \p{N})
  RegExp pat = RegExp(r"""<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[a-zA-Z]+|[0-9]+|[^\s\p{L}\p{N}]+""", caseSensitive: false, multiLine: false);
  
  late int sot;
  late int eot;

  CLIPTokenizer();

  // Async method since the loadFile returns a Future and dart constructor cannot be async
  Future init() async {
    
    final bpe = await loadFile();
    byteEncoder = bytesToUnicode();
    byteDecoder = byteEncoder.map((k, v) => MapEntry(v, k));

    var _merges = bpe.split('\n');
    _merges = _merges.sublist(1, 49152 - 256 - 2 + 1);
    final merges = _merges.map((merge) => Tuple2(merge.split(' ')[0], merge.split(' ')[1])).toList();

    final vocab = byteEncoder.values.toList();
    vocab.addAll(vocab.map((v) => '$v</w>').toList());

    for(var merge = 0; merge < merges.length; merge++) {
      vocab.add(merges[merge].item1 + merges[merge].item2);
    }
    vocab.addAll(['<|startoftext|>', '<|endoftext|>']);
    
    // asMap returns the map as a Map<int, String>
    decoder = vocab.asMap();
    encoder = decoder.map((k, v) => MapEntry(v, k));
    bpeRanks = Map.fromIterables(
      merges.map((merge) => merge),
      List.generate(merges.length, (i) => i),
    );

    sot = encoder['<|startoftext|>']!;
    eot = encoder['<|endoftext|>']!;
  }

  Future<String> loadFile() async {
    return await rootBundle.loadString(bpePath);
  }

  List<int> encode(String text) {
    final List<int> bpeTokens = [];
    text = whitespaceClean(basicClean(text)).toLowerCase();
    for (Match match in pat.allMatches(text)) {
      String token = match[0]!;
      token = utf8.encode(token).map((b) => byteEncoder[b]).join();
      bpe(token).split(' ').forEach((bpeToken) => bpeTokens.add(encoder[bpeToken]!));
    }
    return bpeTokens;
  }

  String bpe(String token) {
    if (cache.containsKey(token)) {
      return cache[token]!;
    }
    var word = token.split('').map((char) => char).toList();
    word[word.length - 1] = '${word.last}</w>';
    var pairs = getPairs(word);
    if (pairs.isEmpty) {
      return '$token</w>';
    }

    while (true) {

      Tuple2<String, String> bigram = pairs.first;
      for (var pair in pairs) {
        var rank1 = bpeRanks[pair] ?? double.infinity;
        var rank2 = bpeRanks[bigram] ?? double.infinity;

        if (rank1 < rank2) {
          bigram = pair;
        }
      }
    
      if (!bpeRanks.containsKey(bigram)) {
        break;
      }
      var first = bigram.item1;
      var second = bigram.item2;
      var newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        var j = word.sublist(i).indexOf(first);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }
        newWord.addAll(word.sublist(i, i + j));
        i = i + j;
        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }

      word = newWord;
      if (word.length == 1) {
        break;
      } else {
        pairs = getPairs(word);
      }
    }
    var wordStr = word.join(' ');
    cache[token] = wordStr;
    return wordStr;
  }

  List<int> tokenize(String text, {int nText = 76, bool pad = true}) {
    var tokens = encode(text);
    tokens = [sot] + tokens.sublist(0, min(nText - 1, tokens.length)) + [eot];
    if (pad) {
      return tokens + List.filled(nText + 1 - tokens.length, 0);
    } else {
      return tokens;
    }
  }

  List<int> pad (List<int> x, int padLength){
    return x + List.filled(padLength - x.length, 0);
  }

  Map<int, String> bytesToUnicode() {
    List<int> bs = [];
    for (int i = '!'.codeUnitAt(0); i <= '~'.codeUnitAt(0); i++) {
      bs.add(i);
    }
    for (int i = '¡'.codeUnitAt(0); i <= '¬'.codeUnitAt(0); i++) {
      bs.add(i);
    }
    for (int i = '®'.codeUnitAt(0); i <= 'ÿ'.codeUnitAt(0); i++) {
      bs.add(i);
    }

    List<int> cs = List.from(bs);
    int n = 0;
    for (int b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n += 1;
      }
    }

    List<String> ds = cs.map((n) => String.fromCharCode(n)).toList();
    return Map.fromIterables(bs, ds);
  }

  Set<Tuple2<String, String>> getPairs(List<String> word) {
    Set<Tuple2<String, String>> pairs = {};
    String prevChar = word[0];
    for (var i = 1; i < word.length; i++) {
      pairs.add(Tuple2(prevChar, word[i]));
      prevChar = word[i];
    }
    return pairs;
  }

  String basicClean(String text) {
    var unescape = HtmlUnescape();
    text = unescape.convert(unescape.convert(text));
    return text.trim();
  }
  
  String whitespaceClean(String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }


}
