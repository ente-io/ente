import 'dart:typed_data';

/// Resolves the logged-in user's existing top-level account key on demand.
typedef AccountKeyProvider = Future<Uint8List> Function();

/// Session input for opening contacts.
///
/// `accountKey` means the logged-in user's existing top-level account key.
/// It is the same conceptual key that Photos currently exposes via
/// `Configuration.instance.getKey()`. It is not a contacts-specific key.
///
/// The contacts package uses this key only to unwrap or create the per-user
/// root contact key stored under `/user-entity/key?type=contact`.
class ContactsSession {
  final String baseUrl;
  final String authToken;
  final int userId;

  /// The logged-in user's existing top-level account key.
  final Uint8List? accountKey;

  /// Lazy resolver for the logged-in user's existing top-level account key.
  final AccountKeyProvider? accountKeyProvider;
  final String? userAgent;
  final String? clientPackage;
  final String? clientVersion;

  ContactsSession({
    required this.baseUrl,
    required this.authToken,
    required this.userId,
    this.accountKey,
    this.accountKeyProvider,
    this.userAgent,
    this.clientPackage,
    this.clientVersion,
  }) : assert(
         accountKey != null || accountKeyProvider != null,
         'ContactsSession requires accountKey or accountKeyProvider',
       );

  Future<Uint8List> resolveAccountKey() async {
    final accountKey = this.accountKey;
    if (accountKey != null) {
      return accountKey;
    }
    final provider = accountKeyProvider;
    if (provider == null) {
      throw StateError(
        'ContactsSession requires accountKey or accountKeyProvider',
      );
    }
    return provider();
  }
}
