import "package:computer/computer.dart";
import "package:onnxruntime/onnxruntime.dart";

class ONNXEnv {
  final Set<String> _loadedModels = {};

  final _computer = Computer.shared();

  // Singleton pattern
  ONNXEnv._privateConstructor();
  static final instance = ONNXEnv._privateConstructor();
  factory ONNXEnv() => instance;

  Future<void> initONNX(String modelName) async {
    if (_loadedModels.isEmpty) {
      await _computer.compute(() => OrtEnv.instance.init());
    }
    _loadedModels.add(modelName);
  }

  Future<void> releaseONNX(String modelName) async {
    _loadedModels.remove(modelName);
    if (_loadedModels.isEmpty) {
      await _computer.compute(() => OrtEnv.instance.release());
    }
  }

  bool isInit() {
    return _loadedModels.isNotEmpty;
  }
}
