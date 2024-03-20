import 'dart:math' show sqrt;

/// Calculates the cosine distance between two embeddings/vectors.
///
/// Throws an ArgumentError if the vectors are of different lengths or
/// if either of the vectors has a magnitude of zero.
double cosineDistance(List<double> vector1, List<double> vector2) {
  if (vector1.length != vector2.length) {
    throw ArgumentError('Vectors must be the same length');
  }

  double dotProduct = 0.0;
  double magnitude1 = 0.0;
  double magnitude2 = 0.0;

  for (int i = 0; i < vector1.length; i++) {
    dotProduct += vector1[i] * vector2[i];
    magnitude1 += vector1[i] * vector1[i];
    magnitude2 += vector2[i] * vector2[i];
  }

  magnitude1 = sqrt(magnitude1);
  magnitude2 = sqrt(magnitude2);

  // Avoid division by zero. This should never happen. If it does, then one of the vectors contains only zeros.
  if (magnitude1 == 0 || magnitude2 == 0) {
    throw ArgumentError('Vectors must not have a magnitude of zero');
  }

  final double similarity = dotProduct / (magnitude1 * magnitude2);

  // Cosine distance is the complement of cosine similarity
  return 1.0 - similarity;
}

// cosineDistForNormVectors calculates the cosine distance between two normalized embeddings/vectors.
@pragma('vm:entry-point')
double cosineDistForNormVectors(List<double> vector1, List<double> vector2) {
  if (vector1.length != vector2.length) {
    throw ArgumentError('Vectors must be the same length');
  }
  double dotProduct = 0.0;
  for (int i = 0; i < vector1.length; i++) {
    dotProduct += vector1[i] * vector2[i];
  }
  return 1.0 - dotProduct;
}

double calculateSqrDistance(List<double> v1, List<double> v2) {
  double sum = 0;
  for (int i = 0; i < v1.length; i++) {
    sum += (v1[i] - v2[i]) * (v1[i] - v2[i]);
  }
  return sqrt(sum);
}
