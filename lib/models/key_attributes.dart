import 'dart:convert';

class KeyAttributes {
  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String publicKey;
  final String encryptedSecretKey;
  final String secretKeyDecryptionNonce;
  final int memLimit;
  final int opsLimit;

  KeyAttributes(
    this.kekSalt,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.publicKey,
    this.encryptedSecretKey,
    this.secretKeyDecryptionNonce,
    this.memLimit,
    this.opsLimit,
  );

  Map<String, dynamic> toMap() {
    return {
      'kekSalt': kekSalt,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'publicKey': publicKey,
      'encryptedSecretKey': encryptedSecretKey,
      'secretKeyDecryptionNonce': secretKeyDecryptionNonce,
      'memLimit': memLimit,
      'opsLimit': opsLimit,
    };
  }

  factory KeyAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return KeyAttributes(
      map['kekSalt'],
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['publicKey'],
      map['encryptedSecretKey'],
      map['secretKeyDecryptionNonce'],
      map['memLimit'],
      map['opsLimit'],
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyAttributes.fromJson(String source) =>
      KeyAttributes.fromMap(json.decode(source));
}
