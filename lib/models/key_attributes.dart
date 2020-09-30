import 'dart:convert';

class KeyAttributes {
  final String kekSalt;
  final String kekHash;
  final String encryptedKey;
  final String keyDecryptionNonce;

  KeyAttributes(
    this.kekSalt,
    this.kekHash,
    this.encryptedKey,
    this.keyDecryptionNonce,
  );

  KeyAttributes copyWith({
    String kekSalt,
    String kekHash,
    String encryptedKey,
    String keyDecryptionNonce,
  }) {
    return KeyAttributes(
      kekSalt ?? this.kekSalt,
      kekHash ?? this.kekHash,
      encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce ?? this.keyDecryptionNonce,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kekSalt': kekSalt,
      'kekHash': kekHash,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
    };
  }

  factory KeyAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return KeyAttributes(
      map['kekSalt'],
      map['kekHash'],
      map['encryptedKey'],
      map['keyDecryptionNonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyAttributes.fromJson(String source) =>
      KeyAttributes.fromMap(json.decode(source));

  @override
  String toString() {
    return 'KeyAttributes(kekSalt: $kekSalt, kekHash: $kekHash, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is KeyAttributes &&
        o.kekSalt == kekSalt &&
        o.kekHash == kekHash &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce;
  }

  @override
  int get hashCode {
    return kekSalt.hashCode ^
        kekHash.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode;
  }
}
