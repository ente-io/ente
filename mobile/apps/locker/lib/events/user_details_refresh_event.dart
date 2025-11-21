import "package:ente_events/models/event.dart";

/// Event fired when user details (like file count, storage) need to be refreshed from the server.
///
/// Fired in the following scenarios:
/// - File uploads complete (PDF/text files or info items)
/// - Files are moved to trash
/// - Files are restored from trash
/// - Settings drawer is opened
class UserDetailsRefreshEvent extends Event {}
