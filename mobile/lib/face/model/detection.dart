import "package:photos/face/model/box.dart";
import "package:photos/face/model/landmark.dart";

/// Stores the face detection data, notably the bounding box and landmarks.
///
/// - Bounding box: [FaceBox] with xMin, yMin (so top left corner), width, height
/// - Landmarks: list of [Landmark]s, namely leftEye, rightEye, nose, leftMouth, rightMouth
///
/// WARNING: All coordinates are relative to the image size, so in the range [0, 1]!
class Detection {
  FaceBox box;
  List<Landmark> landmarks;

  Detection({
    required this.box,
    required this.landmarks,
  });

  bool get isEmpty => box.width == 0 && box.height == 0 && landmarks.isEmpty;

  // emoty box
  Detection.empty()
      : box = FaceBox(
          xMin: 0,
          yMin: 0,
          width: 0,
          height: 0,
        ),
        landmarks = [];

  Map<String, dynamic> toJson() => {
        'box': box.toJson(),
        'landmarks': landmarks.map((x) => x.toJson()).toList(),
      };

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      box: FaceBox.fromJson(json['box'] as Map<String, dynamic>),
      landmarks: List<Landmark>.from(
        json['landmarks']
            .map((x) => Landmark.fromJson(x as Map<String, dynamic>)),
      ),
    );
  }

  // TODO: iterate on better scoring logic, current is a placeholder
  int getVisibilityScore() {
    final double aspectRatio = box.width / box.height;
    final double eyeDistance = (landmarks[1].x - landmarks[0].x).abs();
    final double mouthDistance = (landmarks[4].x - landmarks[3].x).abs();
    final double noseEyeDistance =
        (landmarks[2].y - ((landmarks[0].y + landmarks[1].y) / 2)).abs();

    final double normalizedEyeDistance = eyeDistance / box.width;
    final double normalizedMouthDistance = mouthDistance / box.width;
    final double normalizedNoseEyeDistance = noseEyeDistance / box.height;

    const double aspectRatioThreshold = 0.8;
    const double eyeDistanceThreshold = 0.2;
    const double mouthDistanceThreshold = 0.3;
    const double noseEyeDistanceThreshold = 0.1;

    double score = 0;
    if (aspectRatio >= aspectRatioThreshold) {
      score += 50;
    }
    if (normalizedEyeDistance >= eyeDistanceThreshold) {
      score += 20;
    }
    if (normalizedMouthDistance >= mouthDistanceThreshold) {
      score += 20;
    }
    if (normalizedNoseEyeDistance >= noseEyeDistanceThreshold) {
      score += 10;
    }

    return score.clamp(0, 100).toInt();
  }
}
