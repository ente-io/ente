import 'dart:convert';

import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/components/dialogs.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_utils/email_util.dart';
import 'package:ente_utils/platform_util.dart';
import 'package:flutter/material.dart';

class DeleteAccountPage extends StatelessWidget {
  final BaseConfiguration config;

  const DeleteAccountPage(
    this.config, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(context.strings.deleteAccount),
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
                  context.strings.deleteAccountQuery,
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
                text: context.strings.yesSendFeedbackAction,
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
                      context.strings.noDeleteAccountAction,
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
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.strings.initiateAccountDeleteTitle,
    );

    await PlatformUtil.refocusWindows();

    if (hasAuthenticated) {
      final choice = await showChoiceDialogOld(
        context,
        context.strings.confirmAccountDeleteTitle,
        context.strings.confirmAccountDeleteMessage,
        firstAction: context.strings.cancel,
        secondAction: context.strings.delete,
        firstActionColor: getEnteColorScheme(context).surface,
        secondActionColor: Colors.red,
      );
      if (choice != DialogUserChoice.secondChoice) {
        return;
      }
      final decryptChallenge = CryptoUtil.openSealSync(
        CryptoUtil.base642bin(response.encryptedChallenge),
        CryptoUtil.base642bin(
          config.getKeyAttributes()!.publicKey,
        ),
        config.getSecretKey()!,
      );
      final challengeResponseStr = utf8.decode(decryptChallenge);
      await UserService.instance.deleteAccount(context, challengeResponseStr);
    }
  }

  Future<void> _requestEmailForDeletion(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      title: Text(
        context.strings.deleteAccount,
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
            color: getEnteColorScheme(context).surface,
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            context.strings.sendEmail,
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
            context.strings.ok,
            style: TextStyle(
              color: getEnteColorScheme(context).surface,
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
