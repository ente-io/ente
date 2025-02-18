class SetKeysRequest {
  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final int memLimit;
  final int opsLimit;

  SetKeysRequest({
    required this.kekSalt,
    required this.encryptedKey,
    required this.keyDecryptionNonce,
    required this.memLimit,
    required this.opsLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'kekSalt': kekSalt,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'memLimit': memLimit,
      'opsLimit': opsLimit,
    };
  }
}
