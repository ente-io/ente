import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:logging/logging.dart";
import "package:photos/service_locator.dart"
    show flagService, hasGrantedMLConsent, isLocalGalleryMode, localSettings;
import "package:photos/services/machine_learning/ml_models_overview.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/network_util.dart";
import "package:synchronized/synchronized.dart";

class MLModelDownloadService {
  final _logger = Logger("MLModelDownloadService");

  final _downloadModelLock = Lock();

  bool _areIndexingModelsDownloaded = false;
  bool _areNonIndexingModelsDownloaded = false;
  bool _retryOnlyIndexingModels = true;

  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? _modelDownloadRetrySubscription;

  MLModelDownloadService._privateConstructor();
  static final instance = MLModelDownloadService._privateConstructor();
  factory MLModelDownloadService() => instance;

  bool get areIndexingModelsDownloaded => _areIndexingModelsDownloaded;

  bool areModelsDownloaded({required bool onlyIndexingModels}) {
    return _areIndexingModelsDownloaded &&
        (onlyIndexingModels || _areNonIndexingModelsDownloaded);
  }

  /// Invalidate the download cache so the next ML run re-enters
  /// [ensureModelsDownloaded], which checks consent, local indexing, bandwidth,
  /// and downloads any newly required models.
  void invalidateModelDownloadCache({bool includeNonIndexingModels = false}) {
    _areIndexingModelsDownloaded = false;
    if (includeNonIndexingModels) {
      _areNonIndexingModelsDownloaded = false;
    }
  }

  void triggerModelsDownload({required bool onlyIndexingModels}) {
    if (!areModelsDownloaded(onlyIndexingModels: onlyIndexingModels) &&
        !_downloadModelLock.locked) {
      _logger.info(
        onlyIndexingModels
            ? "Indexing models not downloaded, starting download"
            : "ML models not downloaded, starting download",
      );
      unawaited(
        ensureModelsDownloaded(onlyIndexingModels: onlyIndexingModels),
      );
    }
  }

  Future<void> ensureModelsDownloaded({
    required bool onlyIndexingModels,
    bool forceRefresh = false,
  }) async {
    if (_downloadModelLock.locked) {
      _logger.info("Download models already in progress");
      return;
    }
    return _downloadModelLock.synchronized(() async {
      if (!forceRefresh &&
          areModelsDownloaded(onlyIndexingModels: onlyIndexingModels)) {
        return;
      }
      if (!hasGrantedMLConsent) {
        _logger.info("Skipping ML model download because ML consent is off");
        await _cancelModelDownloadRetry();
        return;
      }
      if (!localSettings.isMLLocalIndexingEnabled) {
        _logger.info(
          "Skipping ML model download because local indexing is disabled",
        );
        await _cancelModelDownloadRetry();
        return;
      }
      final goodInternet = isLocalGalleryMode || await canUseHighBandwidth();
      if (!goodInternet) {
        _logger.info(
          "Cannot download models because user is not connected to wifi and is in enteGallery mode",
        );
        return;
      }

      final modelsToDownload = <Future<void>>[];
      if (forceRefresh || !_areIndexingModelsDownloaded) {
        modelsToDownload.addAll(_indexingModelDownloads(forceRefresh));
      }
      if (!onlyIndexingModels &&
          (forceRefresh || !_areNonIndexingModelsDownloaded)) {
        modelsToDownload.addAll(_nonIndexingModelDownloads(forceRefresh));
      }
      if (modelsToDownload.isEmpty) {
        return;
      }

      _logger.info(
        onlyIndexingModels
            ? "Downloading indexing ML models"
            : "Downloading all ML models",
      );
      try {
        await Future.wait(modelsToDownload);
      } catch (e, s) {
        _logger.warning(
          "ML model download failed, will retry when high bandwidth "
          "connectivity is available",
          e,
          s,
        );
        _listenForHighBandwidthModelDownloadRetry(
          onlyIndexingModels: onlyIndexingModels,
        );
        rethrow;
      }
      if (forceRefresh || !_areIndexingModelsDownloaded) {
        _areIndexingModelsDownloaded = true;
      }
      if (!onlyIndexingModels) {
        _areNonIndexingModelsDownloaded = true;
      }
      await _cancelModelDownloadRetry();
      _logger.info(
        onlyIndexingModels
            ? "Downloaded indexing ML models"
            : "Downloaded all ML models",
      );
    });
  }

