/// Bounding box of a face.
///
/// [xMin] and [yMin] are the coordinates of the top left corner of the box, and
/// [width] and [height] are the width and height of the box.
///
/// WARNING: All values are relative to the original image size, so in the range [0, 1].
class FaceBox {
  final double xMin;
  final double yMin;
  final double width;
  final double height;

  FaceBox({
    required this.xMin,
    required this.yMin,
    required this.width,
    required this.height,
  });

  factory FaceBox.fromJson(Map<String, dynamic> json) {
    return FaceBox(
      xMin: (json['xMin'] is int
          ? (json['xMin'] as int).toDouble()
          : json['xMin'] as double),
      yMin: (json['yMin'] is int
          ? (json['yMin'] as int).toDouble()
          : json['yMin'] as double),
      width: (json['width'] is int
          ? (json['width'] as int).toDouble()
          : json['width'] as double),
      height: (json['height'] is int
          ? (json['height'] as int).toDouble()
          : json['height'] as double),
    );
  }

  Map<String, dynamic> toJson() => {
        'xMin': xMin,
        'yMin': yMin,
        'width': width,
        'height': height,
      };
}

/// Bounding box of a face.
///
/// [xMin] and [yMin] are the coordinates of the top left corner of the box, and
/// [width] and [height] are the width and height of the box.
///
/// One unit is equal to one pixel in the original image.
class FaceBoxImage {
  final int xMin;
  final int yMin;
  final int width;
  final int height;

  FaceBoxImage({
    required this.xMin,
    required this.yMin,
    required this.width,
    required this.height,
  });
}
