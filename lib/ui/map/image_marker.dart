import "package:photos/models/file.dart";

class ImageMarker {
  final File imageFile;
  final double latitude;
  final double longitude;

  ImageMarker({
    required this.imageFile,
    required this.latitude,
    required this.longitude,
  });
}
