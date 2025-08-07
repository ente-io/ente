import "dart:convert";
import "dart:typed_data";

import "package:photos/models/api/diff/trash_time.dart";
import "package:photos/models/file/remote/asset.dart";

class Info {
  final int fileSize;
  final int thumbSize;

  static Info? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Info(
      fileSize: json['fileSize'] ?? -1,
      thumbSize: json['thumbSize'] ?? -1,
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

class ApiFileItem {
  final int fileID;
  final int ownerID;
  final Uint8List? thumnailDecryptionHeader;
  final Uint8List? fileDecryptionHeader;
  final Metadata? metadata;
  final Metadata? privMagicMetadata;
  final Metadata? pubMagicMetadata;
  final Info? info;

  ApiFileItem({
    required this.fileID,
    required this.ownerID,
    this.thumnailDecryptionHeader,
    this.fileDecryptionHeader,
    this.metadata,
    this.privMagicMetadata,
    this.pubMagicMetadata,
    this.info,
  });

  factory ApiFileItem.deleted(int fileID, int ownerID) {
    return ApiFileItem(
      fileID: fileID,
      ownerID: ownerID,
    );
  }

  List<Object?> filesMetadataRowValues() {
    return [
      fileID,
      metadata?.toEncodedJson(),
      privMagicMetadata?.toEncodedJson(),
      pubMagicMetadata?.toEncodedJson(),
      info?.toEncodedJson(),
    ];
  }

  RemoteAsset toRemoteAsset() {
    return RemoteAsset.fromMetadata(
      id: fileID,
      ownerID: ownerID,
      thumbHeader: thumnailDecryptionHeader!,
      fileHeader: fileDecryptionHeader!,
      metadata: metadata!,
      privateMetadata: privMagicMetadata,
      publicMetadata: pubMagicMetadata,
      info: info,
    );
  }

  String get title =>
      pubMagicMetadata?.data['editedName'] ?? metadata?.data['title'] ?? "";

  String get nonEditedTitle {
    return metadata?.data['title'] ?? "";
  }

  String? get localID => metadata?.data['localID'];

  String? get deviceFolder => metadata?.data['deviceFolder'];

  int get creationTime =>
      pubMagicMetadata?.data['editedTime'] ??
      metadata?.data['creationTime'] ??
      0;

  int get modificationTime =>
      metadata?.data['modificationTime'] ?? creationTime;

  // note: during remote to local sync, older live photo hash format from desktop
  // is already converted to the new format
  String? get hash => metadata?.data['hash'];

  int get fileSize => info?.fileSize ?? -1;
}

class DiffItem {
  final int collectionID;
  final bool isDeleted;
  final Uint8List? encFileKey;
  final Uint8List? encFileKeyNonce;
  final int updatedAt;
  final int? createdAt;
  final ApiFileItem fileItem;
  final TrashTime? trashTime;

  DiffItem({
    required this.collectionID,
    required this.isDeleted,
    required this.updatedAt,
    required this.fileItem,
    this.createdAt,
    this.encFileKey,
    this.encFileKeyNonce,
    this.trashTime,
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
    ];
  }

  List<Object?> trashRowValues() {
    return [
      fileID,
      fileItem.ownerID,
      collectionID,
      encFileKey,
      encFileKeyNonce,
      fileItem.fileDecryptionHeader,
      fileItem.thumnailDecryptionHeader,
      fileItem.metadata?.toEncodedJson(),
      fileItem.privMagicMetadata?.toEncodedJson(),
      fileItem.pubMagicMetadata?.toEncodedJson(),
      fileItem.info?.toEncodedJson(),
      trashTime!.createdAt,
      trashTime!.updatedAt,
      trashTime!.deleteBy,
    ];
  }
}
