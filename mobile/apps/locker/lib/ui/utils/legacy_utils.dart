// ignore_for_file: use_build_context_synchronously

import "package:ente_legacy/pages/emergency_page.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";

/// Opens the Legacy (Emergency contacts) page after authenticating the user.
Future<void> openLegacyPage(BuildContext context) async {
  var hasAuthenticatedForLegacyFlow = await _authenticateForLegacyFlow(
    context,
    context.l10n.authToManageLegacy,
  );
  if (!hasAuthenticatedForLegacyFlow || !context.mounted) {
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (BuildContext context) {
        return EmergencyPage(
          config: Configuration.instance,
          legacyKitAuthenticator: (context, reason) async {
            if (hasAuthenticatedForLegacyFlow) {
              return true;
            }
            hasAuthenticatedForLegacyFlow = await _authenticateForLegacyFlow(
              context,
              reason,
            );
            return hasAuthenticatedForLegacyFlow;
          },
        );
      },
    ),
  );
}

Future<bool> _authenticateForLegacyFlow(
  BuildContext context,
  String reason,
) {
  return LocalAuthenticationService.instance.requestLocalAuthentication(
    context,
    reason,
    useDebugAuthCache: false,
  );
}
