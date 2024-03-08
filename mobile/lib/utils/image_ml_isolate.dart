import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data' show Float32List, Uint8List;
import 'dart:ui';

import 'package:flutter_isolate/flutter_isolate.dart';
import "package:logging/logging.dart";
import "package:photos/face/model/box.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import "package:photos/services/face_ml/face_alignment/alignment_result.dart";
import "package:photos/services/face_ml/face_detection/detection.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:synchronized/synchronized.dart";

enum ImageOperation {
  preprocessBlazeFace,
  preprocessYoloOnnx,
  preprocessFaceAlign,
  preprocessMobileFaceNet,
  preprocessMobileFaceNetOnnx,
  generateFaceThumbnail,
  generateFaceThumbnailsForImage,
  cropAndPadFace,
}

/// The isolate below uses functions from ["package:photos/utils/image_ml_util.dart"] to preprocess images for ML models.

/// This class is responsible for all image operations needed for ML models. It runs in a separate isolate to avoid jank.
///
/// It can be accessed through the singleton `ImageConversionIsolate.instance`. e.g. `ImageConversionIsolate.instance.convert(imageData)`
///
/// IMPORTANT: Make sure to dispose of the isolate when you're done with it with `dispose()`, e.g. `ImageConversionIsolate.instance.dispose();`
class ImageMlIsolate {
  // static const String debugName = 'ImageMlIsolate';

