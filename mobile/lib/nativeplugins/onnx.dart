import 'package:flutter/services.dart';

class OnnxFlutterPlugin {
  static const MethodChannel _channel =
      MethodChannel('ente_onnx_flutter_plugin');

  static Future<bool> init(
    String modelType,
    String modelPath, {
    int sessionsCount = 1,
  }) async {
    final bool result = await _channel.invokeMethod('init', {
      'modelType': modelType,
      'modelPath': modelPath,
      'sessionsCount': sessionsCount,
    });
    return result;
  }

  static Future<bool> release(String modelType) async {
    final bool result =
        await _channel.invokeMethod('release', {'modelType': modelType});
    return result;
  }

  static Future<List<double>> predict(
    List<double> inputData,
    String modelType, {
    int sessionAddress = 0,
  }) async {
    final List<dynamic> result = await _channel.invokeMethod(
      'predict',
      {
        'sessionAddress': sessionAddress,
        'inputData': inputData,
        'modelType': modelType,
      },
    );
    return result.cast<double>();
  }
}
