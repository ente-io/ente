import "dart:io";

import "package:ente_lock_screen/lock_screen_config.dart";
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
    final config = LockScreenConfig.current;

    return Scaffold(
      backgroundColor: config.getBackgroundColor(colorTheme),
      appBar: AppBar(
        backgroundColor: config.getBackgroundColor(colorTheme),
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
        centerTitle: config.showTitle,
        title: config.titleWidget,
      ),
      floatingActionButton: isPlatformDesktop
          ? null
          : CustomPinKeypad(controller: _confirmPinController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: _getBody(colorTheme, textTheme, config),
      ),
    );
  }

  Widget _getBody(colorTheme, textTheme, LockScreenConfig config) {
    final pinPutDecoration = PinTheme(
      height: config.pinBoxHeight,
      width: config.pinBoxWidth,
      padding: config.pinBoxPadding,
      decoration: BoxDecoration(
        color: config.getBackgroundColor(colorTheme),
        border: Border.all(
          color: config.getBorderColor(colorTheme),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(config.pinBoxBorderRadius),
      ),
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: config.showTitle ? 24.0 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: config.showTitle ? 40 : 0),
            config.iconBuilder(context, _confirmPinController),
            SizedBox(height: config.showTitle ? 24 : 0),
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
              defaultPinTheme: pinPutDecoration.copyWith(
                textStyle: textTheme.h3Bold,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(config.pinBoxBorderRadius),
                  border: Border.all(
                    color: config.getBorderColor(colorTheme),
                  ),
                ),
              ),
              submittedPinTheme: pinPutDecoration.copyWith(
                textStyle: textTheme.h3Bold.copyWith(
                  color: config.showTitle ? colorTheme.primary700 : null,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(config.pinBoxBorderRadius),
                  border: Border.all(
                    color: config.showTitle
                        ? colorTheme.primary700
                        : colorTheme.fillBase,
                  ),
                ),
              ),
              followingPinTheme: pinPutDecoration.copyWith(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(config.pinBoxBorderRadius),
                  border: Border.all(
                    color: config.getBorderColor(colorTheme),
                  ),
                ),
              ),
              focusedPinTheme: pinPutDecoration.copyWith(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(config.pinBoxBorderRadius),
                  border: Border.all(
                    color: config.showTitle
                        ? colorTheme.fillBase
                        : config.getBorderColor(colorTheme),
                  ),
                ),
              ),
              errorPinTheme: pinPutDecoration.copyWith(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(config.pinBoxBorderRadius),
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
      ),
    );
  }
}
