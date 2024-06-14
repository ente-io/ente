import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_confirm_pin.dart";
import 'package:pinput/pinput.dart';

class LockScreenOptionPin extends StatefulWidget {
  const LockScreenOptionPin({
    super.key,
    this.isAuthenticating = false,
    this.authPin,
  });

  final bool isAuthenticating;
  final String? authPin;
  @override
  State<LockScreenOptionPin> createState() => _LockScreenOptionPinState();
}

class _LockScreenOptionPinState extends State<LockScreenOptionPin> {
  final _pinController = TextEditingController(text: null);
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pinController.dispose();
    _focusNode.dispose();
  }

  Future<bool> confirmPinAuth(String code) async {
    if (widget.authPin == code) {
      Navigator.of(context).pop(true);
      return true;
    }
    await HapticFeedback.vibrate();
    return false;
  }

  Future<void> _confirmPin(String code) async {
    if (widget.isAuthenticating) {
      await confirmPinAuth(code);
      return;
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              LockScreenOptionConfirmPin(pin: code),
        ),
      );
      _pinController.clear();
    }
  }

  final _pinPutDecoration = PinTheme(
    height: 48,
    width: 48,
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
      borderRadius: BorderRadius.circular(15.0),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop(false);
          },
          icon: Icon(
            Icons.arrow_back,
            color: colorTheme.tabIcon,
          ),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 60,
            ),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 75,
                      width: 75,
                      child: ValueListenableBuilder(
                        valueListenable: _pinController,
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            backgroundColor: colorTheme.fillStrong,
                            value: _pinController.text.length / 4,
                            color: colorTheme.primary400,
                            strokeWidth: 1.5,
                          );
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: IconButtonWidget(
                      size: 30,
                      icon: Icons.lock_outline,
                      iconButtonType: IconButtonType.primary,
                      iconColor: colorTheme.tabIcon,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.isAuthenticating ? 'Enter PIN' : 'Set new PIN',
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 0, 70, 0),
                  child: Pinput(
                    length: 4,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    focusNode: _focusNode,
                    controller: _pinController,
                    defaultPinTheme: _pinPutDecoration,
                    submittedPinTheme: _pinPutDecoration.copyWith(
                      textStyle: textTheme.h3Bold,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: colorTheme.fillBase,
                        ),
                      ),
                    ),
                    followingPinTheme: _pinPutDecoration.copyWith(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: colorTheme.fillMuted,
                        ),
                      ),
                    ),
                    focusedPinTheme: _pinPutDecoration,
                    errorPinTheme: _pinPutDecoration.copyWith(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: colorTheme.fillBase,
                        ),
                      ),
                      textStyle: textTheme.h3Bold
                          .copyWith(color: colorTheme.warning400),
                    ),
                    validator: widget.isAuthenticating
                        ? (value) {
                            if (widget.authPin == value) {
                              return null;
                            }
                            return 'Invalid PIN';
                          }
                        : null,
                    autofocus: true,
                    errorText: '',
                    obscureText: true,
                    obscuringCharacter: '*',
                    onCompleted: (value) {
                      FocusScope.of(context).unfocus();
                      _confirmPin(_pinController.text);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
