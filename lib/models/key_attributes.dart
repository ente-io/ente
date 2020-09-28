import 'dart:convert';

class KeyAttributes {
  final String passphraseHash;
  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;

  KeyAttributes({
    this.passphraseHash,
    this.kekSalt,
    this.encryptedKey,
    this.keyDecryptionNonce,
  });

  KeyAttributes copyWith({
    String passphraseHash,
    String kekSalt,
    String encryptedKey,
    String keyDecryptionNonce,
  }) {
    return KeyAttributes(
      passphraseHash: passphraseHash ?? this.passphraseHash,
      kekSalt: kekSalt ?? this.kekSalt,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce: keyDecryptionNonce ?? this.keyDecryptionNonce,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passphraseHash': passphraseHash,
      'kekSalt': kekSalt,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
    };
  }

  factory KeyAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return KeyAttributes(
      passphraseHash: map['passphraseHash'],
      kekSalt: map['kekSalt'],
      encryptedKey: map['encryptedKey'],
      keyDecryptionNonce: map['keyDecryptionNonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyAttributes.fromJson(String source) =>
      KeyAttributes.fromMap(json.decode(source));

  @override
  String toString() {
    return 'KeyAttributes(passphraseHash: $passphraseHash, kekSalt: $kekSalt, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is KeyAttributes &&
        o.passphraseHash == passphraseHash &&
        o.kekSalt == kekSalt &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce;
  }

  @override
  int get hashCode {
    return passphraseHash.hashCode ^
        kekSalt.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode;
  }
}
