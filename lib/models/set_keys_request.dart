import 'dart:convert';

class SetKeysRequest {
  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final int memLimit;
  final int opsLimit;

  SetKeysRequest({
    this.kekSalt,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.memLimit,
    this.opsLimit,
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

  factory SetKeysRequest.fromMap(Map<String, dynamic> map) {
    return SetKeysRequest(
      kekSalt: map['kekSalt'],
      encryptedKey: map['encryptedKey'],
      keyDecryptionNonce: map['keyDecryptionNonce'],
      memLimit: map['memLimit'],
      opsLimit: map['opsLimit'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SetKeysRequest.fromJson(String source) =>
      SetKeysRequest.fromMap(json.decode(source));
}
