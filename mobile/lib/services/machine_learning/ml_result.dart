import "dart:convert" show jsonEncode, jsonDecode;

import "package:logging/logging.dart";
import "package:photos/models/ml/face/dimension.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

class MLResult {
  int fileId;

  List<FaceResult>? faces = <FaceResult>[];
  ClipResult? clip;

  Dimensions decodedImageSize;

  bool get ranML => facesRan || clipRan;
  bool get facesRan => faces != null;
  bool get clipRan => clip != null;

  MLResult({
    this.fileId = -1,
    this.faces,
    this.clip,
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  });

  MLResult.fromEnteFileID(
    fileID, {
    this.decodedImageSize = const Dimensions(width: -1, height: -1),
  }) : fileId = fileID;

  Map<String, dynamic> _toJson() => {
        'fileId': fileId,
        'faces': faces?.map((face) => face.toJson()).toList(),
        'clip': clip?.toJson(),
        'decodedImageSize': {
          'width': decodedImageSize.width,
          'height': decodedImageSize.height,
        },
      };

  String toJsonString() => jsonEncode(_toJson());

  static MLResult _fromJson(Map<String, dynamic> json) {
    return MLResult(
      fileId: json['fileId'],
      faces: json['faces'] != null
          ? (json['faces'] as List)
              .map((item) => FaceResult.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      clip: json['clip'] != null
          ? ClipResult.fromJson(json['clip'] as Map<String, dynamic>)
          : null,
      decodedImageSize: json['decodedImageSize'] != null
          ? Dimensions(
              width: json['decodedImageSize']['width'],
              height: json['decodedImageSize']['height'],
            )
          : json['faceDetectionImageSize'] == null
              ? const Dimensions(width: -1, height: -1)
              : Dimensions(
                  width: (json['faceDetectionImageSize']['width'] as double)
                      .truncate(),
                  height: (json['faceDetectionImageSize']['height'] as double)
                      .truncate(),
                ),
    );
  }

  static MLResult fromJsonString(String jsonString) {
    return _fromJson(jsonDecode(jsonString));
  }
}

class ClipResult {
  final int fileID;
  final Embedding embedding;

  ClipResult({
    required this.fileID,
    required this.embedding,
  });

  Map<String, dynamic> toJson() => {
        'fileID': fileID,
        'embedding': embedding,
      };

  static ClipResult fromJson(Map<String, dynamic> json) {
    return ClipResult(
      fileID: json['fileID'],
      embedding: Embedding.from(json['embedding']),
    );
  }
}

class FaceResult {
  late FaceDetectionRelative detection;
  late double blurValue;
  late AlignmentResult alignment;
  late Embedding embedding;
  late int fileId;
  late String faceId;

  bool get isBlurry => blurValue < kLaplacianHardThreshold;

  FaceResult({
    required this.fileId,
    required this.faceId,
    required this.detection,
    required this.blurValue,
    required this.alignment,
    required this.embedding,
  });

  FaceResult.fromFaceDetection(
    FaceDetectionRelative faceDetection,
    int fileID,
  ) {
    fileId = fileID;
    faceId = faceDetection.toFaceID(fileID: fileID);
    detection = faceDetection;
  }

  Map<String, dynamic> toJson() => {
        'detection': detection.toJson(),
        'blurValue': blurValue,
        'alignment': alignment.toJson(),
        'embedding': embedding,
        'fileId': fileId,
        'faceId': faceId,
      };

  static FaceResult fromJson(Map<String, dynamic> json) {
    return FaceResult(
      detection: FaceDetectionRelative.fromJson(json['detection']),
      blurValue: json['blurValue'],
      alignment: AlignmentResult.fromJson(json['alignment']),
      embedding: Embedding.from(json['embedding']),
      fileId: json['fileId'],
      faceId: json['faceId'],
    );
  }
}

T getFileIdFromFaceId<T extends Object>(String faceId) {
  final String faceIdSplit = faceId.substring(0, faceId.indexOf('_'));
  try {
    if (T == int) {
      return int.parse(faceIdSplit) as T;
    }
    if (T == String) {
      return faceIdSplit as T;
    }
  } catch (e) {
    Logger("FaceID").severe(
      "Error parsing faceId: $faceId with type $T",
      e,
    );
  }
  throw ArgumentError("Unsupported type: $T");
}

int? tryGetFileIdFromFaceId(String faceId) {
  try {
    return int.tryParse(faceId.substring(0, faceId.indexOf('_')));
  } catch (e, s) {
    Logger("FaceID").severe(
      "Error parsing faceId: $faceId",
      e,
      s,
    );
    return null;
  }
}
