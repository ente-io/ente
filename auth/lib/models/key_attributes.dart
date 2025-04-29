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
  final String masterKeyEncryptedWithRecoveryKey;
  final String masterKeyDecryptionNonce;
  final String recoveryKeyEncryptedWithMasterKey;
  final String recoveryKeyDecryptionNonce;

  KeyAttributes(
    this.kekSalt,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.publicKey,
    this.encryptedSecretKey,
    this.secretKeyDecryptionNonce,
    this.memLimit,
    this.opsLimit,
    this.masterKeyEncryptedWithRecoveryKey,
    this.masterKeyDecryptionNonce,
    this.recoveryKeyEncryptedWithMasterKey,
    this.recoveryKeyDecryptionNonce,
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
      'masterKeyEncryptedWithRecoveryKey': masterKeyEncryptedWithRecoveryKey,
      'masterKeyDecryptionNonce': masterKeyDecryptionNonce,
      'recoveryKeyEncryptedWithMasterKey': recoveryKeyEncryptedWithMasterKey,
      'recoveryKeyDecryptionNonce': recoveryKeyDecryptionNonce,
    };
  }

  factory KeyAttributes.fromMap(Map<String, dynamic> map) {
    return KeyAttributes(
      map['kekSalt'],
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['publicKey'],
      map['encryptedSecretKey'],
      map['secretKeyDecryptionNonce'],
      map['memLimit'],
      map['opsLimit'],
      map['masterKeyEncryptedWithRecoveryKey'],
      map['masterKeyDecryptionNonce'],
      map['recoveryKeyEncryptedWithMasterKey'],
      map['recoveryKeyDecryptionNonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyAttributes.fromJson(String source) =>
      KeyAttributes.fromMap(json.decode(source));

  KeyAttributes copyWith({
    String? kekSalt,
    String? encryptedKey,
    String? keyDecryptionNonce,
    String? publicKey,
    String? encryptedSecretKey,
    String? secretKeyDecryptionNonce,
    int? memLimit,
    int? opsLimit,
    String? masterKeyEncryptedWithRecoveryKey,
    String? masterKeyDecryptionNonce,
    String? recoveryKeyEncryptedWithMasterKey,
    String? recoveryKeyDecryptionNonce,
  }) {
    return KeyAttributes(
      kekSalt ?? this.kekSalt,
      encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce ?? this.keyDecryptionNonce,
      publicKey ?? this.publicKey,
      encryptedSecretKey ?? this.encryptedSecretKey,
      secretKeyDecryptionNonce ?? this.secretKeyDecryptionNonce,
      memLimit ?? this.memLimit,
      opsLimit ?? this.opsLimit,
      masterKeyEncryptedWithRecoveryKey ??
          this.masterKeyEncryptedWithRecoveryKey,
      masterKeyDecryptionNonce ?? this.masterKeyDecryptionNonce,
      recoveryKeyEncryptedWithMasterKey ??
          this.recoveryKeyEncryptedWithMasterKey,
      recoveryKeyDecryptionNonce ?? this.recoveryKeyDecryptionNonce,
    );
  }
}
