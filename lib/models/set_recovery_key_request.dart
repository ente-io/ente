import 'dart:convert';

class SetRecoveryKeyRequest {
  final String masterKeyEncryptedWithRecoveryKey;
  final String masterKeyDecryptionNonce;
  final String recoveryKeyEncryptedWithMasterKey;
  final String recoveryKeyDecryptionNonce;

  SetRecoveryKeyRequest(
    this.masterKeyEncryptedWithRecoveryKey,
    this.masterKeyDecryptionNonce,
    this.recoveryKeyEncryptedWithMasterKey,
    this.recoveryKeyDecryptionNonce,
  );

  Map<String, dynamic> toMap() {
    return {
      'masterKeyEncryptedWithRecoveryKey': masterKeyEncryptedWithRecoveryKey,
      'masterKeyDecryptionNonce': masterKeyDecryptionNonce,
      'recoveryKeyEncryptedWithMasterKey': recoveryKeyEncryptedWithMasterKey,
      'recoveryKeyDecryptionNonce': recoveryKeyDecryptionNonce,
    };
  }

  factory SetRecoveryKeyRequest.fromMap(Map<String, dynamic> map) {
    return SetRecoveryKeyRequest(
      map['masterKeyEncryptedWithRecoveryKey'],
      map['masterKeyDecryptionNonce'],
      map['recoveryKeyEncryptedWithMasterKey'],
      map['recoveryKeyDecryptionNonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SetRecoveryKeyRequest.fromJson(String source) =>
      SetRecoveryKeyRequest.fromMap(json.decode(source));
}
