import 'dart:math';

import 'package:image/image.dart' as image_lib;
import 'package:photos/services/object_detection/models/predictions.dart';
import 'package:photos/services/object_detection/models/recognition.dart';
import "package:photos/services/object_detection/models/stats.dart";
import "package:photos/services/object_detection/tflite/classifier.dart";
import "package:tflite_flutter/tflite_flutter.dart";
import "package:tflite_flutter_helper/tflite_flutter_helper.dart";

// Source: https://tfhub.dev/sayannath/lite-model/image-scene/1
class SceneClassifier extends Classifier {
  static const int inputSize = 224;
  static const double threshold = 0.5;

  @override
  String get modelPath => "models/scenes/model.tflite";

  @override
  String get labelPath => "assets/models/scenes/labels.txt";

  SceneClassifier({
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
    inputImage = _getProcessedImage(inputImage);
    final list = inputImage.getTensorBuffer().getDoubleList();
    final input = list.reshape([1, inputSize, inputSize, 3]);

    final preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    final output = TensorBufferFloat(outputShapes[0]);

    final inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(input, output.buffer);
    final inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    final recognitions = <Recognition>[];
    for (int i = 0; i < labels.length; i++) {
      final score = output.getDoubleValue(i);
      final label = labels.elementAt(i);
      if (score >= threshold) {
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

  /// Pre-process the image
  TensorImage _getProcessedImage(TensorImage inputImage) {
    final padSize = max(inputImage.height, inputImage.width);
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }
}
