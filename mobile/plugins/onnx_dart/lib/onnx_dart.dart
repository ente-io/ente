import 'dart:typed_data';

import 'package:onnx_dart/onnx_dart_platform_interface.dart';

class OnnxDart {
  Future<String?> getPlatformVersion() {
    return OnnxDartPlatform.instance.getPlatformVersion();
  }

  Future<bool?> init(
    String modelType,
    String modelPath, {
    int sessionsCount = 1,
  }) {
    return OnnxDartPlatform.instance
        .init(modelType, modelPath, sessionsCount: sessionsCount);
  }

  Future<dynamic?> predict(
    Float32List inputData,
    String modelType, {
    int sessionAddress = 0,
  }) async {
    return OnnxDartPlatform.instance
        .predict(inputData, modelType, sessionAddress: sessionAddress);
  }
}
