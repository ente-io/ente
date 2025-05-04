import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/check_is.dart";
import "package:photos/models/ml/face/detection.dart";
import "package:photos/models/ml/face/dimension.dart";
import "package:photos/models/ml/face/landmark.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/utils/standalone/parse.dart";

// FileInfo holds the original image's width and height.
class FileInfo {
  int? imageWidth;
  int? imageHeight;
  FileInfo({
    this.imageWidth,
    this.imageHeight,
  });
}

class Face {
  final String faceID;
  final List<double> embedding;
  Detection detection;
  final double score;
  final double blur;

  //#region Local DB fields
  FileInfo? fileInfo;
  final int fileID;
  //#endregion

  // Is the image blurry based on Laplacian threshold?
  bool get isBlurry => blur < kLaplacianHardThreshold;

  // Is the face score considered high quality?
  bool get hasHighScore => score > kMinimumQualityFaceScore;

  // Is the face both not blurry and has high enough score?
  bool get isHighQuality => (!isBlurry) && hasHighScore;

  // Is the face recognized (check >= 0.7)?
  bool get isRecognized => detection.box.check >= 0.7;

  // Is the face in the suggestion range (0.1 < check < 0.7)?
  bool get isSuggestion => detection.box.check > 0.1 && detection.box.check < 0.7;

  // Is the face uncertain (check <= 0.1)?
  bool get isUncertain => detection.box.check <= 0.1;

  // Evaluation of face recognition confidence (enum)
  FaceCheckStatus get checkStatus => detection.box.checkStatus;

  // Shortcut booleans from checkStatus
  bool get isCheckedRecognized => detection.box.isRecognized;
  bool get isCheckedSuggestable => detection.box.isSuggestable;
  bool get isCheckedRejected => detection.box.isRejected;

  Face(
    this.faceID,
    this.fileID,
    this.embedding,
    this.score,
    this.detection,
    this.blur, {
    this.fileInfo,
  });

  factory Face.fromFaceResult(
    FaceResult faceResult,
    int fileID,
    Dimensions decodedDimensions,
  ) {
    final detection = Detection(
      box: FaceBox(
        x: faceResult.detection.xMinBox,
        y: faceResult.detection.yMinBox,
        width: faceResult.detection.width,
        height: faceResult.detection.height,
        check: faceResult.detection.check, // Important: take check here
      ),
      landmarks: faceResult.detection.allKeypoints
          .map((keypoint) => Landmark(x: keypoint[0], y: keypoint[1]))
          .toList(),
    );

    return Face(
      faceResult.faceId,
      fileID,
      faceResult.embedding,
      faceResult.detection.score,
      detection,
      faceResult.blurValue,
      fileInfo: FileInfo(
        imageHeight: decodedDimensions.height,
        imageWidth: decodedDimensions.width,
      ),
    );
  }

  factory Face.empty(int fileID, {bool error = false}) {
    return Face(
      "${fileID}_0_0_0_0",
      fileID,
      <double>[],
      error ? -1.0 : 0.0,
      Detection.empty(),
      0.0,
    );
  }

  factory Face.fromJson(Map<String, dynamic> json) {
    final String faceID = json['faceID'] as String;
    final int fileID = getFileIdFromFaceId<int>(faceID);
    return Face(
      faceID,
      fileID,
      parseAsDoubleList(json['embedding'] as List),
      parseIntOrDoubleAsDouble(json['score'])!,
      Detection.fromJson(json['detection'] as Map<String, dynamic>),
      parseIntOrDoubleAsDouble(json['blur']) ?? kLapacianDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'faceID': faceID,
        'embedding': embedding,
        'detection': detection.toJson(),
        'score': score,
        'blur': blur,
      };
}
