import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:pinput/pinput.dart";

class OTTVerificationPage extends StatefulWidget {
  final String email;
  final bool isChangeEmail;
  final bool isCreateAccountScreen;
  final bool isResetPasswordScreen;

  const OTTVerificationPage(
    this.email, {
    this.isChangeEmail = false,
    this.isCreateAccountScreen = false,
    this.isResetPasswordScreen = false,
    super.key,
  });

  @override
  State<OTTVerificationPage> createState() => _OTTVerificationPageState();
}

class _OTTVerificationPageState extends State<OTTVerificationPage> {
  final _pinController = TextEditingController();
  String _code = "";

  Future<void> _onVerifyPressed() async {
    if (widget.isChangeEmail) {
      await UserService.instance.changeEmail(
        context,
        widget.email,
        _pinController.text,
      );
    } else {
      await UserService.instance.verifyEmail(
        context,
        _pinController.text,
        isResettingPasswordScreen: widget.isResetPasswordScreen,
      );
    }
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
          "ente",
          style: textTheme.h3Bold.copyWith(
            fontFamily: "Montserrat",
          ),
        ),
        centerTitle: true,
      ),
      body: _getBody(colorScheme, textTheme),
      floatingActionButton: DynamicFAB(
        key: const ValueKey("verifyOttButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _code.length == 6,
        buttonText: AppLocalizations.of(context).verify,
        onPressedFunction: _onVerifyPressed,
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    final defaultPinTheme = PinTheme(
      height: 52,
      width: 48,
      textStyle: textTheme.body.copyWith(color: colorScheme.textBase),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.strokeMuted),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.greenBase, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      textStyle: textTheme.h3Bold.copyWith(color: colorScheme.greenBase),
      decoration: BoxDecoration(
        color: colorScheme.greenLight,
        border: Border.all(color: colorScheme.greenBase, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'assets/ott.png',
                height: 96,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)
                  .weHaveSentCodeTo(email: widget.email),
              style: textTheme.body.copyWith(color: colorScheme.textBase),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isResetPasswordScreen
                  ? AppLocalizations.of(context).toResetVerifyEmail
                  : AppLocalizations.of(context).checkInboxAndSpamFolder,
              style: textTheme.body.copyWith(color: colorScheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Center(
              child: Pinput(
                length: 6,
                controller: _pinController,
                autofocus: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                followingPinTheme: defaultPinTheme,
                keyboardType: TextInputType.number,
                onChanged: (String pin) {
                  setState(() {
                    _code = pin;
                  });
                },
                onCompleted: (value) {
                  if (value.length == 6) {
                    _onVerifyPressed();
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ButtonWidgetV2(
                buttonType: ButtonTypeV2.link,
                labelText: AppLocalizations.of(context).resendCode,
                buttonSize: ButtonSizeV2.small,
                onTap: () async {
                  // ignore: unawaited_futures
                  UserService.instance.sendOtt(
                    context,
                    widget.email,
                    isCreateAccountScreen: widget.isCreateAccountScreen,
                    isResetPasswordScreen: widget.isResetPasswordScreen,
                    isChangeEmail: widget.isChangeEmail,
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
