import 'package:photos/models/photo.dart';
import 'package:path/path.dart';

String getJPGFileNameForHEIC(Photo photo) {
  return extension(photo.title) == ".HEIC"
      ? basenameWithoutExtension(photo.title) + ".JPG"
      : photo.title;
}

String getHEICFileNameForJPG(Photo photo) {
  return extension(photo.title) == ".JPG"
      ? basenameWithoutExtension(photo.title) + ".HEIC"
      : photo.title;
}
