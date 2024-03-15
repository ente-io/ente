import "package:photos/face/model/box.dart";
import "package:photos/face/model/landmark.dart";

/// Stores the face detection data, notably the bounding box and landmarks.
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
}
