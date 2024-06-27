import "dart:io";
import "dart:math";
import "dart:typed_data";

import 'package:image/image.dart' as img;
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";

class OnnxImageEncoder {
  final _logger = Logger("OnnxImageEncoder");

  Future<int> loadModel(Map args) async {
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      final session =
          OrtSession.fromFile(File(args["imageModelPath"]), sessionOptions);
      _logger.info('image model loaded');

      return session.address;
    } catch (e, s) {
      _logger.severe(e, s);
    }
    return -1;
  }

  Future<List<double>> inferByImage(Map args) async {
    final runOptions = OrtRunOptions();
    //Check the existence of imagePath locally
    final rgb = img.decodeImage(await File(args["imagePath"]).readAsBytes())!;

    final int imageWidth = rgb.width;
    final int imageHeight = rgb.height;
    final int inputSize = 3 * imageWidth * imageHeight;
    final inputImage = List.filled(inputSize, 0.toDouble());

    const int requiredWidth = 224;
    const int requiredHeight = 224;
    const int totalSize = 3 * requiredWidth * requiredHeight;

    // Load image into List<double> inputImage
    for (int y = 0; y < imageHeight; y++) {
      for (int x = 0; x < imageWidth; x++) {
        final int i = 3 * (y * imageWidth + x);
        final pixel = rgb.getPixel(x, y);
        inputImage[i] = pixel.r.toDouble();
        inputImage[i + 1] = pixel.g.toDouble();
        inputImage[i + 2] = pixel.b.toDouble();
      }
    }

    final result = List.filled(totalSize, 0.toDouble());
    final invertedScale = max(imageWidth, imageHeight) / 224;

    final int scaledWidth = (imageWidth / invertedScale + 0.5).toInt();
    final int scaledHeight = (imageHeight / invertedScale + 0.5).toInt();

    final mean = [0.48145466, 0.4578275, 0.40821073];
    final std = [0.26862954, 0.26130258, 0.27577711];

    for (int y = 0; y < scaledHeight; y++) {
      for (int x = 0; x < scaledWidth; x++) {
        for (int c = 0; c < 3; c++) {
          //linear interpolation
          final double scaledX = (x + 0.5) * invertedScale - 0.5;
          final double scaledY = (y + 0.5) * invertedScale - 0.5;

          final int x0 = max(0, scaledX.floor());
          final int y0 = max(0, scaledY.floor());

          final int x1 = min(x0 + 1, imageWidth - 1);
          final int y1 = min(y0 + 1, imageHeight - 1);

          final double dx = scaledX - x0;
          final double dy = scaledY - y0;

          final int j00 = 3 * (y0 * imageWidth + x0) + c;
          final int j01 = 3 * (y0 * imageWidth + x1) + c;
          final int j10 = 3 * (y1 * imageWidth + x0) + c;
          final int j11 = 3 * (y1 * imageWidth + x1) + c;

          final double pixel1 = inputImage[j00];
          final double pixel2 = inputImage[j01];
          final double pixel3 = inputImage[j10];
          final double pixel4 = inputImage[j11];

          final double v0 = pixel1 * (1 - dx) + pixel2 * dx;
          final double v1 = pixel3 * (1 - dx) + pixel4 * dx;

          final double v = v0 * (1 - dy) + v1 * dy;

          final int v2 = min(max(v.round(), 0), 255);

          // createTensorWithDataList is dump compared to reshape and hence has to be given with one channel after another
          final int i = (y * scaledWidth + x) + (c % 3) * 224 * 224; // TODO: is the use of scaledWidth here intentional, or is it a mistake to not use requiredWidth?

          result[i] = ((v2 / 255) - mean[c]) / std[c];
        }
      }
    }
    final floatList = Float32List.fromList(result);

    final inputOrt =
        OrtValueTensor.createTensorWithDataList(floatList, [1, 3, 224, 224]);
    final inputs = {'input': inputOrt};
    final session = OrtSession.fromAddress(args["address"]);
    final outputs = session.run(runOptions, inputs);
    final embedding = (outputs[0]?.value as List<List<double>>)[0];

    double imageNormalization = 0;
    for (int i = 0; i < 512; i++) {
      imageNormalization += embedding[i] * embedding[i];
    }
    final double sqrtImageNormalization = sqrt(imageNormalization);
    for (int i = 0; i < 512; i++) {
      embedding[i] = embedding[i] / sqrtImageNormalization;
    }
    return embedding;
  }
}
