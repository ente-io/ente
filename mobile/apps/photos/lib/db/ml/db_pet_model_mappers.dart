import "dart:typed_data" show Uint8List;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:photos/db/ml/schema.dart";

// ── Pet Face DB Mapper ──

/// Represents a row in the [petFacesTable].
class DBPetFace {
  final int fileId;
  final String petFaceId;
  final String detection;
  final int faceVectorId;
  final int species;
  final double faceScore;
  final int imageHeight;
  final int imageWidth;
  final int mlVersion;
  final Uint8List? embeddingBlob;

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
    this.embeddingBlob,
  });

  Map<String, dynamic> toMap() {
    return {
      fileIDColumn: fileId,
      petFaceIDColumn: petFaceId,
      faceDetectionColumn: detection,
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
      faceVectorId: map[faceVectorIdColumn] as int,
      species: map[speciesColumn] as int,
      faceScore: parseIntOrDoubleAsDouble(map['score']) ?? 0.0,
      imageHeight: map['height'] as int,
      imageWidth: map['width'] as int,
      mlVersion: map[mlVersionColumn] as int,
      embeddingBlob: map[petFaceEmbeddingColumn] as Uint8List?,
    );
  }
}

// ── Detected Object DB Mapper ──

/// Represents a row in the [petBodiesTable].
class DBPetBody {
  final int fileId;
  final String petBodyId;
  final String detection;
  final int bodyVectorId;
  final int species;
  final double score;
  final int imageHeight;
  final int imageWidth;
  final int mlVersion;

  DBPetBody({
    required this.fileId,
    required this.petBodyId,
    required this.detection,
    required this.bodyVectorId,
    required this.species,
    required this.score,
    required this.imageHeight,
    required this.imageWidth,
    required this.mlVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      fileIDColumn: fileId,
      petBodyIDColumn: petBodyId,
      detectionColumn: detection,
      bodyVectorIdColumn: bodyVectorId,
      speciesColumn: species,
      'score': score,
      'height': imageHeight,
      'width': imageWidth,
      mlVersionColumn: mlVersion,
    };
  }

  factory DBPetBody.fromMap(Map<String, dynamic> map) {
    return DBPetBody(
      fileId: map[fileIDColumn] as int,
      petBodyId: map[petBodyIDColumn] as String,
      detection: map[detectionColumn] as String,
      bodyVectorId: map[bodyVectorIdColumn] as int,
      species: map[speciesColumn] as int,
      score: parseIntOrDoubleAsDouble(map['score']) ?? 0.0,
      imageHeight: map['height'] as int,
      imageWidth: map['width'] as int,
      mlVersion: map[mlVersionColumn] as int,
    );
  }
}
