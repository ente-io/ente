import "package:photos/models/file.dart";

abstract class Filter {
  bool filter(File file);
}
