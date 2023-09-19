/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  final int id;

  /// Label of the result
  final String label;

  /// Confidence [0.0, 1.0]
  final double score;

  Recognition(this.id, this.label, this.score);

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score)';
  }
}
