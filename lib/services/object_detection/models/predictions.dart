import "package:photos/services/object_detection/models/recognition.dart";
import "package:photos/services/object_detection/models/stats.dart";

class Predictions {
  final List<Recognition> recognitions;
  final Stats stats;

  Predictions(this.recognitions, this.stats);
}
