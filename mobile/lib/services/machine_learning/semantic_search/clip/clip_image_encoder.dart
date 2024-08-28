import "dart:typed_data";
import "dart:ui" show Image;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

class ClipImageEncoder extends MlModel {
  static const kRemoteBucketModelPath = "mobileclip_s2_image.onnx";
  static const _modelName = "ClipImageEncoder";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('ClipImageEncoder');

  @override
  String get modelName => _modelName;

  // Singleton pattern
  ClipImageEncoder._privateConstructor();
  static final instance = ClipImageEncoder._privateConstructor();
  factory ClipImageEncoder() => instance;

  static Future<List<double>> predict(
    Image image,
    ByteData imageByteData,
    int sessionAddress,
  ) async {
    final inputList = await preprocessImageClip(image, imageByteData);
    if (MlModel.usePlatformPlugin) {
      return await _runPlatformPluginPredict(inputList);
    } else {
      return _runFFIBasedPredict(inputList, sessionAddress);
    }
  }

  static List<double> _runFFIBasedPredict(
    Float32List inputList,
    int sessionAddress,
  ) {
    final w = EnteWatch("ClipImageEncoder._runFFIBasedPredict")..start();
    final inputOrt =
        OrtValueTensor.createTensorWithDataList(inputList, [1, 3, 256, 256]);
    final inputs = {'input': inputOrt};
    final session = OrtSession.fromAddress(sessionAddress);
    final runOptions = OrtRunOptions();
    final outputs = session.run(runOptions, inputs);
    final embedding = (outputs[0]?.value as List<List<double>>)[0];
    inputOrt.release();
    runOptions.release();
    for (var element in outputs) {
      element?.release();
    }
    normalizeEmbedding(embedding);
    w.stopWithLog("done");
    return embedding;
  }

  static Future<List<double>> _runPlatformPluginPredict(
    Float32List inputImageList,
  ) async {
    final w = EnteWatch("ClipImageEncoder._runEntePlugin")..start();
    final OnnxDart plugin = OnnxDart();
    final result = await plugin.predict(
      inputImageList,
      _modelName,
    );
    final List<double> embedding = result!.sublist(0, 512);
    normalizeEmbedding(embedding);
    w.stopWithLog("done");
    return embedding;
  }
}
