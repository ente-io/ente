import "dart:convert";

import 'package:photos/face/db_fields.dart';
import "package:photos/face/model/detection.dart";
import "package:photos/face/model/face.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/ml/ml_versions.dart";

Map<String, dynamic> mapRemoteToFaceDB(Face face) {
  return {
    faceIDColumn: face.faceID,
    fileIDColumn: face.fileID,
    faceDetectionColumn: json.encode(face.detection.toJson()),
    faceEmbeddingBlob: EVector(
      values: face.embedding,
    ).writeToBuffer(),
    faceScore: face.score,
    faceBlur: face.blur,
    isSideways: face.detection.faceIsSideways() ? 1 : 0,
    mlVersionColumn: faceMlVersion,
    imageWidth: face.fileInfo?.imageWidth ?? 0,
    imageHeight: face.fileInfo?.imageHeight ?? 0,
  };
}

Face mapRowToFace(Map<String, dynamic> row) {
  return Face(
    row[faceIDColumn] as String,
    row[fileIDColumn] as int,
    EVector.fromBuffer(row[faceEmbeddingBlob] as List<int>).values,
    row[faceScore] as double,
    Detection.fromJson(json.decode(row[faceDetectionColumn] as String)),
    row[faceBlur] as double,
    fileInfo: FileInfo(
      imageWidth: row[imageWidth] as int,
      imageHeight: row[imageHeight] as int,
    ),
  );
}
