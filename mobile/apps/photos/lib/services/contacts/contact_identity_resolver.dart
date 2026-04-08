import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/service_locator.dart" show flagService;
import "package:photos/services/photos_contacts_service.dart";

String resolveDisplayName(User user) {
  final savedName = _savedContactName(user);
  if (savedName != null) {
    return savedName;
  }

  final personName = user.displayName?.trim();
  if (personName != null && personName.isNotEmpty) {
    return personName;
  }

  return resolveKnownEmail(user) ?? "Someone";
}

String? resolveKnownEmail(User user) {
  if (flagService.internalUser && user.id != null && user.id! > 0) {
    final savedEmail = _knownEmailOrNull(
      PhotosContactsService.instance.getCachedResolvedEmailByUserId(user.id),
    );
    if (savedEmail != null) {
      return savedEmail;
    }
  }

  return _knownEmailOrNull(user.email);
}

String? _savedContactName(User user) {
  if (!flagService.internalUser || user.id == null || user.id! <= 0) {
    return null;
  }

  final savedName = PhotosContactsService.instance
      .getCachedSavedNameByUserId(user.id)
      ?.trim();
  if (savedName == null || savedName.isEmpty) {
    return null;
  }
  return savedName;
}

String? _knownEmailOrNull(String? email) {
  if (email == null) {
    return null;
  }

  final trimmed = email.trim();
  if (trimmed.isEmpty || trimmed == "unknown@unknown.com") {
    return null;
  }

  return trimmed.endsWith("@unknown.com") ? null : trimmed;
}
