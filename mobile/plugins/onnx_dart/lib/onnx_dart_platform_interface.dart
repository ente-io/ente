import 'dart:typed_data';

import 'package:onnx_dart/onnx_dart_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OnnxDartPlatform extends PlatformInterface {
  /// Constructs a OnnxDartPlatform.
  OnnxDartPlatform() : super(token: _token);

  static final Object _token = Object();

  static OnnxDartPlatform _instance = MethodChannelOnnxDart();

  /// The default instance of [OnnxDartPlatform] to use.
  ///
  /// Defaults to [MethodChannelOnnxDart].
  static OnnxDartPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OnnxDartPlatform] when
  /// they register themselves.
  static set instance(OnnxDartPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool?> init(
    String modelType,
    String modelPath, {
    int sessionsCount = 1,
  }) {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<bool?> release(String modelType) {
    throw UnimplementedError('release() has not been implemented.');
  }

  Future<Float32List?> predict(
    Float32List? inputData,
    Int32List? inputDataInt,
    Uint8List? inputDataRgba,
    String modelType, {
    int sessionAddress = 0,
    Int32List? inputShapeList,
  }) {
    throw UnimplementedError('predict() has not been implemented.');
  }
}
