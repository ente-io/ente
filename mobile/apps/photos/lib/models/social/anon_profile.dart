/// Decrypted anonymous user profile stored locally.
///
/// Stores the decrypted display name payload for anonymous users who interact
/// via shared album links.
class AnonProfile {
  /// The anonymous user ID (e.g., "anon_abc123")
  final String anonUserID;

  /// The collection this profile belongs to
  final int collectionID;

  /// The decrypted display name payload as raw string.
  final String data;

  /// When the profile was created (microseconds since epoch)
  final int createdAt;

  /// When the profile was last updated (microseconds since epoch)
  final int updatedAt;

  AnonProfile({
    required this.anonUserID,
    required this.collectionID,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Extracts the trimmed display name from the payload.
  String? get displayName {
    final trimmed = data.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
