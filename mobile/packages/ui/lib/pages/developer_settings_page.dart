import 'package:dio/dio.dart';
import "package:ente_configuration/base_configuration.dart";
import "package:ente_logging/logging.dart";
import "package:ente_strings/ente_strings.dart";
import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';

class DeveloperSettingsPage extends StatefulWidget {
  final BaseConfiguration config;

  const DeveloperSettingsPage(this.config, {super.key});

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
      "Current endpoint is: ${widget.config.getHttpEndpoint()}",
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.developerSettings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: context.strings.serverEndpoint,
                hintText: widget.config.getHttpEndpoint(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 40),
            GradientButton(
              onTap: () async {
                final String url = _urlController.text;
                _logger.info("Entered endpoint: $url");
                try {
                  final uri = Uri.parse(url);
                  if ((uri.scheme == "http" || uri.scheme == "https")) {
                    await _ping(url);
                    await widget.config.setHttpEndpoint(url);
                    showToast(context, context.strings.endpointUpdatedMessage);
                    Navigator.of(context).pop();
                  } else {
                    throw const FormatException();
                  }
                } catch (e) {
                  // ignore: unawaited_futures
                  showErrorDialog(
                    context,
                    context.strings.invalidEndpoint,
                    context.strings.invalidEndpointMessage,
                  );
                }
              },
              text: context.strings.save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ping(String endpoint) async {
    try {
      final response = await Dio().get('$endpoint/ping');
      if (response.data['message'] != 'pong') {
        throw Exception('Invalid response');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}
