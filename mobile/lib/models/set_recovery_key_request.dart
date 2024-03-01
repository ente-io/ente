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
}
