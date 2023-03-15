import 'package:image/image.dart' as image_lib;
import "package:photos/services/object_detection/models/predictions.dart";

abstract class Classifier {
  Predictions? predict(image_lib.Image image);
}
