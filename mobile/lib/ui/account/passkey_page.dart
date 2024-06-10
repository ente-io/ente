import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/user_service.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyPage extends StatefulWidget {
  final String sessionID;

  const PasskeyPage(
    this.sessionID, {
    Key? key,
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
      "https://accounts.ente.io/passkeys/verify?"
      "passkeySessionID=${widget.sessionID}"
      "&redirect=ente://passkey"
      "&clientPackage=io.ente.photos",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleDeeplink(String? link) async {
    if (!context.mounted ||
        Configuration.instance.hasConfiguredAccount() ||
        link == null) {
      _logger.warning(
        'ignored deeplink: contextMounted ${context.mounted} hasConfiguredAccount ${Configuration.instance.hasConfiguredAccount()}',
      );
      return;
    }
    try {
      if (mounted && link.toLowerCase().startsWith("ente://passkey")) {
        final String? uri = Uri.parse(link).queryParameters['response'];
        String base64String = uri!.toString();
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }
        final res = utf8.decode(base64.decode(base64String));
        final json = jsonDecode(res) as Map<String, dynamic>;
        await UserService.instance.onPassKeyVerified(context, json);
      } else {
        _logger.info('ignored deeplink: $link mounted $mounted');
      }
    } catch (e, s) {
      _logger.severe('passKey: failed to handle deeplink', e, s);
      showGenericErrorDialog(context: context, error: e).ignore();
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context).waitingForVerification,
              style: const TextStyle(
                height: 1.4,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ButtonWidget(
              buttonType: ButtonType.primary,
              labelText: S.of(context).verifyPasskey,
              onTap: () => launchPasskey(),
            ),
            const Padding(padding: EdgeInsets.all(30)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                UserService.instance.recoverTwoFactor(
                  context,
                  widget.sessionID,
                  TwoFactorType.passkey,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    S.of(context).recoverAccount,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
