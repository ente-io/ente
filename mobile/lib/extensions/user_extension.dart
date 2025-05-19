import "package:photos/models/api/collection/user.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

extension UserExtension on User {
  //Some initial users have name in name field.
  String? get displayName =>
      PersonService.instance.emailToPartialPersonDataMapCache[email]
          ?[PersonService.kNameKey] ??
      // ignore: deprecated_member_use_from_same_package
      ((name?.isEmpty ?? true) ? null : name);

  String? get linkedPersonID =>
      PersonService.instance.emailToPartialPersonDataMapCache[email]
          ?[PersonService.kPersonIDKey];

  String get nameOrEmail {
    if (PersonService.isInitialized) {
      return displayName ?? email.substring(0, email.indexOf("@"));
    } else {
      return email.substring(0, email.indexOf("@"));
    }
  }
}
