import "dart:typed_data";

class CollectionFileEntry {
  final int collectionID;
  final int fileID;
  final Uint8List encFileKey;
  final Uint8List encFileKeyNonce;
  final int updatedAt;
  final int createdAt;

  CollectionFileEntry({
    required this.collectionID,
    required this.fileID,
    required this.encFileKey,
    required this.encFileKeyNonce,
    required this.updatedAt,
    required this.createdAt,
  });

  CollectionFileEntry.fromMap(Map<String, dynamic> map)
      : collectionID = map["collection_id"] as int,
        fileID = map["file_id"] as int,
        encFileKey = map["enc_key"] as Uint8List,
        encFileKeyNonce = map["enc_key_nonce"] as Uint8List,
        updatedAt = map["updated_at"] as int,
        createdAt = map["created_at"] as int;
}
