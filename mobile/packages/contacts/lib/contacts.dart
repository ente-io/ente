library;

/// Shared contacts package for native Flutter apps.
///
/// `ContactsSession.accountKey` means the logged-in user's existing top-level
/// account key, not a contacts-specific key. The package uses it only to
/// unwrap or create the per-user root contact key.
export 'src/db/contacts_database.dart';
export 'src/models/contact_data.dart';
export 'src/models/contact_record.dart';
export 'src/models/contacts_session.dart';
export 'src/service/contacts_service.dart';
