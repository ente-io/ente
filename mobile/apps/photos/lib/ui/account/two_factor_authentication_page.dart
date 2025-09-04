import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/account/user_service.dart';
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

  final _pinPutDecoration = PinTheme(
    height: 45,
    width: 45,
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
      borderRadius: BorderRadius.circular(15.0),
    ),
  );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).twofactorAuthenticationPageTitle,
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          AppLocalizations.of(context)
              .enterThe6digitCodeFromnyourAuthenticatorApp,
          style: const TextStyle(
            height: 1.4,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const Padding(padding: EdgeInsets.all(32)),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
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
            defaultPinTheme: _pinPutDecoration,
            submittedPinTheme: _pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(
                  color: const Color.fromRGBO(45, 194, 98, 0.5),
                ),
              ),
            ),
            followingPinTheme: _pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: const Color.fromRGBO(45, 194, 98, 0.5),
                ),
              ),
            ),
            focusedPinTheme: _pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: const Color.fromRGBO(45, 194, 98, 0.5),
                ),
              ),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(24)),
        Container(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            onPressed: _code.length == 6
                ? () async {
                    await _verifyTwoFactorCode(_code);
                  }
                : null,
            child: Text(AppLocalizations.of(context).verify),
          ),
        ),
        const Padding(padding: EdgeInsets.all(30)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            UserService.instance.recoverTwoFactor(
              context,
              widget.sessionID,
              TwoFactorType.totp,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Text(
                AppLocalizations.of(context).lostDevice,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyTwoFactorCode(String code) async {
    await UserService.instance.verifyTwoFactor(context, widget.sessionID, code);
  }
}
