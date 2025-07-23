import "dart:io" show File, Platform;

import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/onnx_env.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/network_util.dart";
import "package:synchronized/synchronized.dart";

abstract class MlModel {
  static final Logger isolateLogger = Logger("MlModel");
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
    isolateLogger
        .info('Start loading $modelName (platformPlugin: $usePlatformPlugin)');
    final time = DateTime.now();
    try {
      late int result;
      if (usePlatformPlugin) {
        result = await _loadModelWithPlatformPlugin(modelName, modelPath);
      } else {
        result = await _loadModelWithFFI(modelName, modelPath);
      }
      final timeMs = DateTime.now().difference(time).inMilliseconds;
      isolateLogger.info(
        "$modelName model loaded in $timeMs ms (platformPlugin: $usePlatformPlugin)",
      );
      return result;
    } catch (e, s) {
      isolateLogger.severe(
        "Failed to load model $modelName (platformPlugin: $usePlatformPlugin)",
        e,
        s,
      );
      rethrow;
    }
  }

  static Future<int> _loadModelWithPlatformPlugin(
    String modelName,
    String modelPath,
  ) async {
    final OnnxDart plugin = OnnxDart();
    final String? ortVersionString = await plugin.getPlatformVersion();
    final bool? initResult = await plugin.init(modelName, modelPath);
    if (initResult == null || !initResult) {
      isolateLogger.severe("Failed to initialize $modelName with EntePlugin.");
      throw Exception("Failed to initialize $modelName with EntePlugin.");
    }
    isolateLogger.info("Initialized $modelName on $ortVersionString");
    return 0;
  }

  static Future<int> _loadModelWithFFI(
    String modelName,
    String modelPath,
  ) async {
    ONNXEnvFFI.instance.initONNX(modelName);
    try {
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(1)
        ..setIntraOpNumThreads(1)
        ..setSessionGraphOptimizationLevel(
          GraphOptimizationLevel.ortEnableAll,
        );
      final session = OrtSession.fromFile(File(modelPath), sessionOptions);
      return session.address;
    } catch (e, s) {
      isolateLogger.severe("Failed to load model $modelName with FFI", e, s);
      rethrow;
    }
  }

  static Future<void> releaseModel(String modelName, int sessionAddress) async {
    try {
      if (usePlatformPlugin) {
        await _releaseModelWithPlatformPlugin(modelName);
      } else {
        await _releaseModelWithFFI(modelName, sessionAddress);
      }
    } catch (e, s) {
      isolateLogger.severe(
        "Failed to release model $modelName (platformPlugin: $usePlatformPlugin)",
        e,
        s,
      );
    }
  }

  static Future<void> _releaseModelWithPlatformPlugin(String modelName) async {
    final OnnxDart plugin = OnnxDart();
    final bool? initResult = await plugin.release(modelName);
    if (initResult == null || !initResult) {
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
