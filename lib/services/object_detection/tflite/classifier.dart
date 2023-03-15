import "dart:math";

import 'package:image/image.dart' as image_lib;
import "package:logging/logging.dart";
import "package:photos/services/object_detection/models/predictions.dart";
import "package:tflite_flutter/tflite_flutter.dart";
import "package:tflite_flutter_helper/tflite_flutter_helper.dart";

abstract class Classifier {
  // Path to the model
  String get modelPath;

  // Path to the labels
  String get labelPath;

  // Input size expected by the model (for eg. width = height = 224)
  int get inputSize;

  // Logger implementation for the specific classifier
  Logger get logger;

  Predictions? predict(image_lib.Image image);

  /// Instance of Interpreter
  late Interpreter _interpreter;

  /// Labels file loaded as list
  late List<String> _labels;

  /// Shapes of output tensors
  late List<List<int>> _outputShapes;

  /// Types of output tensors
  late List<TfLiteType> _outputTypes;

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String> get labels => _labels;

  /// Gets the output shapes
  List<List<int>> get outputShapes => _outputShapes;

  /// Gets the output types
  List<TfLiteType> get outputTypes => _outputTypes;

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
      logger.info("Interpreter initialized");
    } catch (e, s) {
      logger.severe("Error while creating interpreter", e, s);
    }
  }

  /// Loads labels from assets
  void loadLabels(List<String>? labels) async {
    try {
      _labels = labels ?? await FileUtil.loadLabels(labelPath);
      logger.info("Labels initialized");
    } catch (e, s) {
      logger.severe("Error while loading labels", e, s);
    }
  }

  /// Pre-process the image
  TensorImage getProcessedImage(TensorImage inputImage) {
    final padSize = max(inputImage.height, inputImage.width);
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }
}
