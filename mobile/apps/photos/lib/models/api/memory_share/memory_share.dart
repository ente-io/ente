enum MemoryShareType {
  share,
  lane;

  static MemoryShareType fromString(String value) {
    switch (value) {
      case 'lane':
        return MemoryShareType.lane;
      default:
        return MemoryShareType.share;
    }
  }
}

class MemoryShare {
  final int id;
  final MemoryShareType type;
  final String? metadataCipher;
  final String? metadataNonce;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String accessToken;
  final bool isDeleted;
  final int createdAt;
  final int? updatedAt;
  final String url;

  MemoryShare({
    required this.id,
    required this.type,
    this.metadataCipher,
    this.metadataNonce,
    required this.encryptedKey,
    required this.keyDecryptionNonce,
    required this.accessToken,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
    required this.url,
  });

  factory MemoryShare.fromJson(Map<String, dynamic> json) {
    return MemoryShare(
      id: json['id'] as int,
      type: MemoryShareType.fromString(json['type'] as String? ?? 'share'),
      metadataCipher: json['metadataCipher'] as String?,
      metadataNonce: json['metadataNonce'] as String?,
      encryptedKey: json['encryptedKey'] as String,
      keyDecryptionNonce: json['keyDecryptionNonce'] as String,
      accessToken: json['accessToken'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'metadataCipher': metadataCipher,
      'metadataNonce': metadataNonce,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'accessToken': accessToken,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'url': url,
    };
  }
}

class MemoryShareFileItem {
  final int fileID;
  final String encryptedKey;
  final String keyDecryptionNonce;

  MemoryShareFileItem({
    required this.fileID,
    required this.encryptedKey,
    required this.keyDecryptionNonce,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileID': fileID,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
    };
  }
}
