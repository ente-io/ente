import 'package:image/image.dart' as imageLib;
import "package:photos/services/object_detection/models/predictions.dart";

abstract class Classifier {
  Predictions? predict(imageLib.Image image);
}
