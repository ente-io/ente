import "dart:io" show File;

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:onnxruntime/onnxruntime.dart";
import "package:photos/services/machine_learning/onnx_env.dart";
import "package:photos/services/remote_assets_service.dart";

abstract class MlModel {
  Logger get logger;

  String get kModelBucketEndpoint => "https://models.ente.io/";

  String get modelRemotePath;

  String get modelName;

  bool isInitialized = false;
  int sessionAddress = 0;

  final computer = Computer.shared();

  Future<void> init() async {
    if (!isInitialized) {
      logger.info('init is called');
      final model =
          await RemoteAssetsService.instance.getAsset(modelRemotePath);
      final startTime = DateTime.now();
      try {
        sessionAddress = await computer.compute(
          _loadModel,
          param: {
            "modelPath": model.path,
          },
        );
        await ONNXEnv.instance.initONNX(modelName);
        isInitialized = true;
        final endTime = DateTime.now();
        logger.info(
          "model loaded, took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
        );
      } catch (e, s) {
        logger.severe('model not loaded', e, s);
      }
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
