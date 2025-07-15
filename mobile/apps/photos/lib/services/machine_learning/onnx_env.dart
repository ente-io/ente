import "package:onnxruntime/onnxruntime.dart";

class ONNXEnvFFI {
  final Set<String> _loadedModels = {};

  // Singleton pattern
  ONNXEnvFFI._privateConstructor();
  static final instance = ONNXEnvFFI._privateConstructor();
  factory ONNXEnvFFI() => instance;

  void initONNX(String modelName) {
    if (_loadedModels.isEmpty) {
      OrtEnv.instance.init();
    }
    _loadedModels.add(modelName);
  }

  void releaseONNX(String modelName) {
    _loadedModels.remove(modelName);
    if (_loadedModels.isEmpty) {
      OrtEnv.instance.release();
    }
  }

  bool isInit() {
    return _loadedModels.isNotEmpty;
  }
}
