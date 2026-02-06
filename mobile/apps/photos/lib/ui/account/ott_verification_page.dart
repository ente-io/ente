import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
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

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      textStyle: textTheme.body.copyWith(color: colorScheme.greenBase),
      decoration: BoxDecoration(
        color: colorScheme.greenLight,
        border: Border.all(color: colorScheme.greenBase, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ButtonWidgetV2(
              key: const ValueKey("verifyOttButton"),
              buttonType: ButtonTypeV2.primary,
              labelText: AppLocalizations.of(context).verify,
              isDisabled: _code.length != 6,
              onTap: () async {
                if (widget.isChangeEmail) {
                  // ignore: unawaited_futures
                  UserService.instance.changeEmail(
                    context,
                    widget.email,
                    _pinController.text,
                  );
                } else {
                  // ignore: unawaited_futures
                  UserService.instance.verifyEmail(
                    context,
                    _pinController.text,
                    isResettingPasswordScreen: widget.isResetPasswordScreen,
                  );
                }
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}
