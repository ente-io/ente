/// Bounding box of a face. 
/// 
/// [`x`] and [y] are the coordinates of the top left corner of the box, so the minimim values
/// [width] and [height] are the width and height of the box.
/// All values are in absolute pixels relative to the original image size.
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
      x: (json['x'] is int
          ? (json['x'] as int).toDouble()
          : json['x'] as double),
      y: (json['y'] is int
          ? (json['y'] as int).toDouble()
          : json['y'] as double),
      width: (json['width'] is int
          ? (json['width'] as int).toDouble()
          : json['width'] as double),
      height: (json['height'] is int
          ? (json['height'] as int).toDouble()
          : json['height'] as double),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}
