import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/app_mode.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/network/network.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/common/gradient_button.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
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
      "Current endpoint is: ${Configuration.instance.getHttpEndpoint()}",
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).developerSettings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).serverEndpoint,
                hintText: Configuration.instance.getHttpEndpoint(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 40),
            GradientButton(
              onTap: () async {
                final url = _urlController.text;
                _logger.info("Entered endpoint: $url");
                if (url == "localMode") {
                  await localSettings.setAppMode(AppMode.offline);
                  await _showRestartDialog(context, "offline");
                  return;
                }
                if (url == "onlineMode") {
                  await localSettings.setAppMode(AppMode.online);
                  await _showRestartDialog(context, "online");
                  return;
                }
                try {
                  final uri = Uri.parse(url);
                  if ((uri.scheme == "http" || uri.scheme == "https")) {
                    await _ping(url);
                    await Configuration.instance.setHttpEndpoint(url);
                    showToast(
                      context,
                      AppLocalizations.of(context).endpointUpdatedMessage,
                    );
                    Navigator.of(context).pop();
                  } else {
                    throw const FormatException();
                  }
                } catch (e) {
                  // ignore: unawaited_futures
                  showErrorDialog(
                    context,
                    AppLocalizations.of(context).invalidEndpoint,
                    AppLocalizations.of(context).invalidEndpointMessage +
                        "\n" +
                        e.toString(),
                  );
                }
              },
              text: AppLocalizations.of(context).save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRestartDialog(BuildContext context, String mode) async {
    await showInfoDialog(
      context,
      title: "App mode set to $mode",
      body: "Please kill and restart the app for the changes to take effect.",
      isDismissable: false,
    );
  }

  Future<void> _ping(String endpoint) async {
    try {
      final response =
          await NetworkClient.instance.getDio().get('$endpoint/ping');
      if (response.data['message'] != 'pong') {
        throw Exception('Invalid response');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}
