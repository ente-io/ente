import 'dart:async';
import 'dart:typed_data' show Uint8List;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/service_locator.dart";
import "package:photos/utils/image_ml_util.dart";
import "package:photos/utils/isolate/isolate_operations.dart";
import "package:photos/utils/isolate/super_isolate.dart";

class FaceThumbnailGenerationResult {
  final List<Uint8List> thumbnails;
  final int sourceWidth;
  final int sourceHeight;

  const FaceThumbnailGenerationResult({
    required this.thumbnails,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}

@pragma('vm:entry-point')
class FaceThumbnailGenerator extends SuperIsolate {
  @override
  Logger get logger => _logger;
  final _logger = Logger('FaceThumbnailGenerator');

  @override
  bool get isDartUiIsolate => !flagService.useRustForFaceThumbnails;

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
      final useRustForFaceThumbnails = flagService.useRustForFaceThumbnails;
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
          'useRustForFaceThumbnails': useRustForFaceThumbnails,
        },
      ).then((value) => value.cast<Uint8List>());
      _logger.info("Generated face thumbnails");
      if (useRustForFaceThumbnails) {
        // Rust path already emits compressed JPEG bytes.
        return faces;
      }
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

  Future<FaceThumbnailGenerationResult>
      generateFaceThumbnailsWithSourceDimensions(
    String imagePath,
    List<FaceBox> faceBoxes,
  ) async {
    if (!flagService.progressivePersonFaceThumbnailsEnabled) {
      final thumbnails = await generateFaceThumbnails(imagePath, faceBoxes);
      return FaceThumbnailGenerationResult(
        thumbnails: thumbnails,
        sourceWidth: 0,
        sourceHeight: 0,
      );
    }

    try {
      final useRustForFaceThumbnails = flagService.useRustForFaceThumbnails;
      _logger.info(
        "Generating face thumbnails for ${faceBoxes.length} face boxes in $imagePath",
      );
      final List<Map<String, dynamic>> faceBoxesJson =
          faceBoxes.map((box) => box.toJson()).toList();
      final Map<String, dynamic> rawResult = await runInIsolate(
        IsolateOperation.generateFaceThumbnailsWithSourceDimensions,
        {
          'imagePath': imagePath,
          'faceBoxesList': faceBoxesJson,
          'useRustForFaceThumbnails': useRustForFaceThumbnails,
        },
      ).then((value) => Map<String, dynamic>.from(value));
      final List<Uint8List> faces =
          (rawResult['thumbnails'] as List<dynamic>).cast<Uint8List>();
      final int sourceWidth = rawResult['sourceWidth'] as int? ?? 0;
      final int sourceHeight = rawResult['sourceHeight'] as int? ?? 0;
      _logger.info(
        "Generated face thumbnails with source dimensions ${sourceWidth}x$sourceHeight",
      );
      if (useRustForFaceThumbnails) {
        // Rust path already emits compressed JPEG bytes.
        return FaceThumbnailGenerationResult(
          thumbnails: faces,
          sourceWidth: sourceWidth,
          sourceHeight: sourceHeight,
        );
      }
      final compressedFaces =
          await compressFaceThumbnails({'listPngBytes': faces});
      _logger.fine(
        "Compressed face thumbnails from sizes ${faces.map((e) => e.length / 1024).toList()} to ${compressedFaces.map((e) => e.length / 1024).toList()} kilobytes",
      );
      return FaceThumbnailGenerationResult(
        thumbnails: compressedFaces,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
      );
    } catch (e, s) {
      _logger.severe("Failed to generate face thumbnails", e, s);

      rethrow;
    }
  }
}
