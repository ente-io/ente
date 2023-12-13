import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:flutter/services.dart";
import 'package:image/image.dart' as img;
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";

class OnnxImageEncoder {
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;
  final _logger = Logger("CLIPImageEncoder");

  OnnxImageEncoder() {
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
      _logger.info('image model loaded');
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  List<double> inferByImage(Map args) {
    final runOptions = OrtRunOptions();
    //Check the existence of imagePath locally
    final rgb = img.decodeImage(File(args["imagePath"]).readAsBytesSync())!;

    dynamic inputImage;
    if (rgb.height >= rgb.width) {
      inputImage = img.copyResize(
        rgb,
        width: 224,
        interpolation: img.Interpolation.linear,
      );
      inputImage = img.copyCrop(
        inputImage,
        x: 0,
        y: (inputImage.height - 224) ~/ 2,
        width: 224,
        height: 224,
      );
    } else {
      inputImage = img.copyResize(
        rgb,
        height: 224,
        interpolation: img.Interpolation.linear,
      );
      inputImage = img.copyCrop(
        inputImage,
        x: (inputImage.width - 224) ~/ 2,
        y: 0,
        width: 224,
        height: 224,
      );
    }

    final mean = [0.48145466, 0.4578275, 0.40821073];
    final std = [0.26862954, 0.26130258, 0.27577711];
    final processedImage = imageToByteListFloat32(rgb, 224, mean, std);

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      processedImage,
      [1, 3, 224, 224],
    );
    final inputs = {'input': inputOrt};
    final outputs = _session?.run(runOptions, inputs);
    final embedding = (outputs?[0]?.value as List<List<double>>)[0];
    double imageNormalization = 0;
    for (int i = 0; i < 512; i++) {
      imageNormalization += embedding[i] * embedding[i];
    }
    for (int i = 0; i < 512; i++) {
      embedding[i] = embedding[i] / sqrt(imageNormalization);
    }
    inputOrt.release();
    runOptions.release();
    return embedding;
  }

  Float32List imageToByteListFloat32(
    img.Image image,
    int inputSize,
    List<double> mean,
    List<double> std,
  ) {
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