  List<Future<void>> _indexingModelDownloads(bool forceRefresh) {
    final models = <MLModels>[
      for (final model in MLModels.values)
        if (model.isIndexingModel && !_isPetModel(model)) model,
      if (_shouldDownloadPetModels) ..._petModels,
    ];
    return [
      for (final model in models) model.model.downloadModel(forceRefresh),
    ];
  }

  List<Future<void>> _nonIndexingModelDownloads(bool forceRefresh) {
    return [
      for (final model in MLModels.values)
        if (!model.isIndexingModel) model.model.downloadModel(forceRefresh),
      RemoteAssetsService.instance.getAssetPath(
        ClipTextEncoder.instance.vocabRemotePath,
        refetch: forceRefresh,
      ),
    ];
  }

  bool get _shouldDownloadPetModels {
    return flagService.petEnabled &&
        localSettings.petRecognitionEnabled &&
        (flagService.useRustForML || isLocalGalleryMode);
  }

  bool _isPetModel(MLModels model) {
    return _petModels.contains(model);
  }

  void _listenForHighBandwidthModelDownloadRetry({
    required bool onlyIndexingModels,
  }) {
    if (!onlyIndexingModels) {
      _retryOnlyIndexingModels = false;
    }
    if (_modelDownloadRetrySubscription != null) {
      return;
    }
    _retryOnlyIndexingModels = onlyIndexingModels;
    _logger.info(
      "Listening for high bandwidth connectivity to retry ML model download",
    );
    _modelDownloadRetrySubscription =
        Connectivity().onConnectivityChanged.listen(
      (connections) {
        unawaited(_retryModelDownloadIfHighBandwidth(connections));
      },
      onError: (Object e, StackTrace s) {
        _logger.warning(
          "Connectivity listener for ML model download retry failed",
          e,
          s,
        );
      },
    );
  }

  Future<void> _retryModelDownloadIfHighBandwidth(
    List<ConnectivityResult> connections,
  ) async {
    if (areModelsDownloaded(onlyIndexingModels: _retryOnlyIndexingModels)) {
      await _cancelModelDownloadRetry();
      return;
    }
    if (!hasGrantedMLConsent) {
      _logger.info(
        "Stopping ML model download retry because ML consent is off",
      );
      await _cancelModelDownloadRetry();
      return;
    }
    if (!localSettings.isMLLocalIndexingEnabled) {
      _logger.info(
        "Stopping ML model download retry because local indexing is disabled",
      );
      await _cancelModelDownloadRetry();
      return;
    }
    if (!(isLocalGalleryMode || await canUseHighBandwidth())) {
      _logger.info(
        "ML model download retry waiting for high bandwidth connectivity: "
        "$connections",
      );
      return;
    }
    _logger.info(
      "High bandwidth connectivity available, retrying ML model download",
    );
    final onlyIndexingModels = _retryOnlyIndexingModels;
    await _cancelModelDownloadRetry();
    triggerModelsDownload(onlyIndexingModels: onlyIndexingModels);
  }

  Future<void> _cancelModelDownloadRetry() async {
    final subscription = _modelDownloadRetrySubscription;
    if (subscription == null) {
      return;
    }
    _modelDownloadRetrySubscription = null;
    _retryOnlyIndexingModels = true;
    await subscription.cancel();
  }
}

const _petModels = <MLModels>[
  MLModels.petFaceDetection,
  MLModels.petFaceEmbeddingDog,
  MLModels.petFaceEmbeddingCat,
  MLModels.petBodyDetection,
  MLModels.petBodyEmbeddingDog,
  MLModels.petBodyEmbeddingCat,
];
