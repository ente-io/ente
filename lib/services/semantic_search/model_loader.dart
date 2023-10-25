import "dart:io";

import "package:clip_ggml/clip_ggml.dart";
import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";

class ModelLoader {
  ModelLoader._privateConstructor();

  static final ModelLoader instance = ModelLoader._privateConstructor();
  static final _logger = Logger("ModelLoader");

  static const kModelBucketEndpoint = "https://models.ente.io/";
  static const kImageModel = "clip-vit-base-patch32_ggml-vision-model-f16.gguf";
  static const kTextModel = "clip-vit-base-patch32_ggml-text-model-f16.gguf";

  late Computer _computer;

  Future<void> init(Computer computer) async {
    _computer = computer;
  }

  Future<bool> _hasImageModel() async {
    return File(await _getImageModelPath()).existsSync();
  }

  Future<bool> _hasTextModel() async {
    return File(await _getTextModelPath()).existsSync();
  }

  Future<void> loadImageModel() async {
    if (await _hasImageModel()) {
      await _loadImageModel();
    } else {
      final imageModelPath = await _getImageModelPath();
      final tempFile = File(imageModelPath + ".temp");
      await _downloadFile(kModelBucketEndpoint + kImageModel, tempFile.path);
      await tempFile.rename(imageModelPath);
      await _loadImageModel();
    }
  }

  Future<void> loadTextModel() async {
    if (await _hasTextModel()) {
      await _loadTextModel();
    } else {
      final textModelPath = await _getTextModelPath();
      final tempFile = File(textModelPath + ".temp");
      await _downloadFile(kModelBucketEndpoint + kTextModel, tempFile.path);
      await tempFile.rename(textModelPath);
      await _loadTextModel();
    }
  }

  Future<String> _getImageModelPath() async {
    return (await getTemporaryDirectory()).path + "/models/" + kImageModel;
  }

  Future<String> _getTextModelPath() async {
    return (await getTemporaryDirectory()).path + "/models/" + kTextModel;
  }

  Future<void> _loadImageModel() async {
    final startTime = DateTime.now();
    await _computer.compute(
      loadModel,
      param: {
        "imageModelPath": await _getImageModelPath(),
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading image model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  Future<void> _loadTextModel() async {
    final startTime = DateTime.now();
    await _computer.compute(
      loadModel,
      param: {
        "textModelPath": await _getTextModelPath(),
      },
    );
    final endTime = DateTime.now();
    _logger.info(
      "Loading text model took: ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).toString()}ms",
    );
  }

  Future<void> _downloadFile(String url, String savePath) async {
    _logger.info("Downloading " + url);
    final existingFile = File(savePath);
    if (await existingFile.exists()) {
      await existingFile.delete();
    }
    await NetworkClient.instance.getDio().download(url, savePath);
  }
}

void loadModel(Map args) {
  if (args["imageModelPath"] != null) {
    CLIP.loadImageModel(args["imageModelPath"]);
  } else if (args["textModelPath"] != null) {
    CLIP.loadTextModel(args["textModelPath"]);
  }
}
