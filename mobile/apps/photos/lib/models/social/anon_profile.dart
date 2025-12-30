import 'dart:convert';

/// Decrypted anonymous user profile stored locally.
///
/// Stores the decrypted profile data (JSON) for anonymous users who interact
/// via shared album links. The raw JSON is preserved for forward compatibility.
class AnonProfile {
  /// The anonymous user ID (e.g., "anon_abc123")
  final String anonUserID;

  /// The collection this profile belongs to
  final int collectionID;

  /// The decrypted profile data as raw JSON string.
  /// Format: {"userName": "..."}
  /// May contain additional fields in future versions.
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

  /// Extracts the display name from the JSON data.
  ///
  /// Returns the userName field if present, otherwise returns null.
  String? get displayName {
    if (data.isEmpty) return null;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return json['userName'] as String?;
    } catch (_) {
      return null;
    }
  }
}
