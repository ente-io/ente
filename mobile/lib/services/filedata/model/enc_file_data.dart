import "dart:convert";

class EncryptedFileData {
  final int fileID;
  final String type;
  final String encryptedData;
  final String decryptionHeader;

  EncryptedFileData({
    required this.fileID,
    required this.type,
    required this.encryptedData,
    required this.decryptionHeader,
  });

  factory EncryptedFileData.fromMap(Map<String, dynamic> map) {
    return EncryptedFileData(
      fileID: map['fileID']?.toInt() ?? 0,
      type: map['type'] ?? '',
      encryptedData: map['encryptedData'] ?? '',
      decryptionHeader: map['decryptionHeader'] ?? '',
    );
  }

  factory EncryptedFileData.fromJson(String source) =>
      EncryptedFileData.fromMap(json.decode(source));
}
