import 'dart:math';

import 'package:image/image.dart' as image_lib;
import 'package:photos/services/object_detection/models/predictions.dart';
import 'package:photos/services/object_detection/models/recognition.dart';
import "package:photos/services/object_detection/models/stats.dart";
import "package:photos/services/object_detection/tflite/classifier.dart";
import "package:tflite_flutter/tflite_flutter.dart";
import "package:tflite_flutter_helper/tflite_flutter_helper.dart";

/// Classifier
class CocoSSDClassifier extends Classifier {
  static const int inputSize = 300;
  static const double threshold = 0.5;

  @override
  String get modelPath => "models/cocossd/model.tflite";

  @override
  String get labelPath => "assets/models/cocossd/labels.txt";

  /// Number of results to show
  static const int numResults = 10;

  CocoSSDClassifier({
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

    final preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // TensorBuffers for output tensors
    final outputLocations = TensorBufferFloat(outputShapes[0]);
    final outputClasses = TensorBufferFloat(outputShapes[1]);
    final outputScores = TensorBufferFloat(outputShapes[2]);
    final numLocations = TensorBufferFloat(outputShapes[3]);

    // Inputs object for runForMultipleInputs
    // Use [TensorImage.buffer] or [TensorBuffer.buffer] to pass by reference
    final inputs = [inputImage.buffer];

    // Outputs map
    final outputs = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };

    final inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    // run inference
    interpreter.runForMultipleInputs(inputs, outputs);

    final inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    // Maximum number of results to show
    final resultsCount = min(numResults, numLocations.getIntValue(0));

    // Using labelOffset = 1 as ??? at index 0
    const labelOffset = 1;

    final recognitions = <Recognition>[];

    for (int i = 0; i < resultsCount; i++) {
      // Prediction score
      final score = outputScores.getDoubleValue(i);

      // Label string
      final labelIndex = outputClasses.getIntValue(i) + labelOffset;
      final label = labels.elementAt(labelIndex);

      if (score > threshold) {
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
