import 'dart:async';
import 'dart:typed_data' show Uint8List;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/services/isolate_functions.dart";
import "package:photos/services/isolate_service.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:synchronized/synchronized.dart";

class MLComputer extends SuperIsolate {
  @override
  Logger get logger => _logger;
  final _logger = Logger('MLComputer');

  final _initModelLock = Lock();

  @override
  bool get isDartUiIsolate => true;

  @override
  String get isolateName => "MLComputerIsolate";

  @override
  bool get shouldAutomaticDispose => false;

  @override
  Future<void> onDispose() async => {};

  // Singleton pattern
  MLComputer._privateConstructor();
  static final MLComputer instance = MLComputer._privateConstructor();
  factory MLComputer() => instance;

  /// Generates face thumbnails for all [faceBoxes] in [imageData].
  ///
  /// Uses [generateFaceThumbnailsUsingCanvas] inside the isolate.
  Future<List<Uint8List>> generateFaceThumbnails(
    String imagePath,
    List<FaceBox> faceBoxes,
  ) async {
    final List<Map<String, dynamic>> faceBoxesJson =
        faceBoxes.map((box) => box.toJson()).toList();
    return await runInIsolate(
      IsolateOperation.generateFaceThumbnails,
      {
        'imagePath': imagePath,
        'faceBoxesList': faceBoxesJson,
      },
    ).then((value) => value.cast<Uint8List>());
  }

  Future<List<double>> runClipText(String query) async {
    try {
      await _ensureLoadedClipTextModel();
      final int clipAddress = ClipTextEncoder.instance.sessionAddress;
      final textEmbedding = await runInIsolate(IsolateOperation.runClipText, {
        "text": query,
        "address": clipAddress,
      }) as List<double>;
      return textEmbedding;
    } catch (e, s) {
      _logger.severe("Could not run clip text in isolate", e, s);
      rethrow;
    }
  }

  Future<void> _ensureLoadedClipTextModel() async {
    return _initModelLock.synchronized(() async {
      if (ClipTextEncoder.instance.isInitialized) return;
      try {
        // Initialize ClipText tokenizer
        final String tokenizerRemotePath =
            ClipTextEncoder.instance.vocabRemotePath;
        final String tokenizerVocabPath = await RemoteAssetsService.instance
            .getAssetPath(tokenizerRemotePath);
        await runInIsolate(
          IsolateOperation.initializeClipTokenizer,
          {'vocabPath': tokenizerVocabPath},
        );

        // Load ClipText model
        final String modelName = ClipTextEncoder.instance.modelName;
        final String? modelPath =
            await ClipTextEncoder.instance.downloadModelSafe();
        if (modelPath == null) {
          throw Exception("Could not download clip text model, no wifi");
        }
        final address = await runInIsolate(
          IsolateOperation.loadModel,
          {
            'modelName': modelName,
            'modelPath': modelPath,
          },
        ) as int;
        ClipTextEncoder.instance.storeSessionAddress(address);
      } catch (e, s) {
        _logger.severe("Could not load clip text model in MLComputer", e, s);
        rethrow;
      }
    });
  }

  Future<bool> testLogging() async {
    try {
      final result =
          await runInIsolate(IsolateOperation.testLogging, {}) as bool;
      return result;
    } catch (e, s) {
      _logger.severe("XXX Could not test logging in isolate", e, s);
      rethrow;
    }
  }
}
