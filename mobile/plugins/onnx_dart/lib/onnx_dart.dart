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

  Future<bool?> release(String modelType) {
    return OnnxDartPlatform.instance.release(modelType);
  }

  Future<Float32List?> predict(
    Float32List inputData,
    String modelType, {
    int sessionAddress = 0,
  }) async {
    final result = await OnnxDartPlatform.instance
        .predict(inputData, null, modelType, sessionAddress: sessionAddress);
    return result;
  }

  Future<Float32List?> predictInt(
    Int32List inputDataInt,
    String modelType, {
    int sessionAddress = 0,
  }) async {
    final result = await OnnxDartPlatform.instance
        .predict(null, inputDataInt, modelType, sessionAddress: sessionAddress);
    return result;
  }
}
