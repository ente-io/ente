import "dart:typed_data";

class CollectionFileEntry {
  final int collectionID;
  final int fileID;
  final Uint8List fileKey;
  final Uint8List fileKeyNonce;
  final int updatedAt;
  final int createdAt;
  final bool isDeleted;

  CollectionFileEntry({
    required this.collectionID,
    required this.fileID,
    required this.fileKey,
    required this.fileKeyNonce,
    required this.updatedAt,
    required this.createdAt,
    required this.isDeleted,
  });
}
