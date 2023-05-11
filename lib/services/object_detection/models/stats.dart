/// Bundles different elapsed times
class Stats {
  /// Total time taken in the isolate where the inference runs
  final int totalPredictTime;

  /// [totalPredictTime] + communication overhead time
  /// between main isolate and another isolate
  final int totalElapsedTime;

  /// Time for which inference runs
  final int inferenceTime;

  /// Time taken to pre-process the image
  final int preProcessingTime;

  Stats(
    this.totalPredictTime,
    this.totalElapsedTime,
    this.inferenceTime,
    this.preProcessingTime,
  );

  @override
  String toString() {
    return 'Stats{totalPredictTime: $totalPredictTime, totalElapsedTime: $totalElapsedTime, inferenceTime: $inferenceTime, preProcessingTime: $preProcessingTime}';
  }
}
