import 'dart:convert';

class DecryptionParams {
  final String encryptedKey;
  final String keyDecryptionNonce;
  String header;
  String nonce;

  DecryptionParams({
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.header,
    this.nonce,
  });

  DecryptionParams copyWith({
    String encryptedKey,
    String keyDecryptionNonce,
    String header,
    String nonce,
  }) {
    return DecryptionParams(
      encryptedKey: encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce: keyDecryptionNonce ?? this.keyDecryptionNonce,
      header: header ?? this.header,
      nonce: nonce ?? this.nonce,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'header': header,
      'nonce': nonce,
    };
  }

  factory DecryptionParams.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return DecryptionParams(
      encryptedKey: map['encryptedKey'],
      keyDecryptionNonce: map['keyDecryptionNonce'],
      header: map['header'],
      nonce: map['nonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DecryptionParams.fromJson(String source) {
    if (source == null) {
      return null;
    }
    return DecryptionParams.fromMap(json.decode(source));
  }

  @override
  String toString() {
    return 'DecryptionParams(encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, header: $header, nonce: $nonce)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is DecryptionParams &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce &&
        o.header == header &&
        o.nonce == nonce;
  }

  @override
  int get hashCode {
    return encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        header.hashCode ^
        nonce.hashCode;
  }
}