  final _logger = Logger('ImageMlIsolate');

  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 60);
  int _activeTasks = 0;

  final _initLock = Lock();
  final _functionLock = Lock();

  late FlutterIsolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;

  // singleton pattern
  ImageMlIsolate._privateConstructor();

  /// Use this instance to access the ImageConversionIsolate service. Make sure to call `init()` before using it.
  /// e.g. `await ImageConversionIsolate.instance.init();`
  /// And kill the isolate when you're done with it with `dispose()`, e.g. `ImageConversionIsolate.instance.dispose();`
  ///
  /// Then you can use `convert()` to get the image, so `ImageConversionIsolate.instance.convert(imageData, imagePath: imagePath)`
  static final ImageMlIsolate instance = ImageMlIsolate._privateConstructor();
  factory ImageMlIsolate() => instance;

  Future<void> init() async {
    return _initLock.synchronized(() async {
      if (isSpawned) return;

      _receivePort = ReceivePort();

      try {
        _isolate = await FlutterIsolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        isSpawned = true;

        _resetInactivityTimer();
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        isSpawned = false;
      }
    });
  }

  Future<void> ensureSpawned() async {
    if (!isSpawned) {
      await init();
    }
  }

  @pragma('vm:entry-point')
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = ImageOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case ImageOperation.preprocessBlazeFace:
            final imageData = args['imageData'] as Uint8List;
            final normalize = args['normalize'] as bool;
            final int normalization = normalize ? 2 : -1;
            final requiredWidth = args['requiredWidth'] as int;
            final requiredHeight = args['requiredHeight'] as int;
            final qualityIndex = args['quality'] as int;
            final maintainAspectRatio = args['maintainAspectRatio'] as bool;
            final quality = FilterQuality.values[qualityIndex];
            final (result, originalSize, newSize) =
                await preprocessImageToMatrix(
              imageData,
              normalization: normalization,
              requiredWidth: requiredWidth,
              requiredHeight: requiredHeight,
              quality: quality,
              maintainAspectRatio: maintainAspectRatio,
            );
            sendPort.send({
              'inputs': result,
              'originalWidth': originalSize.width,
              'originalHeight': originalSize.height,
              'newWidth': newSize.width,
              'newHeight': newSize.height,
            });
          case ImageOperation.preprocessYoloOnnx:
            final imageData = args['imageData'] as Uint8List;
            final normalize = args['normalize'] as bool;
            final int normalization = normalize ? 1 : -1;
            final requiredWidth = args['requiredWidth'] as int;
            final requiredHeight = args['requiredHeight'] as int;
            final qualityIndex = args['quality'] as int;
            final maintainAspectRatio = args['maintainAspectRatio'] as bool;
            final quality = FilterQuality.values[qualityIndex];
            final (result, originalSize, newSize) =
                await preprocessImageToFloat32ChannelsFirst(
              imageData,
              normalization: normalization,
              requiredWidth: requiredWidth,
              requiredHeight: requiredHeight,
              quality: quality,
              maintainAspectRatio: maintainAspectRatio,
            );
            sendPort.send({
              'inputs': result,
              'originalWidth': originalSize.width,
              'originalHeight': originalSize.height,
              'newWidth': newSize.width,
              'newHeight': newSize.height,
            });
          case ImageOperation.preprocessFaceAlign:
            final imageData = args['imageData'] as Uint8List;
            final faceLandmarks =
                args['faceLandmarks'] as List<List<List<double>>>;
            final List<Uint8List> result = await preprocessFaceAlignToUint8List(
              imageData,
              faceLandmarks,
            );
            sendPort.send(List.from(result));
          case ImageOperation.preprocessMobileFaceNet:
            final imageData = args['imageData'] as Uint8List;
            final facesJson = args['facesJson'] as List<Map<String, dynamic>>;
            final (
              inputs,
              alignmentResults,
              isBlurs,
              blurValues,
              originalSize
            ) = await preprocessToMobileFaceNetInput(
              imageData,
              facesJson,
            );
            final List<Map<String, dynamic>> alignmentResultsJson =
                alignmentResults.map((result) => result.toJson()).toList();
            sendPort.send({
              'inputs': inputs,
              'alignmentResultsJson': alignmentResultsJson,
              'isBlurs': isBlurs,
              'blurValues': blurValues,
              'originalWidth': originalSize.width,
              'originalHeight': originalSize.height,
            });
          case ImageOperation.preprocessMobileFaceNetOnnx:
            final imagePath = args['imagePath'] as String;
            final facesJson = args['facesJson'] as List<Map<String, dynamic>>;
            final List<FaceDetectionRelative> relativeFaces = facesJson
                .map((face) => FaceDetectionRelative.fromJson(face))
                .toList();
            final (
              inputs,
              alignmentResults,
              isBlurs,
              blurValues,
              originalSize
            ) = await preprocessToMobileFaceNetFloat32List(
              imagePath,
              relativeFaces,
            );
            final List<Map<String, dynamic>> alignmentResultsJson =
                alignmentResults.map((result) => result.toJson()).toList();
            sendPort.send({
              'inputs': inputs,
              'alignmentResultsJson': alignmentResultsJson,
              'isBlurs': isBlurs,
              'blurValues': blurValues,
              'originalWidth': originalSize.width,
              'originalHeight': originalSize.height,
            });
          case ImageOperation.generateFaceThumbnail:
            final imageData = args['imageData'] as Uint8List;
            final faceDetectionJson =
                args['faceDetection'] as Map<String, dynamic>;
            final faceDetection =
                FaceDetectionRelative.fromJson(faceDetectionJson);
            final Uint8List result =
                await generateFaceThumbnailFromData(imageData, faceDetection);
            sendPort.send(<dynamic>[result]);
          case ImageOperation.generateFaceThumbnailsForImage:
            final imageData = args['imageData'] as Uint8List;
            final faceBoxesJson =
                args['faceBoxesList'] as List<Map<String, dynamic>>;
            final List<FaceBox> faceBoxes =
                faceBoxesJson.map((json) => FaceBox.fromJson(json)).toList();
            final List<Uint8List> results =
                await generateFaceThumbnailsFromDataAndDetections(
              imageData,
              faceBoxes,
            );
            sendPort.send(List.from(results));
          case ImageOperation.cropAndPadFace:
            final imageData = args['imageData'] as Uint8List;
            final faceBox = args['faceBox'] as List<double>;
            final Uint8List result =
                await cropAndPadFaceData(imageData, faceBox);
            sendPort.send(<dynamic>[result]);
        }
      } catch (e, stackTrace) {
        sendPort
            .send({'error': e.toString(), 'stackTrace': stackTrace.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (ImageOperation, Map<String, dynamic>) message,
  ) async {
    await ensureSpawned();
    return _functionLock.synchronized(() async {
      _resetInactivityTimer();
      final completer = Completer<dynamic>();
      final answerPort = ReceivePort();

      _activeTasks++;
      _mainSendPort.send([message.$1.index, message.$2, answerPort.sendPort]);

      answerPort.listen((receivedMessage) {
        if (receivedMessage is Map && receivedMessage.containsKey('error')) {
          // Handle the error
          final errorMessage = receivedMessage['error'];
          final errorStackTrace = receivedMessage['stackTrace'];
          final exception = Exception(errorMessage);
          final stackTrace = StackTrace.fromString(errorStackTrace);
          completer.completeError(exception, stackTrace);
        } else {
          completer.complete(receivedMessage);
        }
      });
      _activeTasks--;

      return completer.future;
    });
  }

  /// Resets a timer that kills the isolate after a certain amount of inactivity.
  ///
  /// Should be called after initialization (e.g. inside `init()`) and after every call to isolate (e.g. inside `_runInIsolate()`)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (_activeTasks > 0) {
        _logger.info('Tasks are still running. Delaying isolate disposal.');
        // Optionally, reschedule the timer to check again later.
        _resetInactivityTimer();
      } else {
        _logger.info(
        'Clustering Isolate has been inactive for ${_inactivityDuration.inSeconds} seconds with no tasks running. Killing isolate.',
      );
        dispose();
      }
    });
  }

  /// Disposes the isolate worker.
  void dispose() {
    if (!isSpawned) return;

    isSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  /// Preprocesses [imageData] for standard ML models inside a separate isolate.
  ///
  /// Returns a [Num3DInputMatrix] image usable for ML inference with BlazeFace.
  ///
  /// Uses [preprocessImageToMatrix] inside the isolate.
  Future<(Num3DInputMatrix, Size, Size)> preprocessImageBlazeFace(
    Uint8List imageData, {
    required bool normalize,
    required int requiredWidth,
    required int requiredHeight,
    FilterQuality quality = FilterQuality.medium,
    bool maintainAspectRatio = true,
  }) async {
    final Map<String, dynamic> results = await _runInIsolate(
      (
        ImageOperation.preprocessBlazeFace,
        {
          'imageData': imageData,
          'normalize': normalize,
          'requiredWidth': requiredWidth,
          'requiredHeight': requiredHeight,
          'quality': quality.index,
          'maintainAspectRatio': maintainAspectRatio,
        },
      ),
    );
    final inputs = results['inputs'] as Num3DInputMatrix;
    final originalSize = Size(
      results['originalWidth'] as double,
      results['originalHeight'] as double,
    );
    final newSize = Size(
      results['newWidth'] as double,
      results['newHeight'] as double,
    );
    return (inputs, originalSize, newSize);
  }

  /// Uses [preprocessImageToFloat32ChannelsFirst] inside the isolate.
  Future<(Float32List, Size, Size)> preprocessImageYoloOnnx(
    Uint8List imageData, {
    required bool normalize,
    required int requiredWidth,
    required int requiredHeight,
    FilterQuality quality = FilterQuality.medium,
    bool maintainAspectRatio = true,
  }) async {
    final Map<String, dynamic> results = await _runInIsolate(
      (
        ImageOperation.preprocessYoloOnnx,
        {
          'imageData': imageData,
          'normalize': normalize,
          'requiredWidth': requiredWidth,
          'requiredHeight': requiredHeight,
          'quality': quality.index,
          'maintainAspectRatio': maintainAspectRatio,
        },
      ),
    );
    final inputs = results['inputs'] as Float32List;
    final originalSize = Size(
      results['originalWidth'] as double,
      results['originalHeight'] as double,
    );
    final newSize = Size(
      results['newWidth'] as double,
      results['newHeight'] as double,
    );
    return (inputs, originalSize, newSize);
  }

  /// Preprocesses [imageData] for face alignment inside a separate isolate, to display the aligned faces. Mostly used for debugging.
  ///
  /// Returns a list of [Uint8List] images, one for each face, in png format.
  ///
  /// Uses [preprocessFaceAlignToUint8List] inside the isolate.
  ///
  /// WARNING: For preprocessing for MobileFaceNet, use [preprocessMobileFaceNet] instead!
  Future<List<Uint8List>> preprocessFaceAlign(
    Uint8List imageData,
    List<FaceDetectionAbsolute> faces,
  ) async {
    final faceLandmarks = faces.map((face) => face.allKeypoints).toList();
    return await _runInIsolate(
      (
        ImageOperation.preprocessFaceAlign,
        {
          'imageData': imageData,
          'faceLandmarks': faceLandmarks,
        },
      ),
    ).then((value) => value.cast<Uint8List>());
  }

  /// Preprocesses [imageData] for MobileFaceNet input inside a separate isolate.
  ///
  /// Returns a list of [Num3DInputMatrix] images, one for each face.
  ///
  /// Uses [preprocessToMobileFaceNetInput] inside the isolate.
  Future<
      (
        List<Num3DInputMatrix>,
        List<AlignmentResult>,
        List<bool>,
        List<double>,
        Size,
      )> preprocessMobileFaceNet(
    Uint8List imageData,
    List<FaceDetectionRelative> faces,
  ) async {
    final List<Map<String, dynamic>> facesJson =
        faces.map((face) => face.toJson()).toList();
    final Map<String, dynamic> results = await _runInIsolate(
      (
        ImageOperation.preprocessMobileFaceNet,
        {
          'imageData': imageData,
          'facesJson': facesJson,
        },
      ),
    );
    final inputs = results['inputs'] as List<Num3DInputMatrix>;
    final alignmentResultsJson =
        results['alignmentResultsJson'] as List<Map<String, dynamic>>;
    final alignmentResults = alignmentResultsJson.map((json) {
      return AlignmentResult.fromJson(json);
    }).toList();
    final isBlurs = results['isBlurs'] as List<bool>;
    final blurValues = results['blurValues'] as List<double>;
    final originalSize = Size(
      results['originalWidth'] as double,
      results['originalHeight'] as double,
    );
    return (inputs, alignmentResults, isBlurs, blurValues, originalSize);
  }

  /// Uses [preprocessToMobileFaceNetFloat32List] inside the isolate.
  Future<(Float32List, List<AlignmentResult>, List<bool>, List<double>, Size)>
      preprocessMobileFaceNetOnnx(
    String imagePath,
    List<FaceDetectionRelative> faces,
  ) async {
    final List<Map<String, dynamic>> facesJson =
        faces.map((face) => face.toJson()).toList();
    final Map<String, dynamic> results = await _runInIsolate(
      (
        ImageOperation.preprocessMobileFaceNetOnnx,
        {
          'imagePath': imagePath,
          'facesJson': facesJson,
        },
      ),
    );
    final inputs = results['inputs'] as Float32List;
    final alignmentResultsJson =
        results['alignmentResultsJson'] as List<Map<String, dynamic>>;
    final alignmentResults = alignmentResultsJson.map((json) {
      return AlignmentResult.fromJson(json);
    }).toList();
    final isBlurs = results['isBlurs'] as List<bool>;
    final blurValues = results['blurValues'] as List<double>;
    final originalSize = Size(
      results['originalWidth'] as double,
      results['originalHeight'] as double,
    );

    return (inputs, alignmentResults, isBlurs, blurValues, originalSize);
  }

  /// Generates a face thumbnail from [imageData] and a [faceDetection].
  ///
  /// Uses [generateFaceThumbnailFromData] inside the isolate.
  Future<Uint8List> generateFaceThumbnail(
    Uint8List imageData,
    FaceDetectionRelative faceDetection,
  ) async {
    return await _runInIsolate(
      (
        ImageOperation.generateFaceThumbnail,
        {
          'imageData': imageData,
          'faceDetection': faceDetection.toJson(),
        },
      ),
    ).then((value) => value[0] as Uint8List);
  }

  /// Generates face thumbnails for all [faceBoxes] in [imageData].
  ///
  /// Uses [generateFaceThumbnailsFromDataAndDetections] inside the isolate.
  Future<List<Uint8List>> generateFaceThumbnailsForImage(
    Uint8List imageData,
    List<FaceBox> faceBoxes,
  ) async {
    final List<Map<String, dynamic>> faceBoxesJson =
        faceBoxes.map((box) => box.toJson()).toList();
    return await _runInIsolate(
      (
        ImageOperation.generateFaceThumbnailsForImage,
        {
          'imageData': imageData,
          'faceBoxesList': faceBoxesJson,
        },
      ),
    ).then((value) => value.cast<Uint8List>());
  }

  /// Generates cropped and padded image data from [imageData] and a [faceBox].
  ///
  /// The steps are:
  /// 1. Crop the image to the face bounding box
  /// 2. Resize this cropped image to a square that is half the BlazeFace input size
  /// 3. Pad the image to the BlazeFace input size
  ///
  /// Uses [cropAndPadFaceData] inside the isolate.
  Future<Uint8List> cropAndPadFace(
    Uint8List imageData,
    List<double> faceBox,
  ) async {
    return await _runInIsolate(
      (
        ImageOperation.cropAndPadFace,
        {
          'imageData': imageData,
          'faceBox': List<double>.from(faceBox),
        },
      ),
    ).then((value) => value[0] as Uint8List);
  }
}
