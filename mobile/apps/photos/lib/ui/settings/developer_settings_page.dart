import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/core/network/network.dart";
import "package:photos/events/app_mode_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/alert_bottom_sheet.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import "package:photos/ui/notification/toast.dart";

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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    _logger.info(
      "Current endpoint is: ${Configuration.instance.getHttpEndpoint()}",
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.content,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context).developerSettings,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextInputWidgetV2(
                label: AppLocalizations.of(context).serverEndpoint,
                hintText: Configuration.instance.getHttpEndpoint(),
                textEditingController: _urlController,
                autoCorrect: false,
                autoFocus: true,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              ButtonWidgetV2(
                buttonType: ButtonTypeV2.primary,
                labelText: AppLocalizations.of(context).save,
                onTap: () async {
                  final url = _urlController.text.trim();
                  _logger.info("Entered endpoint: $url");
                  final modeToggleMessage =
                      await _maybeToggleOfflineModeOption(url);
                  if (modeToggleMessage != null) {
                    Bus.instance.fire(AppModeChangedEvent());
                    showToast(context, modeToggleMessage);
                    Navigator.of(context).pop();
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
                    _logger.severe("Failed to update developer endpoint", e);
                    await showAlertBottomSheet(
                      context,
                      title: AppLocalizations.of(context).invalidEndpoint,
                      message:
                          AppLocalizations.of(context).invalidEndpointMessage +
                              "\n" +
                              e.toString(),
                      assetPath: 'assets/warning-green.png',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
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

  Future<String?> _maybeToggleOfflineModeOption(String input) async {
    switch (input) {
      case "offline":
        await localSettings.setShowOfflineModeOption(true);
        return "Offline mode option enabled";
      case "online":
        await localSettings.setShowOfflineModeOption(false);
        return "Offline mode option disabled";
      default:
        return null;
    }
  }
}
