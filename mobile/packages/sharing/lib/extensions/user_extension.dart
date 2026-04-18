import 'package:ente_contacts/contacts.dart';
import "package:ente_sharing/models/user.dart";

extension UserExtension on User {
  //Some initial users have name in name field.
  String? get displayName =>
      // ignore: deprecated_member_use_from_same_package, deprecated_member_use
      ((name?.isEmpty ?? true) ? null : name);

  String get nameOrEmail {
    return email.substring(0, email.indexOf("@"));
  }

  String get resolvedDisplayName {
    final savedName = ContactsDisplayService.instance.getCachedSavedName(
      contactUserId: id,
      email: email,
    );
    if (savedName != null) {
      return savedName;
    }
    final currentDisplayName = displayName?.trim();
    if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
      return currentDisplayName;
    }
    return resolvedEmail;
  }

  String get resolvedEmail {
    final savedEmail = ContactsDisplayService.instance.getCachedResolvedEmail(
      contactUserId: id,
      email: email,
    );
    if (savedEmail != null) {
      return savedEmail;
    }
    return email;
  }

  bool matchesResolvedNameOrEmail(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return resolvedDisplayName.toLowerCase().contains(normalizedQuery) ||
        resolvedEmail.toLowerCase().contains(normalizedQuery) ||
        email.toLowerCase().contains(normalizedQuery);
  }
}
