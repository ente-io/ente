import "dart:async";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/errors.dart";

import "package:photos/core/event_bus.dart";
import "package:photos/core/network/network.dart";
import "package:photos/events/event.dart";

abstract class MLFramework {
  static const kImageEncoderEnabled = true;
  static const kMaximumRetrials = 3;

  static final _logger = Logger("MLFramework");

  final bool shouldDownloadOverMobileData;

  InitializationState _state = InitializationState.notInitialized;
  final _initializationCompleter = Completer<void>();

  MLFramework(this.shouldDownloadOverMobileData) {
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      _logger.info("Connectivity changed to $result");
      if (_state == InitializationState.waitingForNetwork &&
          await _canDownload()) {
        unawaited(init());
      }
    });
  }

  InitializationState get initializationState => _state;

  set _initState(InitializationState state) {
    Bus.instance.fire(MLFrameworkInitializationUpdateEvent(state));
    _logger.info("Init state is $state");
    _state = state;
  }

  /// Returns the path of the Image Model hosted remotely
  String getImageModelRemotePath();

  /// Returns the path of the Text Model hosted remotely
  String getTextModelRemotePath();

  /// Loads the Image Model stored at [path] into the framework
  Future<void> loadImageModel(String path);

  /// Loads the Text Model stored at [path] into the framework
  Future<void> loadTextModel(String path);

  /// Returns the Image Embedding for a file stored at [imagePath]
  Future<List<double>> getImageEmbedding(String imagePath);

  /// Returns the Text Embedding for [text]
  Future<List<double>> getTextEmbedding(String text);

  /// Downloads the models from remote, caches them and loads them into the
  /// framework. Override this method if you would like to control the
  /// initialization. For eg. if you wish to load the model from `/assets`
  /// instead of a CDN.
  Future<void> init() async {
    try {
      await Future.wait([_initImageModel(), _initTextModel()]);
    } catch (e, s) {
      _logger.warning(e, s);
      if (e is WiFiUnavailableError) {
        return _initializationCompleter.future;
      } else {
        rethrow;
      }
    }
    _initState = InitializationState.initialized;
    _initializationCompleter.complete();
  }

  // Releases any resources held by the framework
  Future<void> release() async {}

  /// Returns the cosine similarity between [imageEmbedding] and [textEmbedding]
  double computeScore(List<double> imageEmbedding, List<double> textEmbedding) {
    assert(
      imageEmbedding.length == textEmbedding.length,
      "The two embeddings should have the same length",
    );
    double score = 0;
    for (int index = 0; index < imageEmbedding.length; index++) {
      score += imageEmbedding[index] * textEmbedding[index];
    }
    return score;
  }

  // ---
  // Private methods
  // ---

  Future<void> _initImageModel() async {
    if (!kImageEncoderEnabled) {
      return;
    }
    _initState = InitializationState.initializingImageModel;
    final path = await _getLocalImageModelPath();
    if (await File(path).exists()) {
      await loadImageModel(path);
    } else {
      _initState = InitializationState.downloadingImageModel;
      final tempFile = File(path + ".temp");
      await _downloadFile(getImageModelRemotePath(), tempFile.path);
      await tempFile.rename(path);
      await loadImageModel(path);
    }
    _initState = InitializationState.initializedImageModel;
  }

  Future<void> _initTextModel() async {
    final path = await _getLocalTextModelPath();
    _initState = InitializationState.initializingTextModel;
    if (await File(path).exists()) {
      await loadTextModel(path);
    } else {
      _initState = InitializationState.downloadingTextModel;
      final tempFile = File(path + ".temp");
      await _downloadFile(getTextModelRemotePath(), tempFile.path);
      await tempFile.rename(path);
      await loadTextModel(path);
    }
    _initState = InitializationState.initializedTextModel;
  }

  Future<String> _getLocalImageModelPath() async {
    return (await getTemporaryDirectory()).path +
        "/models/" +
        basename(getImageModelRemotePath());
  }

  Future<String> _getLocalTextModelPath() async {
    return (await getTemporaryDirectory()).path +
        "/models/" +
        basename(getTextModelRemotePath());
  }

  Future<void> _downloadFile(
    String url,
    String savePath, {
    int trialCount = 1,
  }) async {
    if (!await _canDownload()) {
      _initState = InitializationState.waitingForNetwork;
      throw WiFiUnavailableError();
    }
    _logger.info("Downloading " + url);
    final existingFile = File(savePath);
    if (await existingFile.exists()) {
      await existingFile.delete();
    }
    try {
      await NetworkClient.instance.getDio().download(url, savePath);
    } catch (e, s) {
      _logger.severe(e, s);
      if (trialCount < kMaximumRetrials) {
        return _downloadFile(url, savePath, trialCount: trialCount + 1);
      } else {
        rethrow;
      }
    }
  }

  Future<bool> _canDownload() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.mobile ||
        shouldDownloadOverMobileData;
  }

  Future<String> getAccessiblePathForAsset(
    String assetPath,
    String tempName,
  ) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$tempName')
        .writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}

class MLFrameworkInitializationUpdateEvent extends Event {
  final InitializationState state;

  MLFrameworkInitializationUpdateEvent(this.state);
}

enum InitializationState {
  notInitialized,
  waitingForNetwork,
  downloadingImageModel,
  initializingImageModel,
  initializedImageModel,
  downloadingTextModel,
  initializingTextModel,
  initializedTextModel,
  initialized,
}
