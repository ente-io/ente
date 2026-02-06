import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import 'package:photos/ui/lifecycle_event_handler.dart';
import "package:pinput/pinput.dart";

class TwoFactorAuthenticationPage extends StatefulWidget {
  final String sessionID;

  const TwoFactorAuthenticationPage(this.sessionID, {super.key});

  @override
  State<TwoFactorAuthenticationPage> createState() =>
      _TwoFactorAuthenticationPageState();
}

class _TwoFactorAuthenticationPageState
    extends State<TwoFactorAuthenticationPage> {
  final _pinController = TextEditingController();
  String _code = "";
  late LifecycleEventHandler _lifecycleEventHandler;

  @override
  void initState() {
    _lifecycleEventHandler = LifecycleEventHandler(
      resumeCallBack: () async {
        if (mounted) {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          if (data != null && data.text != null && data.text!.length == 6) {
            _pinController.text = data.text!;
          }
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleEventHandler);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleEventHandler);
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
        title: Text(
          AppLocalizations.of(context).twoFAVerification,
          style: textTheme.largeBold,
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
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).twoFAVerification,
              style: textTheme.body.copyWith(color: colorScheme.textBase),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)
                  .enterThe6digitCodeFromnyourAuthenticatorApp,
              style: textTheme.body.copyWith(color: colorScheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Pinput(
                length: 6,
                onCompleted: (String code) {
                  _verifyTwoFactorCode(code);
                },
                onChanged: (String pin) {
                  setState(() {
                    _code = pin;
                  });
                },
                autofocus: true,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                followingPinTheme: defaultPinTheme,
              ),
            ),
            const Spacer(),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText: AppLocalizations.of(context).verify,
              isDisabled: _code.length != 6,
              onTap: () async {
                await _verifyTwoFactorCode(_code);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ButtonWidgetV2(
                buttonType: ButtonTypeV2.link,
                labelText: AppLocalizations.of(context).lostDevice,
                buttonSize: ButtonSizeV2.small,
                onTap: () async {
                  // ignore: unawaited_futures
                  UserService.instance.recoverTwoFactor(
                    context,
                    widget.sessionID,
                    TwoFactorType.totp,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyTwoFactorCode(String code) async {
    await UserService.instance.verifyTwoFactor(context, widget.sessionID, code);
  }
}
