import 'dart:convert';

class KeyAttributes {
  final String kekSalt;
  final String kekHash;
  final String kekHashSalt;
  final String encryptedKey;
  final String encryptedKeyIV;

  KeyAttributes(
    this.kekSalt,
    this.kekHash,
    this.kekHashSalt,
    this.encryptedKey,
    this.encryptedKeyIV,
  );

  KeyAttributes copyWith({
    String kekSalt,
    String kekHash,
    String kekHashSalt,
    String encryptedKey,
    String encryptedKeyIV,
  }) {
    return KeyAttributes(
      kekSalt ?? this.kekSalt,
      kekHash ?? this.kekHash,
      kekHashSalt ?? this.kekHashSalt,
      encryptedKey ?? this.encryptedKey,
      encryptedKeyIV ?? this.encryptedKeyIV,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kekSalt': kekSalt,
      'kekHash': kekHash,
      'kekHashSalt': kekHashSalt,
      'encryptedKey': encryptedKey,
      'encryptedKeyIV': encryptedKeyIV,
    };
  }

  factory KeyAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return KeyAttributes(
      map['kekSalt'],
      map['kekHash'],
      map['kekHashSalt'],
      map['encryptedKey'],
      map['encryptedKeyIV'],
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyAttributes.fromJson(String source) =>
      KeyAttributes.fromMap(json.decode(source));
}
