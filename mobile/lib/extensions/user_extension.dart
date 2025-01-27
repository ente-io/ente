import "package:photos/models/api/collection/user.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

extension UserExtension on User {
  //Some initial users have name in name field.
  String? get displayName =>
      PersonService.instance.emailToNameMapCache[email] ??
      ((name?.isEmpty ?? true) ? null : name);
}
