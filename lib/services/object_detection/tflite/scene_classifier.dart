import 'dart:math';

import 'package:image/image.dart' as imageLib;
import "package:logging/logging.dart";
import 'package:photos/services/object_detection/models/predictions.dart';
import 'package:photos/services/object_detection/models/recognition.dart';
import "package:photos/services/object_detection/models/stats.dart";
import "package:photos/services/object_detection/tflite/classifier.dart";
import "package:tflite_flutter/tflite_flutter.dart";
import "package:tflite_flutter_helper/tflite_flutter_helper.dart";

// Source: https://tfhub.dev/sayannath/lite-model/image-scene/1
class SceneClassifier extends Classifier {
  final _logger = Logger("SceneClassifier");

  /// Instance of Interpreter
  late Interpreter _interpreter;

  /// Labels file loaded as list
  late List<String> _labels;

  static const int inputSize = 224;

  /// Result score threshold
  static const double threshold = 0.5;

  static const String modelPath = "models/scenes/model.tflite";
  static const String labelPath = "assets/models/scenes/labels.txt";

  /// [ImageProcessor] used to pre-process the image
  ImageProcessor? imageProcessor;

  /// Padding the image to transform into square
  late int padSize;

  /// Shapes of output tensors
  late List<List<int>> _outputShapes;

  /// Types of output tensors
  late List<TfLiteType> _outputTypes;

  /// Number of results to show
  static const int numResults = 10;

  SceneClassifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    loadModel(interpreter);
    loadLabels(labels);
  }

  /// Loads interpreter from asset
  void loadModel(Interpreter? interpreter) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            modelPath,
            options: InterpreterOptions()..threads = 4,
          );
      final outputTensors = _interpreter.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });
      _logger.info("Interpreter initialized");
    } catch (e, s) {
      _logger.severe("Error while creating interpreter", e, s);
    }
  }

  /// Loads labels from assets
  void loadLabels(List<String>? labels) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels(labelPath);
      _logger.info("Labels initialized");
    } catch (e, s) {
      _logger.severe("Error while loading labels", e, s);
    }
  }

  /// Pre-process the image
  TensorImage _getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    imageProcessor ??= ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .build();
    inputImage = imageProcessor!.process(inputImage);
    return inputImage;
  }

  @override
  Predictions? predict(imageLib.Image image) {
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

    // TensorBuffers for output tensors
    final output = TensorBufferFloat(_outputShapes[0]);
    final inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    // run inference
    _interpreter.run(input, output.buffer);

    final inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    final recognitions = <Recognition>[];
    for (int i = 0; i < _labels.length; i++) {
      final score = output.getDoubleValue(i);
      final label = _labels.elementAt(i);
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

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String> get labels => _labels;
}
