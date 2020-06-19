import 'package:photos/models/file.dart';
import 'package:path/path.dart';

String getJPGFileNameForHEIC(File file) {
  return extension(file.title) == ".HEIC"
      ? basenameWithoutExtension(file.title) + ".JPG"
      : file.title;
}

String getHEICFileNameForJPG(File file) {
  return extension(file.title) == ".JPG"
      ? basenameWithoutExtension(file.title) + ".HEIC"
      : file.title;
}
