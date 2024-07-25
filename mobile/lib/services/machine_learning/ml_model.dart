import "dart:io" show File, Platform;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/onnx_env.dart";
import "package:photos/services/remote_assets_service.dart";

abstract class MlModel {
  static final Logger isolateLogger = Logger("MlModelInIsolate");
  Logger get logger;

  String get kModelBucketEndpoint => "https://models.ente.io/";

  String get modelRemotePath;

  String get modelName;

  bool get isInitialized =>
      Platform.isAndroid ? isNativePluginInitialized : isFfiInitialized;
  int get sessionAddress =>
      Platform.isAndroid ? _nativePluginSessionIndex : _ffiSessionAddress;

  // isInitialized is used to check if the model is loaded by the ffi based
  // plugin
  bool isFfiInitialized = false;
  int _ffiSessionAddress = -1;

  bool isNativePluginInitialized = false;
  int _nativePluginSessionIndex = -1;

  Future<(String, String)> getModelNameAndPath() async {
    final path =
        await RemoteAssetsService.instance.getAssetPath(modelRemotePath);
    return (modelName, path);
  }

  void storeSessionAddress(int address) {
    if (Platform.isAndroid) {
      _nativePluginSessionIndex = address;
      isNativePluginInitialized = true;
    } else {
      _ffiSessionAddress = address;
      isFfiInitialized = true;
    }
  }

  // Initializes the model.
  // If `useEntePlugin` is set to true, the custom plugin is used for initialization.
  // Note: The custom plugin requires a dedicated isolate for loading the model to ensure thread safety and performance isolation.
  // In contrast, the current FFI-based plugin leverages the session memory address for session management, which does not require a dedicated isolate.
  static Future<int> loadModel(
    String modelName,
    String modelPath,
  ) async {
    if (Platform.isAndroid) {
      return await _loadModelWithEntePlugin(modelName, modelPath);
    } else {
      return await _loadModelWithFFI(modelName, modelPath);
    }
  }

  static Future<int> _loadModelWithEntePlugin(
    String modelName,
    String modelPath,
  ) async {
    final startTime = DateTime.now();
    isolateLogger.info('Initializing $modelName with EntePlugin');
    final OnnxDart plugin = OnnxDart();
    final bool? initResult = await plugin.init(modelName, modelPath);
    if (initResult == null || !initResult) {
      isolateLogger.severe("Failed to initialize $modelName with EntePlugin.");
      throw Exception("Failed to initialize $modelName with EntePlugin.");
    }
    final endTime = DateTime.now();
    isolateLogger.info(
      "$modelName loaded via EntePlugin in ${endTime.difference(startTime).inMilliseconds}ms",
    );
    return 0;
  }

  static Future<int> _loadModelWithFFI(
    String modelName,
    String modelPath,
  ) async {
    isolateLogger.info('Initializing $modelName with FFI');
    try {
      final startTime = DateTime.now();
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(1)
        ..setIntraOpNumThreads(1)
        ..setSessionGraphOptimizationLevel(
          GraphOptimizationLevel.ortEnableAll,
        );
      final session = OrtSession.fromFile(File(modelPath), sessionOptions);
      final endTime = DateTime.now();
      isolateLogger.info(
        "$modelName loaded with FFI, took: ${endTime.difference(startTime).inMilliseconds}ms",
      );
      return session.address;
    } catch (e) {
      rethrow;
    }
  }

  // TODO: add release method for native plugin
  Future<void> release() async {
    if (isFfiInitialized) {
      await _releaseModel({'address': _ffiSessionAddress});
      await ONNXEnv.instance.releaseONNX(modelName);
      isFfiInitialized = false;
      _ffiSessionAddress = 0;
    }
  }

  static Future<void> _releaseModel(Map args) async {
    final address = args['address'] as int;
    if (address == 0) {
      return;
    }
    final session = OrtSession.fromAddress(address);
    session.release();
    return;
  }
}
