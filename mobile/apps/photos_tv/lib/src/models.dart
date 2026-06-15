import 'dart:convert';
import 'dart:typed_data';

/// Pairing registration generated for this TV.
class Registration {
  /// Pairing code shown on TV.
  final String pairingCode;

  /// Public key registered with API.
  final String publicKey;

  /// Private key kept on TV.
  final String privateKey;

  /// Creates pairing registration.
  const Registration({
    required this.pairingCode,
    required this.publicKey,
    required this.privateKey,
  });
}

/// Cast payload received after pairing.
class CastPayload {
  /// Token used for cast API requests.
  final String castToken;

  /// Paired collection ID.
  final int collectionID;

  /// Collection key encrypted for cast receiver.
  final String collectionKey;

  /// Creates cast payload.
  const CastPayload({
    required this.castToken,
    required this.collectionID,
    required this.collectionKey,
  });

  /// Creates cast payload from JSON.
  factory CastPayload.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return CastPayload(
      castToken: map['castToken'] as String,
      collectionID: map['collectionID'] as int,
      collectionKey: map['collectionKey'] as String,
    );
  }
}

/// Cast file metadata needed for slideshow playback.
class CastFile {
  /// File ID.
  final int id;

  /// Ente file type.
  final int fileType;

  /// Decrypted file key.
  final Uint8List key;

  /// Preview metadata.
  final Map<String, dynamic> preview;

  /// Creates cast file.
  const CastFile({
    required this.id,
    required this.fileType,
    required this.key,
    required this.preview,
  });

  /// Whether file can be shown as an image.
  bool get isImage => fileType == 0 || fileType == 2;

  /// Creates cast file from remote metadata.
  static CastFile? fromRemote(
    Map<String, dynamic> item,
    Uint8List key,
    Uint8List metadataBytes,
  ) {
    final metadata = jsonDecode(utf8.decode(metadataBytes));
    if (metadata is! Map<String, dynamic>) return null;
    final preview = item['thumbnail'] as Map<String, dynamic>?;
    if (preview == null) return null;
    return CastFile(
      id: item['id'] as int,
      fileType: metadata['fileType'] as int,
      key: key,
      preview: preview,
    );
  }
}
