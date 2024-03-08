import "package:photos/face/model/box.dart";
import "package:photos/face/model/landmark.dart";

class Detection {
  FaceBox box;
  List<Landmark> landmarks;

  Detection({
    required this.box,
    required this.landmarks,
  });

  // emoty box
  Detection.empty()
      : box = FaceBox(
          x: 0,
          y: 0,
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
