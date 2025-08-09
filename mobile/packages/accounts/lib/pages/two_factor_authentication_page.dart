import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/lifecycle_event_handler.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    final pinPutDecoration = PinTheme(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary500),
        borderRadius: BorderRadius.circular(15.0),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.strings.twoFactorAuthTitle,
        ),
      ),
      body: _getBody(pinPutDecoration),
    );
  }

  Widget _getBody(PinTheme pinPutDecoration) {
    final colorScheme = getEnteColorScheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          context.strings.enterCodeHint,
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
            controller: _pinController,
            submittedPinTheme: pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: colorScheme.primary500.withOpacity(0.5),
                ),
              ),
            ),
            defaultPinTheme: pinPutDecoration,
            followingPinTheme: pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorScheme.primary500.withOpacity(0.5),
                ),
              ),
            ),
            autofocus: true,
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
            child: Text(context.strings.verify),
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
                context.strings.lostDeviceTitle,
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
