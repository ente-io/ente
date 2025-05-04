import "package:photos/utils/standalone/parse.dart";

/// Bounding box of a face.
///
/// [x] and [y] are the top-left coordinates of the face box.
/// [width] and [height] are its size.
/// [check] is a confidence in case of closeness and matching.

class FaceBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final double check;

  FaceBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.check,
  });

  factory FaceBox.fromJson(Map<String, dynamic> json) {
    final double fallbackConfidence = 0.1; // Düşük güvenli öneri
    return FaceBox(
      x: parseIntOrDoubleAsDouble(json['x']) ??
         parseIntOrDoubleAsDouble(json['xMin'])!,
      y: parseIntOrDoubleAsDouble(json['y']) ??
         parseIntOrDoubleAsDouble(json['yMin'])!,
      width: parseIntOrDoubleAsDouble(json['width'])!,
      height: parseIntOrDoubleAsDouble(json['height'])!,
      check: parseIntOrDoubleAsDouble(json['check']) ?? fallbackConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'check': check,
  };
}
