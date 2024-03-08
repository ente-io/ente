import "dart:convert";

import 'package:photos/face/db_fields.dart';
import "package:photos/face/model/detection.dart";
import "package:photos/face/model/face.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/face/model/person_face.dart';
import "package:photos/generated/protos/ente/common/vector.pb.dart";

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

Map<String, dynamic> mapToFaceDB(PersonFace personFace) {
  return {
    faceIDColumn: personFace.face.faceID,
    faceDetectionColumn: json.encode(personFace.face.detection.toJson()),
    faceConfirmedColumn: boolToSQLInt(personFace.confirmed),
    faceClusterId: personFace.personID,
    faceClosestDistColumn: personFace.closeDist,
    faceClosestFaceID: personFace.closeFaceID,
  };
}

Map<String, dynamic> mapPersonToRow(Person p) {
  return {
    idColumn: p.remoteID,
    nameColumn: p.attr.name,
    personHiddenColumn: boolToSQLInt(p.attr.isHidden),
    coverFaceIDColumn: p.attr.avatarFaceId,
    clusterToFaceIdJson: jsonEncode(p.attr.faces.toList()),
  };
}

Person mapRowToPerson(Map<String, dynamic> row) {
  return Person(
    row[idColumn] as String,
    PersonAttr(
      name: row[nameColumn] as String,
      isHidden: sqlIntToBool(row[personHiddenColumn] as int),
      avatarFaceId: row[coverFaceIDColumn] as String?,
      faces: (jsonDecode(row[clusterToFaceIdJson]) as List)
          .map((e) => e.toString())
          .toList(),
    ),
  );
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
    mlVersionColumn: 1,
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
  );
}
