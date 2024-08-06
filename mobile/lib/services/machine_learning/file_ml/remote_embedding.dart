import "dart:convert";

class FileDataEntity {
  final int fileID;
  final String type;
  final String encryptedData;
  final String decryptionHeader;
  final int updatedAt;

  FileDataEntity({
    required this.fileID,
    required this.type,
    required this.encryptedData,
    required this.decryptionHeader,
    required this.updatedAt,
  });

  factory FileDataEntity.fromMap(Map<String, dynamic> map) {
    return FileDataEntity(
      fileID: map['fileID']?.toInt() ?? 0,
      type: map['type'] ?? '',
      encryptedData: map['encryptedData'] ?? '',
      decryptionHeader: map['decryptionHeader'] ?? '',
      updatedAt: map['updatedAt']?.toInt() ?? 0,
    );
  }

  factory FileDataEntity.fromJson(String source) =>
      FileDataEntity.fromMap(json.decode(source));
}
