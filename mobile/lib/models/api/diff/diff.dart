import "dart:convert";
import "dart:typed_data";

class Info {
  final int fileSize;
  final int thumbSize;

  static Info? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Info(
      fileSize: json['fileSize'] ?? 0,
      thumbSize: json['thumbSize'] ?? 0,
    );
  }

  Info({required this.fileSize, required this.thumbSize});

  Map<String, dynamic> toJson() {
    return {
      'fileSize': fileSize,
      'thumbSize': thumbSize,
    };
  }

  String toEncodedJson() {
    return jsonEncode(toJson());
  }

  static Info? fromEncodedJson(String? encodedJson) {
    if (encodedJson == null) return null;
    return Info.fromJson(jsonDecode(encodedJson));
  }
}

class Metadata {
  final Map<String, dynamic> data;
  final int version;

  Metadata({required this.data, required this.version});

  static fromJson(Map<String, dynamic> json) {
    if (json.isEmpty || json['data'] == null) return null;
    return Metadata(
      data: json['data'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'version': version,
    };
  }

  static Metadata? fromEncodedJson(String? encodedJson) {
    if (encodedJson == null) return null;
    return Metadata.fromJson(jsonDecode(encodedJson));
  }

  String toEncodedJson() {
    return jsonEncode(toJson());
  }
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

  List<Object?> rowValues() {
    return [
      fileID,
      ownerID,
      fileDecryotionHeader,
      thumnailDecryptionHeader,
      metadata?.toEncodedJson(),
      magicMetadata?.toEncodedJson(),
      pubMagicMetadata?.toEncodedJson(),
      info?.toEncodedJson(),
    ];
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

  List<Object?> collectionFileRowValues() {
    return [
      collectionID,
      fileID,
      encFileKey,
      encFileKeyNonce,
      createdAt,
      updatedAt,
      isDeleted ? 1 : 0,
    ];
  }
}
