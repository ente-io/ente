import "package:ente_sharing/models/user.dart";

extension UserExtension on User {
  //Some initial users have name in name field.
  String? get displayName =>
      // ignore: deprecated_member_use_from_same_package, deprecated_member_use
      ((name?.isEmpty ?? true) ? null : name);

  String get nameOrEmail {
    return email.substring(0, email.indexOf("@"));
  }
}
