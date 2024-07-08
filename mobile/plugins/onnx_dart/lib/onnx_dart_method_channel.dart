import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onnx_dart_platform_interface.dart';

/// An implementation of [OnnxDartPlatform] that uses method channels.
class MethodChannelOnnxDart extends OnnxDartPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('onnx_dart');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> init(
    String modelType,
    String modelPath, {
    int sessionsCount = 1,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('init', {
      'modelType': modelType,
      'modelPath': modelPath,
      'sessionsCount': sessionsCount,
    });
    return result;
  }

  @override
  Future<bool?> release(String modelType) async {
    final bool? result = await methodChannel
        .invokeMethod<bool>('release', {'modelType': modelType});
    return result;
  }

  // @override
  // Future<List<double>?> predict(
  //   List<double> inputData,
  //   String modelType, {
  //   int sessionAddress = 0,
  // }) async {
  //   final List<dynamic>? result =
  //       await methodChannel.invokeMethod<List<double>?>(
  //     'predict',
  //     {
  //       'sessionAddress': sessionAddress,
  //       'inputData': inputData,
  //       'modelType': modelType,
  //     },
  //   );
  //   return result!.cast<double>();
  // }

  @override
  Future<dynamic?> predict(
    Float32List inputData,
    String modelType, {
    int sessionAddress = 0,
  }) {
    return methodChannel.invokeMethod<dynamic?>(
      'predict',
      {
        'sessionAddress': sessionAddress,
        'inputData': inputData,
        'modelType': modelType,
      },
    );
  }
}
