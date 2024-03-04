import 'dart:convert';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
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
      "&redirect=enteauth://passkey",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleDeeplink(String? link) async {
    if (!context.mounted ||
        Configuration.instance.hasConfiguredAccount() ||
        link == null) {
      return;
    }
    if (mounted && link.toLowerCase().startsWith("enteauth://passkey")) {
      final uri = Uri.parse(link).queryParameters['response'];

      // response to json
      final res = utf8.decode(base64.decode(uri!));
      final json = jsonDecode(res) as Map<String, dynamic>;

      await UserService.instance.acceptPasskey(
        context,
        json,
        widget.keyEncryptionKey,
      );
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.passkeyAuthTitle,
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.waitingForBrowserRequest,
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
              child: Text(l10n.launchPasskeyUrlAgain),
            ),
          ),
        ],
      ),
    );
  }
}
