import "dart:async";
import 'dart:convert';

import "package:app_links/app_links.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/errors.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/ui/account/two_factor_authentication_page.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyPage extends StatefulWidget {
  final String sessionID;
  final String totp2FASessionID;
  final String accountsUrl;

  const PasskeyPage(
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
  late StreamSubscription<Uri?> linkStreamSubscription;

  @override
  void initState() {
    launchPasskey();
    _initDeepLinks();
    super.initState();
  }

  @override
  void dispose() {
    linkStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> launchPasskey() async {
    await launchUrlString(
      "${widget.accountsUrl}/passkeys/verify?"
      "passkeySessionID=${widget.sessionID}"
      "&redirect=ente://passkey"
      "&clientPackage=io.ente.photos",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> checkStatus() async {
    late dynamic response;
    try {
      response = await UserService.instance
          .getTokenForPasskeySession(widget.sessionID);
    } on PassKeySessionNotVerifiedError {
      showToast(context, context.l10n.passKeyPendingVerification);
      return;
    } on PassKeySessionExpiredError {
      await showErrorDialog(
        context,
        context.l10n.loginSessionExpired,
        context.l10n.loginSessionExpiredDetails,
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

  Future<void> _handleDeeplink(Uri? uri) async {
    if (!context.mounted ||
        Configuration.instance.hasConfiguredAccount() ||
        uri == null) {
      _logger.warning(
        'ignored deeplink: contextMounted ${context.mounted} hasConfiguredAccount ${Configuration.instance.hasConfiguredAccount()}',
      );
      return;
    }
    final link = uri.toString();
    try {
      if (mounted && link.toLowerCase().startsWith("ente://passkey")) {
        if (Configuration.instance.isLoggedIn()) {
          _logger.info('ignored deeplink: already configured');
          showToast(
            context,
            AppLocalizations.of(context).accountIsAlreadyConfigured,
          );
          return;
        }
        final parsedUri = Uri.parse(link);
        final sessionID = parsedUri.queryParameters['passkeySessionID'];
        if (sessionID != widget.sessionID) {
          showToast(context, AppLocalizations.of(context).sessionIdMismatch);
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
    linkStreamSubscription = appLinks.uriLinkStream.listen(
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.waitingForVerification,
              style: const TextStyle(
                height: 1.4,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ButtonWidget(
              buttonType: ButtonType.primary,
              labelText: context.l10n.tryAgain,
              onTap: () => launchPasskey(),
            ),
            const SizedBox(height: 16),
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: context.l10n.checkStatus,
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
                      context.l10n.loginWithTOTP,
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
                    context.l10n.recoverAccount,
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
