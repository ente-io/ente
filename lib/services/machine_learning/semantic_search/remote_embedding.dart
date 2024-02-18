import "dart:convert";

class RemoteEmbedding {
  final int fileID;
  final String model;
  final String encryptedEmbedding;
  final String decryptionHeader;
  final int updatedAt;

  RemoteEmbedding({
    required this.fileID,
    required this.model,
    required this.encryptedEmbedding,
    required this.decryptionHeader,
    required this.updatedAt,
  });

  factory RemoteEmbedding.fromMap(Map<String, dynamic> map) {
    return RemoteEmbedding(
      fileID: map['fileID']?.toInt() ?? 0,
      model: map['model'] ?? '',
      encryptedEmbedding: map['encryptedEmbedding'] ?? '',
      decryptionHeader: map['decryptionHeader'] ?? '',
      updatedAt: map['updatedAt']?.toInt() ?? 0,
    );
  }

  factory RemoteEmbedding.fromJson(String source) =>
      RemoteEmbedding.fromMap(json.decode(source));
}

class RemoteEmbeddings {
  final List<RemoteEmbedding> embeddings;
  final bool hasMore;

  RemoteEmbeddings(this.embeddings, this.hasMore);
}
