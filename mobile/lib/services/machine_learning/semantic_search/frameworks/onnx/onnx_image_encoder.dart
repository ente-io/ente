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

    final int nx = rgb.width;
    final int ny = rgb.height;
    final int inputSize = 3 * nx * ny;
    final inputImage = List.filled(inputSize, 0.toDouble());

    const int nx2 = 224;
    const int ny2 = 224;
    const int totalSize = 3 * nx2 * ny2;

    // Load image into List<double> inputImage
    for (int y = 0; y < ny; y++) {
      for (int x = 0; x < nx; x++) {
        final int i = 3 * (y * nx + x);
        final pixel = rgb.getPixel(x, y);
        inputImage[i] = pixel.r.toDouble();
        inputImage[i + 1] = pixel.g.toDouble();
        inputImage[i + 2] = pixel.b.toDouble();
      }
    }

    final result = List.filled(totalSize, 0.toDouble());
    final scale = max(nx, ny) / 224;

    final int nx3 = (nx / scale + 0.5).toInt();
    final int ny3 = (ny / scale + 0.5).toInt();

    final mean = [0.48145466, 0.4578275, 0.40821073];
    final std = [0.26862954, 0.26130258, 0.27577711];

    for (int y = 0; y < ny3; y++) {
      for (int x = 0; x < nx3; x++) {
        for (int c = 0; c < 3; c++) {
          //linear interpolation
          final double sx = (x + 0.5) * scale - 0.5;
          final double sy = (y + 0.5) * scale - 0.5;

          final int x0 = max(0, sx.floor());
          final int y0 = max(0, sy.floor());

          final int x1 = min(x0 + 1, nx - 1);
          final int y1 = min(y0 + 1, ny - 1);

          final double dx = sx - x0;
          final double dy = sy - y0;

          final int j00 = 3 * (y0 * nx + x0) + c;
          final int j01 = 3 * (y0 * nx + x1) + c;
          final int j10 = 3 * (y1 * nx + x0) + c;
          final int j11 = 3 * (y1 * nx + x1) + c;

          final double v00 = inputImage[j00];
          final double v01 = inputImage[j01];
          final double v10 = inputImage[j10];
          final double v11 = inputImage[j11];

          final double v0 = v00 * (1 - dx) + v01 * dx;
          final double v1 = v10 * (1 - dx) + v11 * dx;

          final double v = v0 * (1 - dy) + v1 * dy;

          final int v2 = min(max(v.round(), 0), 255);

          // createTensorWithDataList is dump compared to reshape and hence has to be given with one channel after another
          final int i = (y * nx3 + x) + (c % 3) * 224 * 224;

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
