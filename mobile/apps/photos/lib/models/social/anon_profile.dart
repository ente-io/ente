/// Decrypted anonymous user profile stored locally.
///
/// Stores the decrypted display name for anonymous users who interact
/// via shared album links.
class AnonProfile {
  /// The anonymous user ID (e.g., "anon_abc123")
  final String anonUserID;

  /// The collection this profile belongs to
  final int collectionID;

  /// The decrypted display name
  final String displayName;

  /// When the profile was created (microseconds since epoch)
  final int createdAt;

  /// When the profile was last updated (microseconds since epoch)
  final int updatedAt;

  AnonProfile({
    required this.anonUserID,
    required this.collectionID,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });
}
