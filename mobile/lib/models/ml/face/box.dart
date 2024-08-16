/// Bounding box of a face.
///
/// [ x] and [y] are the minimum coordinates, so the top left corner of the box.
/// [width] and [height] are the width and height of the box.
///
/// WARNING: All values are relative to the original image size, so in the range [0, 1].
class FaceBox {
  final double x;
  final double y;
  final double width;
  final double height;

  FaceBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory FaceBox.fromJson(Map<String, dynamic> json) {
    return FaceBox(
      x: (json['x'] as double?) ?? (json['xMin'] as double),
      y: (json['y'] as double?) ?? (json['yMin'] as double),
      width: json['width'] as double,
      height: json['height'] as double,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}
