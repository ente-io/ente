import "dart:io" show File;

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:onnx_dart/onnx_dart.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/onnx_env.dart";
import "package:photos/services/remote_assets_service.dart";

abstract class MlModel {
  Logger get logger;

  String get kModelBucketEndpoint => "https://models.ente.io/";

  String get modelRemotePath;

  String get modelName;

  // isInitialized is used to check if the model is loaded by the ffi based
  // plugin
  bool isInitialized = false;

  bool isNativePluginInitialized = false;
  int sessionAddress = 0;

  final computer = Computer.shared();

  // Initializes the model.
  // If `useEntePlugin` is set to true, the custom plugin is used for initialization.
  // Note: The custom plugin requires a dedicated isolate for loading the model to ensure thread safety and performance isolation.
  // In contrast, the current FFI-based plugin leverages the session memory address for session management, which does not require a dedicated isolate.
  Future<void> loadModel({bool useEntePlugin = false}) async {
    final model = await RemoteAssetsService.instance.getAsset(modelRemotePath);
    if (useEntePlugin) {
      await _loadModelWithEntePlugin(modelName, model.path);
    } else {
      await _loadModelWithFFI(modelName, model.path);
    }
  }

  Future<void> downloadModel() async {
    await RemoteAssetsService.instance.getAssetIfUpdated(modelRemotePath);
  }

  Future<void> _loadModelWithEntePlugin(
    String modelName,
    String modelPath,
  ) async {
    if (!isNativePluginInitialized) {
      final startTime = DateTime.now();
      logger.info('Initializing $modelName with EntePlugin');
      final OnnxDart plugin = OnnxDart();
      final bool? initResult = await plugin.init(modelName, modelPath);
      isNativePluginInitialized = initResult ?? false;
      if (isNativePluginInitialized) {
        final endTime = DateTime.now();
        logger.info(
          "$modelName loaded via EntePlugin ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
        );
      } else {
        logger.severe("Failed to initialize $modelName with EntePlugin.");
      }
    } else {
      logger.info("$modelName already initialized with Ente Plugin.");
    }
  }

  Future<void> _loadModelWithFFI(String modelName, String modelPath) async {
    if (!isInitialized) {
      logger.info('Initializing $modelName with FFI');
      final startTime = DateTime.now();
      sessionAddress = await computer.compute(
        _loadModel,
        param: {
          "modelPath": modelPath,
        },
      );
      isInitialized = true;
      final endTime = DateTime.now();
      logger.info(
        "$modelName loaded with FFI, took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
      );
    } else {
      logger.info("$modelName already initialized with FFI.");
    }
  }

  Future<void> release() async {
    if (isInitialized) {
      await computer.compute(_releaseModel, param: {'address': sessionAddress});
      await ONNXEnv.instance.releaseONNX(modelName);
      isInitialized = false;
      sessionAddress = 0;
    }
  }

  static Future<int> _loadModel(Map args) async {
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(1)
      ..setIntraOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    try {
      final session =
          OrtSession.fromFile(File(args["modelPath"]), sessionOptions);
      return session.address;
    } catch (e) {
      rethrow;
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
