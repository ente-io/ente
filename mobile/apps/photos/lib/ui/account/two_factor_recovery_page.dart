import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import 'package:photos/utils/dialog_util.dart';

class TwoFactorRecoveryPage extends StatefulWidget {
  final String sessionID;
  final String encryptedSecret;
  final String secretDecryptionNonce;
  final TwoFactorType type;

  const TwoFactorRecoveryPage(
    this.type,
    this.sessionID,
    this.encryptedSecret,
    this.secretDecryptionNonce, {
    super.key,
  });

  @override
  State<TwoFactorRecoveryPage> createState() => _TwoFactorRecoveryPageState();
}

class _TwoFactorRecoveryPageState extends State<TwoFactorRecoveryPage> {
  final _recoveryKeyController = TextEditingController();
  String _recoveryKey = '';

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    FloatingActionButtonLocation? fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
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
        title: Text(
          AppLocalizations.of(context).recoverAccount,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _getBody(colorScheme, textTheme),
      floatingActionButton: DynamicFAB(
        key: const ValueKey("recover2FAButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _recoveryKey.isNotEmpty,
        buttonText: AppLocalizations.of(context).recover,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          await UserService.instance.removeTwoFactor(
            context,
            widget.type,
            widget.sessionID,
            _recoveryKeyController.text,
            widget.encryptedSecret,
            widget.secretDecryptionNonce,
          );
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            TextInputWidgetV2(
              label: AppLocalizations.of(context).recoveryKey,
              hintText: AppLocalizations.of(context).enterYourRecoveryKey,
              textEditingController: _recoveryKeyController,
              autoCorrect: false,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              onChange: (value) {
                final hasKey = value.isNotEmpty;
                if ((_recoveryKey.isNotEmpty) != hasKey) {
                  setState(() {
                    _recoveryKey = value;
                  });
                } else {
                  _recoveryKey = value;
                }
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ButtonWidgetV2(
                buttonType: ButtonTypeV2.link,
                labelText: AppLocalizations.of(context).noRecoveryKey,
                buttonSize: ButtonSizeV2.small,
                onTap: () async {
                  // ignore: unawaited_futures
                  showErrorDialog(
                    context,
                    AppLocalizations.of(context).contactSupport,
                    AppLocalizations.of(context).dropSupportEmail(
                      supportEmail: "support@ente.io",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
