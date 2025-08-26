import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_accounts/models/errors.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:ente_utils/navigation_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyPage extends StatefulWidget {
  final BaseConfiguration config;
  final String sessionID;
  final String totp2FASessionID;
  final String accountsUrl;

  const PasskeyPage(
    this.config,
    this.sessionID, {
    required this.totp2FASessionID,
    required this.accountsUrl,
    super.key,
  });

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
      "${widget.accountsUrl}/passkeys/verify?"
      "passkeySessionID=${widget.sessionID}"
      "&redirect=enteauth://passkey"
      "&clientPackage=io.ente.auth",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> checkStatus() async {
    late dynamic response;
    try {
      response = await UserService.instance
          .getTokenForPasskeySession(widget.sessionID);
    } on PassKeySessionNotVerifiedError {
      showToast(context, context.strings.passKeyPendingVerification);
      return;
    } on PassKeySessionExpiredError {
      await showErrorDialog(
        context,
        context.strings.loginSessionExpired,
        context.strings.loginSessionExpiredDetails,
      );
      Navigator.of(context).pop();
      return;
    } catch (e, s) {
      _logger.severe("failed to check status", e, s);
      showGenericErrorDialog(context: context, error: e).ignore();
      return;
    }
    await UserService.instance.onPassKeyVerified(context, response);
  }

  Future<void> _handleDeeplink(String? link) async {
    if (!context.mounted ||
        widget.config.hasConfiguredAccount() ||
        link == null) {
      _logger.warning(
        'ignored deeplink: contextMounted ${context.mounted}',
      );
      return;
    }
    try {
      if (mounted && link.toLowerCase().startsWith("enteauth://passkey")) {
        if (widget.config.isLoggedIn()) {
          _logger.info('ignored deeplink: already configured');
          showToast(context, 'Account is already configured.');
          return;
        }
        final parsedUri = Uri.parse(link);
        final sessionID = parsedUri.queryParameters['passkeySessionID'];
        if (sessionID != widget.sessionID) {
          showToast(context, "Session ID mismatch");
          _logger.warning('ignored deeplink: sessionID mismatch');
          return;
        }
        final String? authResponse = parsedUri.queryParameters['response'];
        String base64String = authResponse!.toString();
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
    final appLinks = AppLinks();
    // Attach a listener to the stream
    appLinks.stringLinkStream.listen(
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
          context.strings.passkeyAuthTitle,
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
              context.strings.waitingForVerification,
              style: const TextStyle(
                height: 1.4,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ButtonWidget(
              buttonType: ButtonType.primary,
              labelText: context.strings.tryAgain,
              onTap: () => launchPasskey(),
            ),
            const SizedBox(height: 16),
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: context.strings.checkStatus,
              onTap: () async {
                try {
                  await checkStatus();
                } catch (e) {
                  debugPrint('failed to check status %e');
                  showGenericErrorDialog(context: context, error: e).ignore();
                }
              },
              shouldSurfaceExecutionStates: true,
            ),
            const Padding(padding: EdgeInsets.all(30)),
            if (widget.totp2FASessionID.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  routeToPage(
                    context,
                    TwoFactorAuthenticationPage(
                      widget.totp2FASessionID,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      context.strings.loginWithTOTP,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
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
                    context.strings.recoverAccount,
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
