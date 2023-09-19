import 'package:photos/models/file/file.dart';

class ImageMarker {
  final EnteFile imageFile;
  final double latitude;
  final double longitude;

  ImageMarker({
    required this.imageFile,
    required this.latitude,
    required this.longitude,
  });
}
