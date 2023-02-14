/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  int id;

  /// Label of the result
  String label;

  /// Confidence [0.0, 1.0]
  double score;

  Recognition(this.id, this.label, this.score);

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score)';
  }
}
