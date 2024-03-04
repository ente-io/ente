import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/user_service.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyPage extends StatefulWidget {
  final String sessionID;
  final Uint8List keyEncryptionKey;

  const PasskeyPage(
    this.sessionID, {
    Key? key,
    required this.keyEncryptionKey,
  }) : super(key: key);

  @override
  State<PasskeyPage> createState() => _PasskeyPageState();
}

class _PasskeyPageState extends State<PasskeyPage> {
  final Logger _logger = Logger("PasskeyPage");

  @override
  void initState() {
    launchPasskey();
    _initDeepLinks();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> launchPasskey() async {
    await launchUrlString(
      "https://accounts.ente.io/passkeys/flow?"
      "passkeySessionID=${widget.sessionID}"
      "&redirect=ente://passkey",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleDeeplink(String? link) async {
    if (!context.mounted ||
        Configuration.instance.hasConfiguredAccount() ||
        link == null) {
      return;
    }
    if (mounted && link.toLowerCase().startsWith("ente://passkey")) {
      final uri = Uri.parse(link).queryParameters['response'];

      // response to json
      final res = utf8.decode(base64.decode(uri!));
      final json = jsonDecode(res) as Map<String, dynamic>;

      try {
        await UserService.instance.acceptPasskey(
          context,
          json,
          widget.keyEncryptionKey,
        );
      } catch (e) {
        _logger.severe(e);
      }
    }
  }

  Future<bool> _initDeepLinks() async {
    // Attach a listener to the stream
    linkStream.listen(
      _handleDeeplink,
      onError: (err) {
        _logger.severe(err);
      },
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).passkeyAuthTitle,
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).waitingForBrowserRequest,
            style: const TextStyle(
              height: 1.4,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton(
              style: Theme.of(context).colorScheme.optionalActionButtonStyle,
              onPressed: launchPasskey,
              child: Text(S.of(context).launchPasskeyUrlAgain),
            ),
          ),
        ],
      ),
    );
  }
}
