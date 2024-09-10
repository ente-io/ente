import "dart:convert";

import "package:ml_linalg/vector.dart";

class EmbeddingVector {
  final int fileID;
  final Vector vector;

  bool get isEmpty => vector.isEmpty;

  EmbeddingVector({
    required this.fileID,
    required List<double> embedding,
  }) : vector = Vector.fromList(embedding);

  static Vector decodeEmbedding(String embedding) {
    return Vector.fromList(List<double>.from(jsonDecode(embedding) as List));
  }

  static String encodeEmbedding(Vector embedding) {
    return jsonEncode(embedding.toList());
  }
}
