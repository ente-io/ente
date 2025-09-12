import 'package:ente_auth/core/configuration.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService {
  static bool isInternalUserOrDebugBuild() {
    final String? email = Configuration.instance.getEmail();
    final userID = Configuration.instance.getUserID();
    if (email == null || userID == null) {
      return kDebugMode;
    }
    return (email.endsWith("@ente.io")) || (userID < 1000) || kDebugMode;
  }
}
