import "dart:convert";
import "dart:typed_data" show Uint8List;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/detection.dart";
import "package:photos/models/ml/face/landmark.dart";
import "package:photos/services/machine_learning/ml_result.dart";

// ── Pet Face DB Mapper ──

/// Represents a row in the [petFacesTable].
class DBPetFace {
  final int fileId;
  final String petFaceId;
  final String detection;
  final String landmarks;
  final int faceVectorId;
  final String species;
  final double faceScore;
  final int imageHeight;
  final int imageWidth;
  final int mlVersion;
  final Uint8List? embeddingBlob;

  DBPetFace({
    required this.fileId,
    required this.petFaceId,
    required this.detection,
    required this.landmarks,
    required this.faceVectorId,
    required this.species,
    required this.faceScore,
    required this.imageHeight,
    required this.imageWidth,
    required this.mlVersion,
    this.embeddingBlob,
  });

  /// Convert a [FaceResult] (from Rust) into a DB row, embedding the assigned [vectorId].
  factory DBPetFace.fromRustResult({
    required int fileId,
    required FaceResult rustResult,
    required int vectorId,
    required int imageHeight,
    required int imageWidth,
    required int mlVersion,
    required String speciesLabel,
  }) {
    // Mirror the human face detection JSON structure
    final detectionObj = Detection(
      box: FaceBox(
        x: rustResult.detection.xMinBox,
        y: rustResult.detection.yMinBox,
        width: rustResult.detection.width,
        height: rustResult.detection.height,
      ),
      landmarks: rustResult.detection.allKeypoints
          .map((kp) => Landmark(x: kp[0], y: kp[1]))
          .toList(),
    );

    return DBPetFace(
      fileId: fileId,
      petFaceId: rustResult.faceId,
      detection: jsonEncode(detectionObj.toJson()),
      landmarks: jsonEncode(rustResult.detection.allKeypoints),
      faceVectorId: vectorId,
      species: speciesLabel,
      faceScore: rustResult.detection.score,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      mlVersion: mlVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fileIDColumn: fileId,
      petFaceIDColumn: petFaceId,
      faceDetectionColumn: detection,
      petLandmarksColumn: landmarks,
      faceVectorIdColumn: faceVectorId,
      speciesColumn: species,
      'score': faceScore,
      'height': imageHeight,
      'width': imageWidth,
      mlVersionColumn: mlVersion,
      petFaceEmbeddingColumn: embeddingBlob,
    };
  }

  factory DBPetFace.fromMap(Map<String, dynamic> map) {
    return DBPetFace(
      fileId: map[fileIDColumn] as int,
      petFaceId: map[petFaceIDColumn] as String,
      detection: map[faceDetectionColumn] as String,
      landmarks: map[petLandmarksColumn] as String,
      faceVectorId: map[faceVectorIdColumn] as int,
      species: map[speciesColumn] as String,
      faceScore: parseIntOrDoubleAsDouble(map['score']) ?? 0.0,
      imageHeight: map['height'] as int,
      imageWidth: map['width'] as int,
      mlVersion: map[mlVersionColumn] as int,
      embeddingBlob: map[petFaceEmbeddingColumn] as Uint8List?,
    );
  }
}

// ── Pet Body DB Mapper ──

/// Represents a row in the [petBodiesTable].
class DBPetBody {
  final int fileId;
  final String petBodyId;
  final String detection;
  final int bodyVectorId;
  final String species;
  final double faceScore; // Reusing column name, but represents body score
  final int imageHeight;
  final int imageWidth;
  final int mlVersion;
  final Uint8List? embeddingBlob;

  DBPetBody({
    required this.fileId,
    required this.petBodyId,
    required this.detection,
    required this.bodyVectorId,
    required this.species,
    required this.faceScore,
    required this.imageHeight,
    required this.imageWidth,
    required this.mlVersion,
    this.embeddingBlob,
  });

  /// Convert to DB row given the bounding box, class, and assigned [vectorId].
  /// boxXyxy: [xMin, yMin, xMax, yMax]
  factory DBPetBody.fromRustResult({
    required int fileId,
    required String petBodyId,
    required List<double> boxXyxy,
    required double score,
    required int vectorId,
    required int imageHeight,
    required int imageWidth,
    required int mlVersion,
    required String speciesLabel,
  }) {
    final width = boxXyxy[2] - boxXyxy[0];
    final height = boxXyxy[3] - boxXyxy[1];

    final detectionObj = Detection(
      box: FaceBox(
        x: boxXyxy[0],
        y: boxXyxy[1],
        width: width,
        height: height,
      ),
      landmarks: const [], // Bodies don't have landmarks
    );

    return DBPetBody(
      fileId: fileId,
      petBodyId: petBodyId,
      detection: jsonEncode(detectionObj.toJson()),
      bodyVectorId: vectorId,
      species: speciesLabel,
      faceScore: score,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      mlVersion: mlVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fileIDColumn: fileId,
      petBodyIDColumn: petBodyId,
      faceDetectionColumn: detection,
      bodyVectorIdColumn: bodyVectorId,
      speciesColumn: species,
      'score': faceScore,
      'height': imageHeight,
      'width': imageWidth,
      mlVersionColumn: mlVersion,
      petBodyEmbeddingColumn: embeddingBlob,
    };
  }

  factory DBPetBody.fromMap(Map<String, dynamic> map) {
    return DBPetBody(
      fileId: map[fileIDColumn] as int,
      petBodyId: map[petBodyIDColumn] as String,
      detection: map[faceDetectionColumn] as String,
      bodyVectorId: map[bodyVectorIdColumn] as int,
      species: map[speciesColumn] as String,
      faceScore: parseIntOrDoubleAsDouble(map['score']) ?? 0.0,
      imageHeight: map['height'] as int,
      imageWidth: map['width'] as int,
      mlVersion: map[mlVersionColumn] as int,
      embeddingBlob: map[petBodyEmbeddingColumn] as Uint8List?,
    );
  }
}
