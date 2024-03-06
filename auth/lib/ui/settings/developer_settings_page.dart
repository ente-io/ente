import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  _DeveloperSettingsPageState createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  final _logger = Logger('DeveloperSettingsPage');
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info(
      "Current endpoint is: " + Configuration.instance.getHttpEndpoint(),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.developerSettings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: context.l10n.serverEndpoint,
                hintText: Configuration.instance.getHttpEndpoint(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 40),
            GradientButton(
              onTap: () async {
                String url = _urlController.text;
                _logger.info("Entered endpoint: " + url);
                try {
                  final uri = Uri.parse(url);
                  if ((uri.scheme == "http" || uri.scheme == "https")) {
                    await Configuration.instance.setHttpEndpoint(url);
                    showToast(context, context.l10n.endpointUpdatedMessage);
                    Navigator.of(context).pop();
                  } else {
                    throw const FormatException();
                  }
                } catch (e) {
                  showErrorDialog(
                    context,
                    context.l10n.invalidURL,
                    context.l10n.invalidURLMessage,
                  );
                }
              },
              text: context.l10n.saveAction,
            ),
          ],
        ),
      ),
    );
  }
}
