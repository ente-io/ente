import 'dart:convert' show utf8;
import 'dart:math' show sqrt, pow;
import 'dart:ui' show Size;
import 'package:crypto/crypto.dart' show sha256;

abstract class Detection {
  final double score;

  Detection({required this.score});

  const Detection.empty() : score = 0;

  get width;
  get height;

  @override
  String toString();
}

extension BBoxExtension on List<double> {
  void roundBoxToDouble() {
    final widthRounded = (this[2] - this[0]).roundToDouble();
    final heightRounded = (this[3] - this[1]).roundToDouble();
    this[0] = this[0].roundToDouble();
    this[1] = this[1].roundToDouble();
    this[2] = this[0] + widthRounded;
    this[3] = this[1] + heightRounded;
  }

  // double get xMinBox =>
  //     isNotEmpty ? this[0] : throw IndexError.withLength(0, length);
  // double get yMinBox =>
  //     length >= 2 ? this[1] : throw IndexError.withLength(1, length);
  // double get xMaxBox =>
  //     length >= 3 ? this[2] : throw IndexError.withLength(2, length);
  // double get yMaxBox =>
  //     length >= 4 ? this[3] : throw IndexError.withLength(3, length);
}

/// This class represents a face detection with relative coordinates in the range [0, 1].
/// The coordinates are relative to the image size. The pattern for the coordinates is always [x, y], where x is the horizontal coordinate and y is the vertical coordinate.
///
/// The [score] attribute is a double representing the confidence of the face detection.
///
/// The [box] attribute is a list of 4 doubles, representing the coordinates of the bounding box of the face detection.
/// The four values of the box in order are: [xMinBox, yMinBox, xMaxBox, yMaxBox].
///
/// The [allKeypoints] attribute is a list of 6 lists of 2 doubles, representing the coordinates of the keypoints of the face detection.
/// The six lists of two values in order are: [leftEye, rightEye, nose, mouth, leftEar, rightEar]. Again, all in [x, y] order.
class FaceDetectionRelative extends Detection {
  final List<double> box;
  final List<List<double>> allKeypoints;

  double get xMinBox => box[0];
  double get yMinBox => box[1];
  double get xMaxBox => box[2];
  double get yMaxBox => box[3];

  List<double> get leftEye => allKeypoints[0];
  List<double> get rightEye => allKeypoints[1];
  List<double> get nose => allKeypoints[2];
  List<double> get leftMouth => allKeypoints[3];
  List<double> get rightMouth => allKeypoints[4];

  FaceDetectionRelative({
    required double score,
    required List<double> box,
    required List<List<double>> allKeypoints,
  })  : assert(
          box.every((e) => e >= -0.1 && e <= 1.1),
          "Bounding box values must be in the range [0, 1], with only a small margin of error allowed.",
        ),
        assert(
          allKeypoints
              .every((sublist) => sublist.every((e) => e >= -0.1 && e <= 1.1)),
          "All keypoints must be in the range [0, 1], with only a small margin of error allowed.",
        ),
        box = List<double>.from(box.map((e) => e.clamp(0.0, 1.0))),
        allKeypoints = allKeypoints
            .map(
              (sublist) =>
                  List<double>.from(sublist.map((e) => e.clamp(0.0, 1.0))),
            )
            .toList(),
        super(score: score);

  factory FaceDetectionRelative.zero() {
    return FaceDetectionRelative(
      score: 0,
      box: <double>[0, 0, 0, 0],
      allKeypoints: <List<double>>[
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
      ],
    );
  }

