// ignore_for_file: use_build_context_synchronously

import "package:ente_legacy/pages/emergency_page.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:locker/services/configuration.dart";

/// Opens the Legacy (Emergency contacts) page after authenticating the user.
///
/// In debug mode, authentication is bypassed.
Future<void> openLegacyPage(BuildContext context) async {
  final hasAuthenticated = kDebugMode ||
      await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        "Authenticate to manage legacy contacts",
      );
  if (hasAuthenticated && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return EmergencyPage(config: Configuration.instance);
        },
      ),
    );
  }
}
