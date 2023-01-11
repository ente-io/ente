import 'dart:convert';

class KeyAttributes {
  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String publicKey;
  final String encryptedSecretKey;
  final String secretKeyDecryptionNonce;

  // Note: For users who signed in before we started storing memLimit and
  // optsLimit, these fields will be null. To update these values, they need to
  // either log in again or client needs to fetch these values from server.
  // (internal monologue: Hopefully, the mem/ops limit used to generate the
  // key is same as it's stored on the server)
  // https://github.com/ente-io/photos-app/commit/8cb7f885b343f2c796e4cc9ce1f7d70c9a13a003#diff-02f19d9ee0a60ee9674372d2c780da5d5284128dc9ea65dec6cdcddfc559ebb3
  final int? memLimit;
  final int? opsLimit;
  // The recovery key attributes can be null for old users who haven't generated
  // their recovery keys yet.
  // https://github.com/ente-io/photos-app/commit/d7acc95855c62ecdf2a29c4102e648105e17bd8c#diff-02f19d9ee0a60ee9674372d2c780da5d5284128dc9ea65dec6cdcddfc559ebb3
  final String? masterKeyEncryptedWithRecoveryKey;
  final String? masterKeyDecryptionNonce;
  final String? recoveryKeyEncryptedWithMasterKey;
  final String? recoveryKeyDecryptionNonce;

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
