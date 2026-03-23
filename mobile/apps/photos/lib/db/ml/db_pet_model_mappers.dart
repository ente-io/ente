import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:photos/db/ml/schema.dart";
import "package:photos/models/ml/ml_versions.dart";

// ── Pet Face DB Mapper ──

/// Represents a row in the [petFacesTable].
class DBPetFace {
  final int fileId;
  final String petFaceId;
  final String detection;
  final int? faceVectorId;
  final int species;
  final double faceScore;
  final int imageHeight;
  final int imageWidth;
  final int mlVersion;

  DBPetFace({
    required this.fileId,
    required this.petFaceId,
    required this.detection,
    required this.faceVectorId,
    required this.species,
    required this.faceScore,
    required this.imageHeight,
    required this.imageWidth,
    required this.mlVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      fileIDColumn: fileId,
      petFaceIDColumn: petFaceId,
      faceDetectionColumn: detection,
      faceVectorIdColumn: faceVectorId,
      speciesColumn: species,
      // Use string literals for keys that collide with instance member names.
      'score': faceScore,
      'height': imageHeight,
      'width': imageWidth,
      mlVersionColumn: mlVersion,
    };
  }

  /// Creates a dummy entry to mark a file as pet-indexed when no pets were
  /// found, matching how [Face.empty] works for human face detection.
  factory DBPetFace.empty(int fileId, {bool error = false}) {
    return DBPetFace(
      fileId: fileId,
      petFaceId: '${fileId}_pet_0_0_0_0',
      detection: '{}',
      faceVectorId: null,
      species: -1,
      faceScore: error ? -1.0 : 0.0,
      imageHeight: 0,
      imageWidth: 0,
      mlVersion: petMlVersion,
    );
  }

  factory DBPetFace.fromMap(Map<String, dynamic> map) {
    return DBPetFace(
      fileId: map[fileIDColumn] as int,
      petFaceId: map[petFaceIDColumn] as String,
      detection: map[faceDetectionColumn] as String,
      faceVectorId: map[faceVectorIdColumn] as int?,
      species: map[speciesColumn] as int,
      faceScore: parseIntOrDoubleAsDouble(map['score']) ?? 0.0,
      imageHeight: map['height'] as int,
      imageWidth: map['width'] as int,
      mlVersion: map[mlVersionColumn] as int,
    );
  }
}
