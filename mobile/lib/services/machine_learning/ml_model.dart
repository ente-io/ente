import "dart:io" show File, Platform;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/onnx_env.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/network_util.dart";
import "package:synchronized/synchronized.dart";

abstract class MlModel {
  static final Logger isolateLogger = Logger("MlModelInIsolate");
  Logger get logger;

  String get kModelBucketEndpoint => "https://models.ente.io/";

  String get modelRemotePath;

  String get modelName;

  final _downloadModelLock = Lock();

  static final bool usePlatformPlugin = Platform.isAndroid;

  bool get isInitialized =>
      usePlatformPlugin ? _isNativePluginInitialized : _isFfiInitialized;
  int get sessionAddress =>
      usePlatformPlugin ? _nativePluginSessionIndex : _ffiSessionAddress;

  bool _isFfiInitialized = false;
  int _ffiSessionAddress = -1;

  bool _isNativePluginInitialized = false;
  int _nativePluginSessionIndex = -1;

  /// WARNING: If [downloadModel] was not first called, this method will download the model first using high bandwidth.
  Future<(String, String)> getModelNameAndPath() async {
    return _downloadModelLock.synchronized(() async {
      final path =
          await RemoteAssetsService.instance.getAssetPath(modelRemotePath);
      return (modelName, path);
    });
  }

  Future<String?> downloadModelSafe() async {
    if (await RemoteAssetsService.instance.hasAsset(modelRemotePath)) {
      return await RemoteAssetsService.instance.getAssetPath(modelRemotePath);
    } else {
      if (await canUseHighBandwidth()) {
        return await downloadModel();
      } else {
        logger.warning(
          'Cannot return model path as it is not available locally and high bandwidth is not available.',
        );
        return null;
      }
    }
  }

  Future<String> downloadModel([bool forceRefresh = false]) async {
    return _downloadModelLock.synchronized(() async {
      if (forceRefresh) {
        final file = await RemoteAssetsService.instance
            .getAssetIfUpdated(modelRemotePath);
        return file!.path;
      } else {
        return await RemoteAssetsService.instance.getAssetPath(modelRemotePath);
      }
    });
  }

  void storeSessionAddress(int address) {
    if (usePlatformPlugin) {
      _nativePluginSessionIndex = address;
      _isNativePluginInitialized = true;
    } else {
      _ffiSessionAddress = address;
      _isFfiInitialized = true;
    }
  }

  void releaseSessionAddress() {
    if (usePlatformPlugin) {
      _nativePluginSessionIndex = -1;
      _isNativePluginInitialized = false;
    } else {
      _ffiSessionAddress = -1;
      _isFfiInitialized = false;
    }
  }

  // Note: The platform plugin requires a dedicated isolate for loading the model to ensure thread safety and performance isolation.
  // In contrast, the current FFI-based plugin leverages the session memory address for session management, which does not require a dedicated isolate.
  static Future<int> loadModel(
    String modelName,
    String modelPath,
  ) async {
    if (usePlatformPlugin) {
      return await _loadModelWithPlatformPlugin(modelName, modelPath);
    } else {
      return await _loadModelWithFFI(modelName, modelPath);
    }
  }

  static Future<int> _loadModelWithPlatformPlugin(
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
    ONNXEnvFFI.instance.initONNX(modelName);
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

  static Future<void> releaseModel(String modelName, int sessionAddress) async {
    if (usePlatformPlugin) {
      await _releaseModelWithPlatformPlugin(modelName);
    } else {
      await _releaseModelWithFFI(modelName, sessionAddress);
    }
  }

  static Future<void> _releaseModelWithPlatformPlugin(String modelName) async {
    final OnnxDart plugin = OnnxDart();
    final bool? initResult = await plugin.release(modelName);
    if (initResult == null || !initResult) {
      isolateLogger.severe("Failed to release $modelName with PlatformPlugin.");
      throw Exception("Failed to release $modelName with PlatformPlugin.");
    }
  }

  static Future<void> _releaseModelWithFFI(
    String modelName,
    int sessionAddress,
  ) async {
    if (sessionAddress == 0 || sessionAddress == -1) {
      return;
    }
    final session = OrtSession.fromAddress(sessionAddress);
    session.release();
    ONNXEnvFFI.instance.releaseONNX(modelName);
    return;
  }
}
