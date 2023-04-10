import "package:photos/services/object_detection/models/recognition.dart";
import "package:photos/services/object_detection/models/stats.dart";

class Predictions {
  final List<Recognition>? recognitions;
  final Stats? stats;
  final Object? error;

  Predictions(
    this.recognitions,
    this.stats, {
    this.error,
  });
}
