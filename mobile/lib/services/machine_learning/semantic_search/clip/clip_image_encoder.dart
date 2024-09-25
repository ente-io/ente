import "dart:typed_data" show Uint8List;
import "dart:ui" show Image;

import "package:logging/logging.dart";
// import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/utils/debug_ml_export_data.dart";
// import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/ml_util.dart";

class ClipImageEncoder extends MlModel {
  static const kRemoteBucketModelPath =
      "mobileclip_s2_image_opset18_rgba_sim.onnx";
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
    Uint8List rawRgbaBytes,
    int sessionAddress, [
    int? enteFileID,
  ]) async {
    final startTime = DateTime.now();
    // final inputListAa = await preprocessImageClip(image, rawRgbaBytes, true);
    // final inputListNoaa = await preprocessImageClip(image, rawRgbaBytes, false);
    // await encodeAndSaveData(inputListAa, "star-aa-mobile-input", "clip");
    // await encodeAndSaveData(inputListNoaa, "star-noaa-mobile-input", "clip");
    final preprocessingTime = DateTime.now();
    final preprocessingMs =
        preprocessingTime.difference(startTime).inMilliseconds;
    late List<double> resultAa; //, resultNoaa;
    try {
      if (false) {
        // resultAa = await _runPlatformPluginPredict(rawRgbaBytes);
        // resultNoaa = await _runPlatformPluginPredict(inputListNoaa);
        // await encodeAndSaveData(resultAa, "star-aa-mobile-embedding", "clip");
        // await encodeAndSaveData(
        //   resultNoaa,
        //   "star-noaa-mobile-embedding",
        //   "clip",
        // );
      } else {
        resultAa = _runFFIBasedPredict(rawRgbaBytes, sessionAddress);
        print('clip inference done with FFI package');
      }
    } catch (e, stackTrace) {
      _logger.severe(
        "Clip image inference failed${enteFileID != null ? " with fileID $enteFileID" : ""}  (PlatformPlugin: ${MlModel.usePlatformPlugin})",
        e,
        stackTrace,
      );
      rethrow;
    }
    final inferTime = DateTime.now();
    final inferenceMs = inferTime.difference(preprocessingTime).inMilliseconds;
    final totalMs = inferTime.difference(startTime).inMilliseconds;
    _logger.info(
      "Clip image predict took $totalMs ms${enteFileID != null ? " with fileID $enteFileID" : ""} (inference: $inferenceMs ms, preprocessing: $preprocessingMs ms)",
    );
    await encodeAndSaveData(
      resultAa,
      'singapore-rgba-mobile-embedding-ffi',
      'clip',
    );
    return resultAa;
  }

  static List<double> _runFFIBasedPredict(
    Uint8List inputImageList,
    int sessionAddress,
  ) {
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputImageList,
      [1200, 1920, 4],
    );
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
    return embedding;
  }

  // static Future<List<double>> _runPlatformPluginPredict(
  //   Uint8List inputImageList,
  // ) async {
  //   final OnnxDart plugin = OnnxDart();
  //   final result = await plugin.predictRgba(
  //     inputImageList,
  //     _modelName,
  //   );
  //   final List<double> embedding = result!.sublist(0, 512);
  //   normalizeEmbedding(embedding);
  //   return embedding;
  // }
}
