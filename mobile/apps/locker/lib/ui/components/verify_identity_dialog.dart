import "dart:convert";

import "package:bip39/bip39.dart" as bip39;
import "package:crypto/crypto.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/services/configuration.dart";
import "package:share_plus/share_plus.dart";

class VerifyIdentityDialog extends StatelessWidget {
  const VerifyIdentityDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final publicKey = Configuration.instance.getKeyAttributes()!.publicKey;
    final verificationID = _generateVerificationID(publicKey);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleBarTitleWidget(
                  title: context.strings.verifyIDLabel,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.fillFaint,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.strings.thisIsYourVerificationId,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            _buildVerificationIDWidget(
              context,
              verificationID,
            ),
            const SizedBox(height: 16),
            Text(
              context.strings.someoneSharingAlbumsWithYouShouldSeeTheSameId,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationIDWidget(
    BuildContext context,
    String verificationID,
  ) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return GestureDetector(
      onTap: () => _shareVerificationID(context, verificationID),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.primary700,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: SelectableText(
                verificationID,
                style: textTheme.body.copyWith(
                  color: Colors.white,
                  fontFamily: "monospace",
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                onPressed: () => _copyToClipboard(context, verificationID),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: colorScheme.primary500,
                ),
                tooltip: "Copy to clipboard",
              ),
            ),
          ],
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

  Future<void> _copyToClipboard(
    BuildContext context,
    String verificationID,
  ) async {
    await Clipboard.setData(ClipboardData(text: verificationID));
    if (context.mounted) {
      showShortToast(
        context,
        context.strings.recoveryKeyCopiedToClipboard,
      );
    }
  }

  Future<void> _shareVerificationID(
    BuildContext context,
    String verificationID,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        text: verificationID,
      ),
    );
  }
}

Future<void> showVerifyIdentityDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return const VerifyIdentityDialog();
    },
  );
}
