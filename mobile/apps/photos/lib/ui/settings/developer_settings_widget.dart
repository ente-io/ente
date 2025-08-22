import 'package:flutter/material.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";

class DeveloperSettingsWidget extends StatelessWidget {
  const DeveloperSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Configuration.instance.isEnteProduction()) {
      final endpoint = Configuration.instance.getHttpEndpoint();
      final endpointURI = Uri.parse(endpoint);
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          AppLocalizations.of(context).customEndpoint(
              endpoint: "${endpointURI.host}:${endpointURI.port}",),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
