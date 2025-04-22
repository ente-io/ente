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

  CollectionFileEntry.fromMap(Map<String, dynamic> map)
      : collectionID = map["collection_id"] as int,
        fileID = map["file_id"] as int,
        fileKey = map["enc_key"] as Uint8List,
        fileKeyNonce = map["enc_key_nonce"] as Uint8List,
        updatedAt = map["updated_at"] as int,
        createdAt = map["created_at"] as int,
        isDeleted = (map["is_deleted"] as int) == 1;
}
