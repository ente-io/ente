import 'package:image/image.dart' as image_lib;
import "package:logging/logging.dart";
import 'package:photos/services/object_detection/models/predictions.dart';
import 'package:photos/services/object_detection/models/recognition.dart';
import "package:photos/services/object_detection/models/stats.dart";
import "package:photos/services/object_detection/tflite/classifier.dart";
import "package:tflite_flutter/tflite_flutter.dart";
import "package:tflite_flutter_helper/tflite_flutter_helper.dart";

// Source: https://tfhub.dev/tensorflow/lite-model/mobilenet_v1_1.0_224/1/default/1
class MobileNetClassifier extends Classifier {
  static final _logger = Logger("MobileNetClassifier");
  static const double threshold = 0.5;

  @override
  String get modelPath => "models/mobilenet/mobilenet_v1_1.0_224_quant.tflite";

  @override
  String get labelPath =>
      "assets/models/mobilenet/labels_mobilenet_quant_v1_224.txt";

  @override
  int get inputSize => 224;

  @override
  Logger get logger => _logger;

  MobileNetClassifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    loadModel(interpreter);
    loadLabels(labels);
  }

  @override
  Predictions? predict(image_lib.Image image) {
    final predictStartTime = DateTime.now().millisecondsSinceEpoch;

    final preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // Create TensorImage from image
    TensorImage inputImage = TensorImage.fromImage(image);

    // Pre-process TensorImage
    inputImage = getProcessedImage(inputImage);

    final preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // TensorBuffers for output tensors
    final output = TensorBufferUint8(outputShapes[0]);
    final inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    // run inference
    interpreter.run(inputImage.buffer, output.buffer);

    final inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    final recognitions = <Recognition>[];
    for (int i = 0; i < labels.length; i++) {
      final score = output.getDoubleValue(i) / 255;
      if (score >= threshold) {
        final label = labels.elementAt(i);

        recognitions.add(
          Recognition(i, label, score),
        );
      }
    }

    final predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;
    return Predictions(
      recognitions,
      Stats(
        predictElapsedTime,
        predictElapsedTime,
        inferenceTimeElapsed,
        preProcessElapsedTime,
      ),
    );
  }
}
