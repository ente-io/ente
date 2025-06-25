import 'dart:async';
import 'dart:typed_data' show Uint8List;

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/services/isolate_functions.dart";
import "package:photos/services/isolate_service.dart";
import "package:photos/utils/image_ml_util.dart";

final Computer _computer = Computer.shared();

class FaceThumbnailGenerator extends SuperIsolate {
  @override
  Logger get logger => _logger;
  final _logger = Logger('FaceThumbnailGenerator');

  @override
  bool get isDartUiIsolate => true;

  @override
  String get isolateName => "FaceThumbnailGenerator";

  @override
  bool get shouldAutomaticDispose => true;

  // Singleton pattern
  FaceThumbnailGenerator._privateConstructor();
  static final FaceThumbnailGenerator instance =
      FaceThumbnailGenerator._privateConstructor();
  factory FaceThumbnailGenerator() => instance;

  /// Generates face thumbnails for all [faceBoxes] in [imageData].
  ///
  /// Uses [generateFaceThumbnailsUsingCanvas] inside the isolate.
  Future<List<Uint8List>> generateFaceThumbnails(
    String imagePath,
    List<FaceBox> faceBoxes,
  ) async {
    final List<Map<String, dynamic>> faceBoxesJson =
        faceBoxes.map((box) => box.toJson()).toList();
    final List<Uint8List> faces = await runInIsolate(
      IsolateOperation.generateFaceThumbnails,
      {
        'imagePath': imagePath,
        'faceBoxesList': faceBoxesJson,
      },
    ).then((value) => value.cast<Uint8List>());
    final compressedFaces = <Future<Uint8List>>[];
    for (final face in faces) {
      if (!shouldCompressFaceThumbnail(face)) {
        compressedFaces.add(Future.value(face));
      } else {
        final compressedFace = _computer.compute<Map, Uint8List>(
          compressFaceThumbnail,
          param: {'pngBytes': face},
        );
        compressedFaces.add(compressedFace);
      }
    }
    return await Future.wait(compressedFaces);
  }
}
