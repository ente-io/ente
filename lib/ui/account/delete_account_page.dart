import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/delete_account.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Delete account"),
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
                  "We'll be sorry to see you go. Are you facing some issue?",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(color: colorScheme.textMuted),
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
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(color: colorScheme.textMuted),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              ButtonWidget(
                buttonType: ButtonType.primary,
                labelText: "Yes, send feedback",
                icon: Icons.check_outlined,
                onTap: () async {
                  await sendEmail(
                    context,
                    to: 'feedback@ente.io',
                    subject: '[Feedback]',
                  );
                },
              ),
              const SizedBox(height: 8),
              ButtonWidget(
                buttonType: ButtonType.tertiaryCritical,
                labelText: "No, delete account",
                icon: Icons.no_accounts_outlined,
                onTap: () async => {await _initiateDelete(context)},
                shouldSurfaceExecutionStates: false,
              )
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
      "Please authenticate to initiate account deletion",
    );

    if (hasAuthenticated) {
      final choice = await showNewChoiceDialog(
        context: context,
        title: 'Are you sure you want to delete your account?',
        body:
            'Your uploaded data will be scheduled for deletion, and your account'
            ' will be permanently deleted. \n\nThis action is not reversible.',
        firstButtonLabel: "Delete my account",
        isCritical: true,
        firstButtonOnTap: () async {
          final decryptChallenge = CryptoUtil.openSealSync(
            Sodium.base642bin(response.encryptedChallenge),
            Sodium.base642bin(
              Configuration.instance.getKeyAttributes()!.publicKey,
            ),
            Configuration.instance.getSecretKey()!,
          );
          final challengeResponseStr = utf8.decode(decryptChallenge);
          await UserService.instance
              .deleteAccount(context, challengeResponseStr);
        },
      );
      if (choice == ButtonAction.error) {
        showGenericErrorDialog(context: context);
      }
      if (choice != ButtonAction.first) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _requestEmailForDeletion(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      title: const Text(
        "Delete account",
        style: TextStyle(
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
          child: const Text(
            "Send email",
            style: TextStyle(
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
            "Ok",
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
