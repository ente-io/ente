import "package:photos/models/api/collection/user.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

extension UserExtension on User {
  String? displayName() {
    final emailToName = PersonService.instance.emailToNameMapCache;
    if (emailToName.containsKey(email)) {
      return emailToName[email];
    } else {
      //Some initial users have name in name field.
      return name;
    }
  }
}
