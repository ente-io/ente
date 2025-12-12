import "dart:convert";

import 'package:bip39/bip39.dart' as bip39;
import "package:crypto/crypto.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_configuration/base_configuration.dart";
import "package:ente_sharing/components/gradient_button.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";

/// Shows the verify identity bottom sheet
Future<void> showVerifyIdentitySheet(
  BuildContext context, {
  required bool self,
  String email = '',
  required BaseConfiguration config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => VerifyIdentityDialog(
      self: self,
      email: email,
      config: config,
    ),
  );
}

class VerifyIdentityDialog extends StatefulWidget {
  // email id of the user who's verification ID is being displayed for
  // verification
  final String email;

  // self is true when the user is viewing their own verification ID
  final bool self;
  final BaseConfiguration config;

  VerifyIdentityDialog({
    super.key,
    required this.self,
    this.email = '',
    required this.config,
  }) {
    if (!self && email.isEmpty) {
      throw ArgumentError("email cannot be empty when self is false");
    }
  }

  @override
  State<VerifyIdentityDialog> createState() => _VerifyIdentityDialogState();
}

class _VerifyIdentityDialogState extends State<VerifyIdentityDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    final String subTitle = widget.self
        ? context.strings.thisIsYourVerificationId
        : context.strings.thisIsPersonVerificationId(widget.email);
    final String bottomText = widget.self
        ? context.strings.someoneSharingAlbumsWithYouShouldSeeTheSameId
        : context.strings.howToViewShareeVerificationID;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, colorScheme, textStyle),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: _getPublicKey(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final publicKey = snapshot.data!;
                    if (publicKey.isEmpty) {
                      return _buildNoAccountContent(
                        context,
                        colorScheme,
                        textStyle,
                      );
                    } else {
                      return _buildVerificationContent(
                        context,
                        colorScheme,
                        textStyle,
                        publicKey,
                        subTitle,
                        bottomText,
                      );
                    }
                  } else if (snapshot.hasError) {
                    Logger("VerificationID")
                        .severe("failed to end userID", snapshot.error);
                    return Text(
                      context.strings.somethingWentWrong,
                      style: textStyle.bodyMuted,
                    );
                  } else {
                    return const SizedBox(
                      height: 200,
                      child: EnteLoadingWidget(),
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

  Widget _buildHeader(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textStyle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.strings.verify,
          style: textStyle.largeBold,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 20,
              color: colorScheme.textBase,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoAccountContent(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textStyle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.strings.emailNoEnteAccount(widget.email),
          style: textStyle.small.copyWith(color: colorScheme.textMuted),
        ),
        const SizedBox(height: 20),
        GradientButton(
          text: context.strings.sendInvite,
          onTap: () {
            shareText(context.strings.shareTextRecommendUsingEnte);
          },
        ),
      ],
    );
  }

  Widget _buildVerificationContent(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textStyle,
    String publicKey,
    String subTitle,
    String bottomText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subTitle,
          style: textStyle.small.copyWith(color: colorScheme.textMuted),
        ),
        const SizedBox(height: 20),
        _verificationIDWidget(context, publicKey),
        const SizedBox(height: 20),
        Text(
          bottomText,
          style: textStyle.small.copyWith(color: colorScheme.textMuted),
        ),
      ],
    );
  }

  Future<String> _getPublicKey() async {
    if (widget.self) {
      return widget.config.getKeyAttributes()!.publicKey;
    }
    final String? userPublicKey =
        await UserService.instance.getPublicKey(widget.email);
    if (userPublicKey == null) {
      // user not found
      return "";
    }
    return userPublicKey;
  }

  Widget _verificationIDWidget(BuildContext context, String publicKey) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final String verificationID = _generateVerificationID(publicKey);
    return GestureDetector(
      onTap: () async {
        if (verificationID.isEmpty) {
          return;
        }
        await Clipboard.setData(
          ClipboardData(text: verificationID),
        );
        // ignore: unawaited_futures
        shareText(
          widget.self
              ? context.strings.shareMyVerificationID(verificationID)
              : context.strings
                  .shareTextConfirmOthersVerificationID(verificationID),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.primary700,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 24,
        ),
        width: double.infinity,
        child: Text(
          verificationID,
          style: textTheme.body.copyWith(
            color: Colors.white,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  String _generateVerificationID(String publicKey) {
    final inputBytes = base64.decode(publicKey);
    final shaValue = sha256.convert(inputBytes);
    return bip39.generateMnemonic(
      strength: 256,
      randomBytes: (int size) {
        return Uint8List.fromList(shaValue.bytes);
      },
    );
  }
}
