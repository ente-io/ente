import "dart:convert";
import "dart:io";

import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_lock_screen/lock_screen_config.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/custom_pin_keypad.dart";
import "package:ente_lock_screen/ui/lock_screen_confirm_pin.dart";
import "package:ente_lock_screen/ui/lock_screen_options.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:pinput/pinput.dart';

/// [isChangingLockScreenSettings] Authentication required for changing lock screen settings.
/// Set to true when the app requires the user to authenticate before allowing
/// changes to the lock screen settings.

/// [isAuthenticatingOnAppLaunch] Authentication required on app launch.
/// Set to true when the app requires the user to authenticate immediately upon opening.

/// [isAuthenticatingForInAppChange] Authentication required for in-app changes (e.g., email, password).
/// Set to true when the app requires the to authenticate for sensitive actions like email, password changes.

class LockScreenPin extends StatefulWidget {
  const LockScreenPin({
    super.key,
    this.isChangingLockScreenSettings = false,
    this.isAuthenticatingOnAppLaunch = false,
    this.isAuthenticatingForInAppChange = false,
    this.authPin,
  });

  final bool isAuthenticatingOnAppLaunch;
  final bool isChangingLockScreenSettings;
  final bool isAuthenticatingForInAppChange;
  final String? authPin;
  @override
  State<LockScreenPin> createState() => _LockScreenPinState();
}

class _LockScreenPinState extends State<LockScreenPin> {
  final _pinController = TextEditingController(text: null);

  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  bool isPinValid = false;
  int invalidAttemptsCount = 0;
  bool isPlatformDesktop = false;
  @override
  void initState() {
    super.initState();
    isPlatformDesktop =
        Platform.isLinux || Platform.isMacOS || Platform.isWindows;
    invalidAttemptsCount = _lockscreenSetting.getInvalidAttemptCount();
  }

  @override
  void dispose() {
    super.dispose();
    _pinController.dispose();
  }

  Future<bool> confirmPinAuth(String inputtedPin) async {
    final Uint8List? salt = await _lockscreenSetting.getSalt();
    final hash = cryptoPwHash(
      utf8.encode(inputtedPin),
      salt!,
      sodium.crypto.pwhash.memLimitInteractive,
      sodium.crypto.pwhash.opsLimitSensitive,
      sodium,
    );
    if (widget.authPin == base64Encode(hash)) {
      invalidAttemptsCount = 0;
      await _lockscreenSetting.setInvalidAttemptCount(0);
      widget.isAuthenticatingOnAppLaunch ||
              widget.isAuthenticatingForInAppChange
          ? Navigator.of(context).pop(true)
          : Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LockScreenOptions(),
              ),
            );
      return true;
    } else {
      setState(() {
        isPinValid = true;
      });
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 75));
      _pinController.clear();
      setState(() {
        isPinValid = false;
      });

      if (widget.isAuthenticatingOnAppLaunch) {
        invalidAttemptsCount++;
        await _lockscreenSetting.setInvalidAttemptCount(invalidAttemptsCount);
        if (invalidAttemptsCount > 4) {
          Navigator.of(context).pop(false);
        }
      }
      return false;
    }
  }

  Future<void> _confirmPin(String inputtedPin) async {
    if (widget.isChangingLockScreenSettings) {
      await confirmPinAuth(inputtedPin);
      return;
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              LockScreenConfirmPin(pin: inputtedPin),
        ),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final config = LockScreenConfig.current;

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
          : CustomPinKeypad(controller: _pinController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SingleChildScrollView(
        child: _getBody(colorTheme, textTheme, pinPutDecoration, config),
      ),
    );
  }

  Widget _getBody(
    EnteColorScheme colorTheme,
    EnteTextTheme textTheme,
    PinTheme pinPutDecoration,
    LockScreenConfig config,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: config.showTitle ? 24.0 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: config.showTitle ? 40 : 0),
            config.iconBuilder(context, _pinController),
            SizedBox(height: config.showTitle ? 24 : 0),
            Text(
              widget.isChangingLockScreenSettings
                  ? context.strings.enterAppLockPin
                  : context.strings.setNewPin,
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            Pinput(
              length: 4,
              showCursor: false,
              useNativeKeyboard: isPlatformDesktop,
              controller: _pinController,
              autofocus: true,
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
              forceErrorState: isPinValid,
              obscureText: true,
              obscuringCharacter: '*',
              errorText: '',
              onCompleted: (value) async {
                await _confirmPin(_pinController.text);
              },
            ),
          ],
        ),
      ),
    );
  }
}
