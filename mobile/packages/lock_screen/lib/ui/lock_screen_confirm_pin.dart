import "dart:io";

import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/custom_pin_keypad.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:pinput/pinput.dart";

class LockScreenConfirmPin extends StatefulWidget {
  const LockScreenConfirmPin({super.key, required this.pin});
  final String pin;
  @override
  State<LockScreenConfirmPin> createState() => _LockScreenConfirmPinState();
}

class _LockScreenConfirmPinState extends State<LockScreenConfirmPin> {
  final _confirmPinController = TextEditingController(text: null);
  bool isConfirmPinValid = false;
  bool isPlatformDesktop = false;
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;

  @override
  void initState() {
    super.initState();
    isPlatformDesktop =
        Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  @override
  void dispose() {
    super.dispose();
    _confirmPinController.dispose();
  }

  Future<void> _confirmPinMatch() async {
    if (widget.pin == _confirmPinController.text) {
      await _lockscreenSetting.setPin(_confirmPinController.text);

      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      isConfirmPinValid = true;
    });
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 75));
    _confirmPinController.clear();
    setState(() {
      isConfirmPinValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          icon: Icon(
            Icons.arrow_back,
            color: colorTheme.textBase,
          ),
        ),
      ),
      floatingActionButton: isPlatformDesktop
          ? null
          : CustomPinKeypad(controller: _confirmPinController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: _getBody(colorTheme, textTheme),
      ),
    );
  }

  Widget _getBody(colorTheme, textTheme) {
    final pinPutDecoration = PinTheme(
      height: 48,
      width: 48,
      padding: const EdgeInsets.only(top: 6.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
        borderRadius: BorderRadius.circular(15.0),
      ),
    );

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade500.withValues(alpha: 0.2),
                        Colors.grey.shade50.withValues(alpha: 0.1),
                        Colors.grey.shade400.withValues(alpha: 0.2),
                        Colors.grey.shade300.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorTheme.backgroundBase,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 75,
                  width: 75,
                  child: ValueListenableBuilder(
                    valueListenable: _confirmPinController,
                    builder: (context, value, child) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: _confirmPinController.text.length / 4,
                        ),
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 250),
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          backgroundColor: colorTheme.fillFaintPressed,
                          value: value,
                          color: colorTheme.primary400,
                          strokeWidth: 1.5,
                        ),
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.lock,
                  color: colorTheme.textBase,
                  size: 30,
                ),
              ],
            ),
          ),
          Text(
            context.strings.reEnterPin,
            style: textTheme.bodyBold,
          ),
          const Padding(padding: EdgeInsets.all(12)),
          Pinput(
            length: 4,
            showCursor: false,
            useNativeKeyboard: isPlatformDesktop,
            autofocus: true,
            controller: _confirmPinController,
            defaultPinTheme: pinPutDecoration,
            submittedPinTheme: pinPutDecoration.copyWith(
              textStyle: textTheme.h3Bold,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorTheme.fillBase,
                ),
              ),
            ),
            followingPinTheme: pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorTheme.fillMuted,
                ),
              ),
            ),
            focusedPinTheme: pinPutDecoration,
            errorPinTheme: pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorTheme.warning400,
                ),
              ),
            ),
            errorText: '',
            obscureText: true,
            obscuringCharacter: '*',
            forceErrorState: isConfirmPinValid,
            onCompleted: (value) async {
              await _confirmPinMatch();
            },
          ),
        ],
      ),
    );
  }
}
