import 'dart:convert';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/delete_account.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/ui/common/dialogs.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/utils/email_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/material.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.deleteAccount),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/broken_heart.png',
                width: 200,
              ),
              const SizedBox(
                height: 24,
              ),
              Center(
                child: Text(
                  l10n.deleteAccountQuery,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              RichText(
                // textAlign: TextAlign.center,
                text: TextSpan(
                  children: const [
                    TextSpan(text: "Please write to us at "),
                    TextSpan(
                      text: "feedback@ente.io",
                      style: TextStyle(color: Color.fromRGBO(29, 185, 84, 1)),
                    ),
                    TextSpan(
                      text: ", maybe there is a way we can help.",
                    ),
                  ],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              GradientButton(
                text: l10n.yesSendFeedbackAction,
                iconData: Icons.check,
                onTap: () async {
                  await sendEmail(
                    context,
                    to: 'feedback@ente.io',
                    subject: '[Feedback]',
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              InkWell(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 10,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    label: Text(
                      l10n.noDeleteAccountAction,
                      style: const TextStyle(
                        color: Colors.redAccent, // same for both themes
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () async => {await _initiateDelete(context)},
                    icon: const Icon(
                      Icons.no_accounts,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateDelete(BuildContext context) async {
    final deleteChallengeResponse =
        await UserService.instance.getDeleteChallenge(context);
    if (deleteChallengeResponse == null) {
      return;
    }
    if (deleteChallengeResponse.allowDelete) {
      await _confirmAndDelete(context, deleteChallengeResponse);
    } else {
      await _requestEmailForDeletion(context);
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    DeleteChallengeResponse response,
  ) async {
    final l10n = context.l10n;
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      l10n.initiateAccountDeleteTitle,
    );

    await PlatformUtil.refocusWindows();

    if (hasAuthenticated) {
      final choice = await showChoiceDialogOld(
        context,
        l10n.confirmAccountDeleteTitle,
        l10n.confirmAccountDeleteMessage,
        firstAction: l10n.cancel,
        secondAction: l10n.delete,
        firstActionColor: Theme.of(context).colorScheme.onSurface,
        secondActionColor: Colors.red,
      );
      if (choice != DialogUserChoice.secondChoice) {
        return;
      }
      final decryptChallenge = CryptoUtil.openSealSync(
        CryptoUtil.base642bin(response.encryptedChallenge),
        CryptoUtil.base642bin(
          Configuration.instance.getKeyAttributes()!.publicKey,
        ),
        Configuration.instance.getSecretKey()!,
      );
      final challengeResponseStr = utf8.decode(decryptChallenge);
      await UserService.instance.deleteAccount(context, challengeResponseStr);
    }
  }

  Future<void> _requestEmailForDeletion(BuildContext context) async {
    final l10n = context.l10n;
    final AlertDialog alert = AlertDialog(
      title: Text(
        l10n.deleteAccount,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
      content: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Please send an email to ",
            ),
            TextSpan(
              text: "account-deletion@ente.io",
              style: TextStyle(
                color: Colors.orange[300],
              ),
            ),
            const TextSpan(
              text:
                  " from your registered email address.\n\nYour request will be processed within 72 hours.",
            ),
          ],
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            l10n.sendEmail,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            await sendEmail(
              context,
              to: 'account-deletion@ente.io',
              subject: '[Delete account]',
            );
          },
        ),
        TextButton(
          child: Text(
            l10n.ok,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );
    // ignore: unawaited_futures
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
