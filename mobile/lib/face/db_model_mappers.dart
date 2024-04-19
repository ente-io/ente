import "dart:convert";

import 'package:photos/face/db_fields.dart';
import "package:photos/face/model/detection.dart";
import "package:photos/face/model/face.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/ml/ml_versions.dart";

int boolToSQLInt(bool? value, {bool defaultValue = false}) {
  final bool v = value ?? defaultValue;
  if (v == false) {
    return 0;
  } else {
    return 1;
  }
}

bool sqlIntToBool(int? value, {bool defaultValue = false}) {
  final int v = value ?? (defaultValue ? 1 : 0);
  if (v == 0) {
    return false;
  } else {
    return true;
  }
}

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
