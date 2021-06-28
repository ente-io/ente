import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/two_factor_recovery_page.dart';
import 'package:pinput/pin_put/pin_put.dart';

class TwoFactorAuthenticationPage extends StatefulWidget {
  final String sessionID;

  const TwoFactorAuthenticationPage(this.sessionID, {Key key})
      : super(key: key);

  @override
  _TwoFactorAuthenticationPageState createState() =>
      _TwoFactorAuthenticationPageState();
}

class _TwoFactorAuthenticationPageState
    extends State<TwoFactorAuthenticationPage> {
  final _pinController = TextEditingController();
  final _pinPutDecoration = BoxDecoration(
    border: Border.all(color: Color.fromRGBO(45, 194, 98, 1.0)),
    borderRadius: BorderRadius.circular(15.0),
  );
  String _code = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "two-factor authentication",
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
          "enter the 6-digit code from\nyour authenticator app",
          style: TextStyle(
            height: 1.4,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        Padding(padding: EdgeInsets.all(32)),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          child: PinPut(
            fieldsCount: 6,
            onSubmit: (String code) {
              _verifyTwoFactorCode(code);
            },
            onChanged: (String pin) {
              setState(() {
                _code = pin;
              });
            },
            controller: _pinController,
            submittedFieldDecoration: _pinPutDecoration.copyWith(
              borderRadius: BorderRadius.circular(20.0),
            ),
            selectedFieldDecoration: _pinPutDecoration,
            followingFieldDecoration: _pinPutDecoration.copyWith(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                color: Color.fromRGBO(45, 194, 98, 0.5),
              ),
            ),
            inputDecoration: InputDecoration(
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              counterText: '',
            ),
            autofocus: true,
          ),
        ),
        Padding(padding: EdgeInsets.all(24)),
        Container(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          width: double.infinity,
          height: 64,
          child: button(
            "authenticate",
            fontSize: 18,
            onPressed: _code.length == 6
                ? () async {
                    _verifyTwoFactorCode(_code);
                  }
                : null,
          ),
        ),
        Padding(padding: EdgeInsets.all(30)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            UserService.instance.recoverTwoFactor(context, widget.sessionID);
          },
          child: Container(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                "lost device?",
                style: TextStyle(
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
