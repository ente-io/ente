import "dart:convert";

class Embedding {
  final int fileID;
  final List<double> embedding;
  int? updationTime;

  bool get isEmpty => embedding.isEmpty;

  Embedding({
    required this.fileID,
    required this.embedding,
    this.updationTime,
  });

  factory Embedding.empty(int fileID) {
    return Embedding(
      fileID: fileID,
      embedding: <double>[],
    );
  }

  static List<double> decodeEmbedding(String embedding) {
    return List<double>.from(jsonDecode(embedding) as List);
  }

  static String encodeEmbedding(List<double> embedding) {
    return jsonEncode(embedding);
  }
}
