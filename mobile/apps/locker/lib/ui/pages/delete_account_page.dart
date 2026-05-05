import "dart:convert";

import "package:ente_accounts/ente_accounts.dart";
import "package:ente_configuration/base_configuration.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/email_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/gradient_button.dart";

class DeleteAccountPage extends StatelessWidget {
  final BaseConfiguration config;

  const DeleteAccountPage(
    this.config, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deleteAccount,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Center(
                child: Image.asset(
                  "assets/file_delete_icon.png",
                  width: 115,
                  height: 104,
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: l10n
                          .deleteAccountFeedbackPrompt("feedback@ente.com")
                          .split("feedback@ente.com")[0],
                    ),
                    TextSpan(
                      text: "feedback@ente.com",
                      style: TextStyle(color: colorScheme.primary700),
                    ),
                    TextSpan(
                      text: l10n
                          .deleteAccountFeedbackPrompt("feedback@ente.com")
                          .split("feedback@ente.com")[1],
                    ),
                  ],
                  style: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: l10n.sendFeedback,
                onTap: () async {
                  await sendEmail(
                    context,
                    to: "feedback@ente.com",
                    subject: "[Feedback]",
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                l10n.deleteAccountPermanentWarning,
                style: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: l10n.deleteAccount,
                backgroundColor: colorScheme.warning700,
                onTap: () async => {await _initiateDelete(context)},
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

    if (hasAuthenticated) {
      final confirmed = await _showDeleteConfirmationSheet(context);
      if (confirmed != true) {
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
      if (!context.mounted) {
        return;
      }
      showShortToast(context, context.strings.yourAccountHasBeenDeleted);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<bool?> _showDeleteConfirmationSheet(BuildContext context) async {
    final colorScheme = getEnteColorScheme(context);

    return showAlertBottomSheet<bool>(
      context,
      title: context.strings.confirmAccountDeleteTitle,
      message: context.strings.confirmAccountDeleteMessage,
      assetPath: "assets/warning-grey.png",
      buttons: [
        GradientButton(
          text: context.strings.delete,
          backgroundColor: colorScheme.warning700,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  Future<void> _requestEmailForDeletion(BuildContext context) async {
    final colorScheme = getEnteColorScheme(context);

    await showAlertBottomSheet(
      context,
      title: context.strings.deleteAccount,
      message:
          "Please send an email to account-deletion@ente.com from your registered email address.\n\nYour request will be processed within 72 hours.",
      assetPath: "assets/file_delete_icon.png",
      buttons: [
        GradientButton(
          text: context.strings.sendEmail,
          backgroundColor: colorScheme.primary700,
          onTap: () async {
            Navigator.of(context).pop();
            await sendEmail(
              context,
              to: "account-deletion@ente.com",
              subject: "[Delete account]",
            );
          },
        ),
      ],
    );
  }
}
