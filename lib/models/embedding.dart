import "dart:convert";

class Embedding {
  final int id;
  final List<double> embedding;
  final int updationTime;

  Embedding(this.id, this.embedding, this.updationTime);

  static List<double> decodeEmbedding(String embedding) {
    return List<double>.from(jsonDecode(embedding) as List);
  }

  static String encodeEmbedding(List<double> embedding) {
    return jsonEncode(embedding);
  }
}
