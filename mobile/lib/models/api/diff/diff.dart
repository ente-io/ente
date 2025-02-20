import "dart:typed_data";

class Info {
  final int fileSize;
  final int thumbnailSize;

  static Info? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Info(
      fileSize: json['fileSize'],
      thumbnailSize: json['thumbnailSize'],
    );
  }

  Info({required this.fileSize, required this.thumbnailSize});
}

class Metadata {
  final Map<String, dynamic> data;
  final int version;
  Metadata({required this.data, required this.version});
}

class FileItem {
  final int fileID;
  final int ownerID;
  final Uint8List? thumnailDecryptionHeader;
  final Uint8List? fileDecryotionHeader;
  final Metadata? metadata;
  final Metadata? magicMetadata;
  final Metadata? pubMagicMetadata;
  final Info? info;

  FileItem({
    required this.fileID,
    required this.ownerID,
    this.thumnailDecryptionHeader,
    this.fileDecryotionHeader,
    this.metadata,
    this.magicMetadata,
    this.pubMagicMetadata,
    this.info,
  });

  factory FileItem.deleted(int fileID, int ownerID) {
    return FileItem(
      fileID: fileID,
      ownerID: ownerID,
    );
  }
}

class CollectionFileItem {
  final int collectionID;
  final bool isDeleted;
  final Uint8List? encFileKey;
  final Uint8List? encFileKeyNonce;
  final int updatedAt;
  final int? createdAt;
  final FileItem fileItem;

  CollectionFileItem({
    required this.collectionID,
    required this.isDeleted,
    required this.updatedAt,
    required this.fileItem,
    this.createdAt,
    this.encFileKey,
    this.encFileKeyNonce,
  });
  int get fileID => fileItem.fileID;
}
