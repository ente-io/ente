import "dart:convert";

import 'package:bip39/bip39.dart' as bip39;
import "package:crypto/crypto.dart";
import "package:dotted_border/dotted_border.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:logging/logging.dart";

class VerifyIdentifyDialog extends StatefulWidget {
  // email id of the user who's verification ID is being displayed for
  // verification
  final String email;

  // self is true when the user is viewing their own verification ID
  final bool self;

  VerifyIdentifyDialog({
    super.key,
    required this.self,
    this.email = '',
  }) {
    if (!self && email.isEmpty) {
      throw ArgumentError("email cannot be empty when self is false");
    }
  }

  @override
  State<VerifyIdentifyDialog> createState() => _VerifyIdentifyDialogState();
}

class _VerifyIdentifyDialogState extends State<VerifyIdentifyDialog> {
  final bool doesUserExist = true;

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    final String subTitle = widget.self
        ? context.l10n.thisIsYourVerificationId
        : context.l10n.thisIsPersonVerificationId(widget.email);
    final String bottomText = widget.self
        ? context.l10n.someoneSharingAlbumsWithYouShouldSeeTheSameId
        : context.l10n.howToViewShareeVerificationID;

    final AlertDialog alert = AlertDialog(
      title: Text(
        widget.self
            ? context.l10n.verificationId
            : context.l10n.verifyEmailID(widget.email),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<String>(
            future: _getPublicKey(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final publicKey = snapshot.data!;
                if (publicKey.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.emailNoEnteAccount(widget.email),
                      ),
                      const SizedBox(height: 24),
                      ButtonWidget(
                        buttonType: ButtonType.neutral,
                        icon: Icons.adaptive.share,
                        labelText: context.l10n.sendInvite,
                        isInAlert: true,
                        onTap: () async {
                          // ignore: unawaited_futures
                          shareText(
                            context.l10n.shareTextRecommendUsingEnte,
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subTitle,
                        style: textStyle.bodyMuted,
                      ),
                      const SizedBox(height: 20),
                      _verificationIDWidget(context, publicKey),
                      const SizedBox(height: 16),
                      Text(
                        bottomText,
                        style: textStyle.bodyMuted,
                      ),
                      const SizedBox(height: 24),
                      ButtonWidget(
                        buttonType: ButtonType.neutral,
                        isInAlert: true,
                        labelText:
                            widget.self ? context.l10n.ok : context.l10n.done,
                      ),
                    ],
                  );
                }
              } else if (snapshot.hasError) {
                Logger("VerificationID")
                    .severe("failed to end userID", snapshot.error);
                return Text(
                  context.l10n.somethingWentWrong,
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
    );
    return alert;
  }

  Future<String> _getPublicKey() async {
    if (widget.self) {
      return Configuration.instance.getKeyAttributes()!.publicKey;
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
    final textStyle = getEnteTextTheme(context);
    final String verificationID = _generateVerificationID(publicKey);
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: colorScheme.strokeMuted,
        strokeWidth: 1,
        dashPattern: const [12, 6],
        radius: const Radius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
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
                    ? context.l10n.shareMyVerificationID(verificationID)
                    : context.l10n
                        .shareTextConfirmOthersVerificationID(verificationID),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(2),
                ),
                color: colorScheme.backgroundElevated2,
              ),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Text(
                verificationID,
                style: textStyle.bodyBold,
              ),
            ),
          ),
        ],
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
