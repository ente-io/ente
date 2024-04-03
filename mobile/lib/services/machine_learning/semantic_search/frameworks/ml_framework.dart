import "dart:async";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:logging/logging.dart";
import "package:photos/core/errors.dart";

import "package:photos/core/event_bus.dart";
import "package:photos/events/event.dart";
import "package:photos/services/remote_assets_service.dart";

abstract class MLFramework {
  static const kImageEncoderEnabled = true;
  static const kMaximumRetrials = 3;

  static final _logger = Logger("MLFramework");

  final bool shouldDownloadOverMobileData;
  final _initializationCompleter = Completer<void>();

  InitializationState _state = InitializationState.notInitialized;

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
      _initState = InitializationState.initializing;
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
    final imageModel = await _getModel(getImageModelRemotePath());
    await loadImageModel(imageModel.path);
  }

  Future<void> _initTextModel() async {
    final textModel = await _getModel(getTextModelRemotePath());
    await loadTextModel(textModel.path);
  }

  Future<File> _getModel(
    String url, {
    int trialCount = 1,
  }) async {
    if (await RemoteAssetsService.instance.hasAsset(url)) {
      return RemoteAssetsService.instance.getAsset(url);
    }
    if (!await _canDownload()) {
      _initState = InitializationState.waitingForNetwork;
      throw WiFiUnavailableError();
    }
    try {
      return RemoteAssetsService.instance.getAsset(url);
    } catch (e, s) {
      _logger.severe(e, s);
      if (trialCount < kMaximumRetrials) {
        return _getModel(url, trialCount: trialCount + 1);
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
}

class MLFrameworkInitializationUpdateEvent extends Event {
  final InitializationState state;

  MLFrameworkInitializationUpdateEvent(this.state);
}

enum InitializationState {
  notInitialized,
  waitingForNetwork,
  initializing,
  initialized,
}