  /// This is used to initialize the FaceDetectionRelative object with default values.
  /// This constructor is useful because it can be used to initialize a FaceDetectionRelative object as a constant.
  /// Contrary to the `FaceDetectionRelative.zero()` constructor, this one gives immutable attributes [box] and [allKeypoints].
  FaceDetectionRelative.defaultInitialization()
      : box = const <double>[0, 0, 0, 0],
        allKeypoints = const <List<double>>[
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0],
        ],
        super.empty();

  FaceDetectionRelative getNearestDetection(
    List<FaceDetectionRelative> detections,
  ) {
    if (detections.isEmpty) {
      throw ArgumentError("The detection list cannot be empty.");
    }

    var nearestDetection = detections[0];
    var minDistance = double.infinity;

    // Calculate the center of the current instance
    final centerX1 = (xMinBox + xMaxBox) / 2;
    final centerY1 = (yMinBox + yMaxBox) / 2;

    for (var detection in detections) {
      final centerX2 = (detection.xMinBox + detection.xMaxBox) / 2;
      final centerY2 = (detection.yMinBox + detection.yMaxBox) / 2;
      final distance =
          sqrt(pow(centerX2 - centerX1, 2) + pow(centerY2 - centerY1, 2));
      if (distance < minDistance) {
        minDistance = distance;
        nearestDetection = detection;
      }
    }
    return nearestDetection;
  }

  void transformRelativeToOriginalImage(
    List<double> fromBox, // [xMin, yMin, xMax, yMax]
    List<double> toBox, // [xMin, yMin, xMax, yMax]
  ) {
    // Return if all elements of fromBox and toBox are equal
    for (int i = 0; i < fromBox.length; i++) {
      if (fromBox[i] != toBox[i]) {
        break;
      }
      if (i == fromBox.length - 1) {
        return;
      }
    }

    // Account for padding
    final double paddingXRatio =
        (fromBox[0] - toBox[0]) / (toBox[2] - toBox[0]);
    final double paddingYRatio =
        (fromBox[1] - toBox[1]) / (toBox[3] - toBox[1]);

    // Calculate the scaling and translation
    final double scaleX = (fromBox[2] - fromBox[0]) / (1 - 2 * paddingXRatio);
    final double scaleY = (fromBox[3] - fromBox[1]) / (1 - 2 * paddingYRatio);
    final double translateX = fromBox[0] - paddingXRatio * scaleX;
    final double translateY = fromBox[1] - paddingYRatio * scaleY;

    // Transform Box
    _transformBox(box, scaleX, scaleY, translateX, translateY);

    // Transform All Keypoints
    for (int i = 0; i < allKeypoints.length; i++) {
      allKeypoints[i] = _transformPoint(
        allKeypoints[i],
        scaleX,
        scaleY,
        translateX,
        translateY,
      );
    }
  }

  void correctForMaintainedAspectRatio(
    Size originalSize,
    Size newSize,
  ) {
    // Return if both are the same size, meaning no scaling was done on both width and height
    if (originalSize == newSize) {
      return;
    }

    // Calculate the scaling
    final double scaleX = originalSize.width / newSize.width;
    final double scaleY = originalSize.height / newSize.height;
    const double translateX = 0;
    const double translateY = 0;

    // Transform Box
    _transformBox(box, scaleX, scaleY, translateX, translateY);

    // Transform All Keypoints
    for (int i = 0; i < allKeypoints.length; i++) {
      allKeypoints[i] = _transformPoint(
        allKeypoints[i],
        scaleX,
        scaleY,
        translateX,
        translateY,
      );
    }
  }

  void _transformBox(
    List<double> box,
    double scaleX,
    double scaleY,
    double translateX,
    double translateY,
  ) {
    box[0] = (box[0] * scaleX + translateX).clamp(0.0, 1.0);
    box[1] = (box[1] * scaleY + translateY).clamp(0.0, 1.0);
    box[2] = (box[2] * scaleX + translateX).clamp(0.0, 1.0);
    box[3] = (box[3] * scaleY + translateY).clamp(0.0, 1.0);
  }

  List<double> _transformPoint(
    List<double> point,
    double scaleX,
    double scaleY,
    double translateX,
    double translateY,
  ) {
    return [
      (point[0] * scaleX + translateX).clamp(0.0, 1.0),
      (point[1] * scaleY + translateY).clamp(0.0, 1.0),
    ];
  }

  FaceDetectionAbsolute toAbsolute({
    required int imageWidth,
    required int imageHeight,
  }) {
    final scoreCopy = score;
    final boxCopy = List<double>.from(box, growable: false);
    final allKeypointsCopy = allKeypoints
        .map((sublist) => List<double>.from(sublist, growable: false))
        .toList();

    boxCopy[0] *= imageWidth;
    boxCopy[1] *= imageHeight;
    boxCopy[2] *= imageWidth;
    boxCopy[3] *= imageHeight;
    // final intbox = boxCopy.map((e) => e.toInt()).toList();

    for (List<double> keypoint in allKeypointsCopy) {
      keypoint[0] *= imageWidth;
      keypoint[1] *= imageHeight;
    }
    // final intKeypoints =
    //     allKeypointsCopy.map((e) => e.map((e) => e.toInt()).toList()).toList();
    return FaceDetectionAbsolute(
      score: scoreCopy,
      box: boxCopy,
      allKeypoints: allKeypointsCopy,
    );
  }

  String toFaceID({required int fileID}) {
    // Assert that the values are within the expected range
    assert(
      (xMinBox >= 0 && xMinBox <= 1) &&
          (yMinBox >= 0 && yMinBox <= 1) &&
          (xMaxBox >= 0 && xMaxBox <= 1) &&
          (yMaxBox >= 0 && yMaxBox <= 1),
      "Bounding box values must be in the range [0, 1]",
    );

    // Extract bounding box values
    final String xMin =
        xMinBox.clamp(0.0, 0.999999).toStringAsFixed(5).substring(2);
    final String yMin =
        yMinBox.clamp(0.0, 0.999999).toStringAsFixed(5).substring(2);
    final String xMax =
        xMaxBox.clamp(0.0, 0.999999).toStringAsFixed(5).substring(2);
    final String yMax =
        yMaxBox.clamp(0.0, 0.999999).toStringAsFixed(5).substring(2);

    // Convert the bounding box values to string and concatenate
    final String rawID = "${xMin}_${yMin}_${xMax}_$yMax";

    // Hash the concatenated string using SHA256
    final digest = sha256.convert(utf8.encode(rawID));

    // Return the hexadecimal representation of the hash
    return fileID.toString() + '_' + digest.toString();
  }

  /// This method is used to generate a faceID for a face detection that was manually added by the user.
  static String toFaceIDEmpty({required int fileID}) {
    return fileID.toString() + '_0';
  }

  /// This method is used to check if a faceID corresponds to a manually added face detection and not an actual face detection.
  static bool isFaceIDEmpty(String faceID) {
    return faceID.split('_')[1] == '0';
  }

  @override
  String toString() {
    return 'FaceDetectionRelative( with relative coordinates: \n score: $score \n Box: xMinBox: $xMinBox, yMinBox: $yMinBox, xMaxBox: $xMaxBox, yMaxBox: $yMaxBox, \n Keypoints: leftEye: $leftEye, rightEye: $rightEye, nose: $nose, leftMouth: $leftMouth, rightMouth: $rightMouth \n )';
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'box': box,
      'allKeypoints': allKeypoints,
    };
  }

  factory FaceDetectionRelative.fromJson(Map<String, dynamic> json) {
    return FaceDetectionRelative(
      score: (json['score'] as num).toDouble(),
      box: List<double>.from(json['box']),
      allKeypoints: (json['allKeypoints'] as List)
          .map((item) => List<double>.from(item))
          .toList(),
    );
  }

  @override

  /// The width of the bounding box of the face detection, in relative range [0, 1].
  double get width => xMaxBox - xMinBox;
  @override

  /// The height of the bounding box of the face detection, in relative range [0, 1].
  double get height => yMaxBox - yMinBox;
}

