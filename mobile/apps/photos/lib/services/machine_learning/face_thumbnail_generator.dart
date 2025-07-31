import 'dart:async';
import 'dart:typed_data' show Uint8List;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/isolate/isolate_operations.dart";
import "package:photos/utils/isolate/super_isolate.dart";

@pragma('vm:entry-point')
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
    try {
      _logger.info(
        "Generating face thumbnails for ${faceBoxes.length} face boxes in $imagePath",
      );
      final List<Map<String, dynamic>> faceBoxesJson =
          faceBoxes.map((box) => box.toJson()).toList();
      final List<Uint8List> faces = await runInIsolate(
        IsolateOperation.generateFaceThumbnails,
        {
          'imagePath': imagePath,
          'faceBoxesList': faceBoxesJson,
        },
      ).then((value) => value.cast<Uint8List>());
      _logger.info("Generated face thumbnails");
      final compressedFaces =
          await compressFaceThumbnails({'listPngBytes': faces});
      _logger.fine(
        "Compressed face thumbnails from sizes ${faces.map((e) => e.length / 1024).toList()} to ${compressedFaces.map((e) => e.length / 1024).toList()} kilobytes",
      );
      return compressedFaces;
    } catch (e, s) {
      _logger.severe("Failed to generate face thumbnails", e, s);

      rethrow;
    }
  }
}
