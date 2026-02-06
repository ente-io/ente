import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/share_util.dart';
import 'package:share_plus/share_plus.dart';

class RecoveryKeyPage extends StatefulWidget {
  final String recoveryKey;
  final String doneText;
  final Function()? onDone;
  final String? title;
  final String? text;
  final String? subText;
  final bool isOnboarding;

  const RecoveryKeyPage(
    this.recoveryKey,
    this.doneText, {
    super.key,
    this.onDone,
    this.title,
    this.text,
    this.subText,
    this.isOnboarding = false,
  });

  @override
  State<RecoveryKeyPage> createState() => _RecoveryKeyPageState();
}

class _RecoveryKeyPageState extends State<RecoveryKeyPage> {
  final _recoveryKeyFile = File(
    Configuration.instance.getTempDirectory() + "ente-recovery-key.txt",
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final String recoveryKey = bip39.entropyToMnemonic(widget.recoveryKey);
    if (recoveryKey.split(' ').length != mnemonicKeyWordCount) {
      throw AssertionError(
        'recovery code should have $mnemonicKeyWordCount words',
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.content,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _getBody(recoveryKey, colorScheme, textTheme),
    );
  }

  Widget _getBody(
    String recoveryKey,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? AppLocalizations.of(context).recoveryKey,
                    style: textTheme.h3Bold,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/recovery_key.png',
                      width: 101,
                      height: 82,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.text ??
                        AppLocalizations.of(context)
                            .recoveryKeyOnForgotPassword,
                    textAlign: TextAlign.center,
                    style: textTheme.body.copyWith(
                      color: colorScheme.textBase,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subText ??
                        AppLocalizations.of(context).recoveryKeySaveDescription,
                    textAlign: TextAlign.center,
                    style: textTheme.body.copyWith(
                      color: colorScheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.greenBase,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recoveryKey,
                                style: textTheme.body.copyWith(
                                  color: Colors.white,
                                  height: 24 / 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: recoveryKey),
                                );
                                showShortToast(
                                  context,
                                  AppLocalizations.of(context)
                                      .recoveryKeyCopiedToClipboard,
                                );
                              },
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCopy01,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ButtonWidgetV2(
                          buttonType: ButtonTypeV2.secondary,
                          shouldStickToLightTheme: true,
                          labelText: AppLocalizations.of(context).shareKey,
                          onTap: () async {
                            await _shareRecoveryKey(recoveryKey);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isOnboarding)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: ButtonWidgetV2(
                buttonType: ButtonTypeV2.secondary,
                labelText: widget.doneText,
                onTap: () async {
                  await _saveKeys();
                },
              ),
            ),
          ),
      ],
    );
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    _recoveryKeyFile.writeAsStringSync(recoveryKey);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_recoveryKeyFile.path)],
        sharePositionOrigin: shareButtonRect(context, null),
      ),
    );
  }

  Future<void> _saveKeys() async {
    Navigator.of(context).pop();
    if (_recoveryKeyFile.existsSync()) {
      await _recoveryKeyFile.delete();
    }
    widget.onDone!();
  }
}