/// This class represents a face detection with absolute coordinates in pixels, in the range [0, imageWidth] for the horizontal coordinates and [0, imageHeight] for the vertical coordinates.
/// The pattern for the coordinates is always [x, y], where x is the horizontal coordinate and y is the vertical coordinate.
///
/// The [score] attribute is a double representing the confidence of the face detection.
///
/// The [box] attribute is a list of 4 integers, representing the coordinates of the bounding box of the face detection.
/// The four values of the box in order are: [xMinBox, yMinBox, xMaxBox, yMaxBox].
///
/// The [allKeypoints] attribute is a list of 6 lists of 2 integers, representing the coordinates of the keypoints of the face detection.
/// The six lists of two values in order are: [leftEye, rightEye, nose, mouth, leftEar, rightEar]. Again, all in [x, y] order.
class FaceDetectionAbsolute extends Detection {
  final List<double> box;
  final List<List<double>> allKeypoints;

  double get xMinBox => box[0];
  double get yMinBox => box[1];
  double get xMaxBox => box[2];
  double get yMaxBox => box[3];

  List<double> get leftEye => allKeypoints[0];
  List<double> get rightEye => allKeypoints[1];
  List<double> get nose => allKeypoints[2];
  List<double> get leftMouth => allKeypoints[3];
  List<double> get rightMouth => allKeypoints[4];

