import "dart:convert";

import "package:objectbox/objectbox.dart";

@Entity()
class Embedding {
  @Id(assignable: true)
  final int fileID;
  final String model;
  final List<double> embedding;
  int? updationTime;

  Embedding({
    required this.fileID,
    required this.model,
    required this.embedding,
    this.updationTime,
  });

  static List<double> decodeEmbedding(String embedding) {
    return List<double>.from(jsonDecode(embedding) as List);
  }

  static String encodeEmbedding(List<double> embedding) {
    return jsonEncode(embedding);
  }
}
