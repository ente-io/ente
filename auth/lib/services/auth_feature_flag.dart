import 'package:ente_auth/core/configuration.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService {
  FeatureFlagService._privateConstructor();
  static final FeatureFlagService instance =
      FeatureFlagService._privateConstructor();

  static final _internalUserIDs = const String.fromEnvironment(
    "internal_user_ids",
    defaultValue: "1,2,3,4,191,125,1580559962388044,1580559962392434,10000025",
  ).split(",").map((element) {
    return int.parse(element);
  }).toSet();

  bool isInternalUserOrDebugBuild() {
    final String? email = Configuration.instance.getEmail();
    final userID = Configuration.instance.getUserID();
    return (email != null && email.endsWith("@ente.io")) ||
        _internalUserIDs.contains(userID) ||
        kDebugMode;
  }
}