  FaceDetectionAbsolute({
    required double score,
    required this.box,
    required this.allKeypoints,
  }) : super(score: score);

  factory FaceDetectionAbsolute._zero() {
    return FaceDetectionAbsolute(
      score: 0,
      box: <double>[0, 0, 0, 0],
      allKeypoints: <List<double>>[
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
      ],
    );
  }

  FaceDetectionAbsolute.defaultInitialization()
      : box = const <double>[0, 0, 0, 0],
        allKeypoints = const <List<double>>[
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0],
        ],
        super.empty();

  @override
  String toString() {
    return 'FaceDetectionAbsolute( with absolute coordinates: \n score: $score \n Box: xMinBox: $xMinBox, yMinBox: $yMinBox, xMaxBox: $xMaxBox, yMaxBox: $yMaxBox, \n Keypoints: leftEye: $leftEye, rightEye: $rightEye, nose: $nose, leftMouth: $leftMouth, rightMouth: $rightMouth \n )';
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'box': box,
      'allKeypoints': allKeypoints,
    };
  }

  factory FaceDetectionAbsolute.fromJson(Map<String, dynamic> json) {
    return FaceDetectionAbsolute(
      score: (json['score'] as num).toDouble(),
      box: List<double>.from(json['box']),
      allKeypoints: (json['allKeypoints'] as List)
          .map((item) => List<double>.from(item))
          .toList(),
    );
  }

  static FaceDetectionAbsolute empty = FaceDetectionAbsolute._zero();

  @override

  /// The width of the bounding box of the face detection, in number of pixels, range [0, imageWidth].
  double get width => xMaxBox - xMinBox;
  @override

  /// The height of the bounding box of the face detection, in number of pixels, range [0, imageHeight].
  double get height => yMaxBox - yMinBox;
}

List<FaceDetectionAbsolute> relativeToAbsoluteDetections({
  required List<FaceDetectionRelative> relativeDetections,
  required int imageWidth,
  required int imageHeight,
}) {
  final numberOfDetections = relativeDetections.length;
  final absoluteDetections = List<FaceDetectionAbsolute>.filled(
    numberOfDetections,
    FaceDetectionAbsolute._zero(),
  );
  for (var i = 0; i < relativeDetections.length; i++) {
    final relativeDetection = relativeDetections[i];
    final absoluteDetection = relativeDetection.toAbsolute(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    absoluteDetections[i] = absoluteDetection;
  }

  return absoluteDetections;
}

/// Returns an enlarged version of the [box] by a factor of [factor].
List<double> getEnlargedRelativeBox(List<double> box, [double factor = 2]) {
  final boxCopy = List<double>.from(box, growable: false);
  // The four values of the box in order are: [xMinBox, yMinBox, xMaxBox, yMaxBox].

  final width = boxCopy[2] - boxCopy[0];
  final height = boxCopy[3] - boxCopy[1];

  boxCopy[0] -= width * (factor - 1) / 2;
  boxCopy[1] -= height * (factor - 1) / 2;
  boxCopy[2] += width * (factor - 1) / 2;
  boxCopy[3] += height * (factor - 1) / 2;

  return boxCopy;
}
