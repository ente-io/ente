import "dart:convert";

import 'package:ente_crypto/ente_crypto.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_sodium/flutter_sodium.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/settings/lock_screen/custom_pin_keypad.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_confirm_pin.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_options.dart";
import "package:photos/utils/lock_screen_settings.dart";
import 'package:pinput/pinput.dart';

class LockScreenPin extends StatefulWidget {
  const LockScreenPin({
    super.key,
    this.isChangingLockScreenSettings = false,
    this.isAuthenticatingOnAppLaunch = false,
    this.isAuthenticatingForInAppChange = false,
    this.authPin,
  });

  /// [isChangingLockScreenSettings] Authentication required for changing lock screen settings.
  /// Set to true when the app requires the user to authenticate before allowing
  /// changes to the lock screen settings.
  final bool isChangingLockScreenSettings;

  /// [isAuthenticatingOnAppLaunch] Authentication required on app launch.
  /// Set to true when the app requires the user to authenticate immediately upon opening.
  final bool isAuthenticatingOnAppLaunch;

  /// [isAuthenticatingForInAppChange] Authentication required for in-app changes (e.g., email, password).
  /// Set to true when the app requires the to authenticate for sensitive actions like email, password changes.
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

  @override
  void initState() {
    super.initState();
    invalidAttemptsCount = _lockscreenSetting.getInvalidAttemptCount();
  }

  @override
  void dispose() {
    super.dispose();
    _pinController.dispose();
  }

  Future<bool> confirmPinAuth(String code) async {
    final Uint8List? salt = await _lockscreenSetting.getSalt();
    final hash = cryptoPwHash({
      "password": utf8.encode(code),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

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

  Future<void> _confirmPin(String code) async {
    if (widget.isChangingLockScreenSettings) {
      await confirmPinAuth(code);
      return;
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => LockScreenConfirmPin(pin: code),
        ),
      );
      _pinController.clear();
    }
  }

  final _pinPutDecoration = PinTheme(
    height: 48,
    width: 48,
    padding: const EdgeInsets.only(top: 6.0),
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
            Navigator.of(context).pop(false);
          },
          icon: Icon(
            Icons.arrow_back,
            color: colorTheme.tabIcon,
          ),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? _getBody(colorTheme, textTheme, isPortrait: true)
              : SingleChildScrollView(
                  child: _getBody(colorTheme, textTheme, isPortrait: false),
                );
        },
      ),
    );
  }

  Widget _getBody(
    EnteColorScheme colorTheme,
    EnteTextTheme textTheme, {
    required bool isPortrait,
  }) {
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
                    valueListenable: _pinController,
                    builder: (context, value, child) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: _pinController.text.length / 4,
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
                IconButtonWidget(
                  size: 30,
                  icon: Icons.lock,
                  iconButtonType: IconButtonType.primary,
                  iconColor: colorTheme.tabIcon,
                ),
              ],
            ),
          ),
          Text(
            widget.isChangingLockScreenSettings
                ? S.of(context).enterPin
                : S.of(context).setNewPin,
            style: textTheme.bodyBold,
          ),
          const Padding(padding: EdgeInsets.all(12)),
          Pinput(
            length: 4,
            showCursor: false,
            useNativeKeyboard: false,
            controller: _pinController,
            defaultPinTheme: _pinPutDecoration,
            submittedPinTheme: _pinPutDecoration.copyWith(
              textStyle: textTheme.h3Bold,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorTheme.fillBase,
                ),
              ),
            ),
            followingPinTheme: _pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: colorTheme.fillMuted,
                ),
              ),
            ),
            focusedPinTheme: _pinPutDecoration,
            errorPinTheme: _pinPutDecoration.copyWith(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
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
          isPortrait
              ? const Spacer()
              : const Padding(padding: EdgeInsets.all(12)),
          CustomPinKeypad(controller: _pinController),
        ],
      ),
    );
  }
}
