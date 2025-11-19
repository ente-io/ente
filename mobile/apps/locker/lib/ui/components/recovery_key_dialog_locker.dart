import 'dart:io' as io;

import 'package:bip39/bip39.dart' as bip39;
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_configuration/constants.dart';
import 'package:ente_strings/ente_strings.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/ui/components/gradient_button.dart";
import "package:share_plus/share_plus.dart";

class RecoveryKeyDialogLocker extends StatefulWidget {
  final String recoveryKey;
  final Function()? onDone;

  const RecoveryKeyDialogLocker({
    super.key,
    required this.recoveryKey,
    this.onDone,
  });

  @override
  State<RecoveryKeyDialogLocker> createState() =>
      _RecoveryKeyDialogLockerState();
}

class _RecoveryKeyDialogLockerState extends State<RecoveryKeyDialogLocker> {
  late final io.File _recoveryKeyFile;
  late final BaseConfiguration _config;

  @override
  void initState() {
    super.initState();
    _config = Configuration.instance;
    _recoveryKeyFile = io.File(
      "${_config.getTempDirectory()}ente-recovery-key.txt",
    );
  }

  @override
  void dispose() {
    // Clean up temp file if it exists
    if (_recoveryKeyFile.existsSync()) {
      _recoveryKeyFile.deleteSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    // Convert recovery key to mnemonic words
    final String recoveryKeyMnemonic =
        bip39.entropyToMnemonic(widget.recoveryKey);

    if (recoveryKeyMnemonic.split(' ').length != mnemonicKeyWordCount) {
      throw AssertionError(
        'Recovery code should have $mnemonicKeyWordCount words',
      );
    }

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
                  title: context.strings.recoveryKey,
                ),
                GestureDetector(
                  onTap: () => _handleClose(),
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
              context.strings.recoveryKeyOnForgotPassword,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary700,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    child: SelectableText(
                      recoveryKeyMnemonic,
                      style: textTheme.body.copyWith(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () => _copyToClipboard(recoveryKeyMnemonic),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: colorScheme.primary500,
                      ),
                      tooltip: 'Copy to clipboard',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.strings.recoveryKeySaveDescription,
              style: textTheme.small.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onTap: () => _shareRecoveryKey(recoveryKeyMnemonic),
                text: 'Share recovery key',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String recoveryKey) async {
    await Clipboard.setData(ClipboardData(text: recoveryKey));
    if (mounted) {
      showShortToast(
        context,
        context.strings.recoveryKeyCopiedToClipboard,
      );
    }
  }

  Future<void> _shareRecoveryKey(String recoveryKey) async {
    try {
      if (_recoveryKeyFile.existsSync()) {
        await _recoveryKeyFile.delete();
      }
      _recoveryKeyFile.writeAsStringSync(recoveryKey);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_recoveryKeyFile.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        showShortToast(context, 'Failed to share recovery key');
      }
    }
  }

  void _handleClose() {
    Navigator.of(context).pop();
    if (widget.onDone != null) {
      widget.onDone!();
    }
  }
}

// Helper function to show the recovery key dialog
Future<void> showRecoveryKeyDialogLocker(
  BuildContext context, {
  required String recoveryKey,
  Function()? onDone,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return RecoveryKeyDialogLocker(
        recoveryKey: recoveryKey,
        onDone: onDone,
      );
    },
  );
}
