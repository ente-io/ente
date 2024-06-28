import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/utils/image_ml_util.dart";

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
    final imageData = await File(args["imagePath"]).readAsBytes();
    final image = await decodeImageFromData(imageData);
    final ByteData imgByteData = await getByteDataFromImage(image);

    final inputList = await preprocessImageClip(image, imgByteData);

    final inputOrt =
        OrtValueTensor.createTensorWithDataList(inputList, [1, 3, 224, 224]);
    final inputs = {'input': inputOrt};
    final session = OrtSession.fromAddress(args["address"]);
    final runOptions = OrtRunOptions();
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
