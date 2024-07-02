import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/settings/lock_screen/custom_pin_keypad.dart";
import "package:photos/utils/lock_screen_settings.dart";
import "package:pinput/pinput.dart";

class LockScreenConfirmPin extends StatefulWidget {
  const LockScreenConfirmPin({super.key, required this.pin});
  final String pin;
  @override
  State<LockScreenConfirmPin> createState() => _LockScreenConfirmPinState();
}

class _LockScreenConfirmPinState extends State<LockScreenConfirmPin> {
  final _confirmPinController = TextEditingController(text: null);

  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
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
  void dispose() {
    super.dispose();
    _confirmPinController.dispose();
  }

  void _onKeyTap(String number) {
    _confirmPinController.text += number;
    return;
  }

  void _onBackspace() {
    if (_confirmPinController.text.isNotEmpty) {
      _confirmPinController.text = _confirmPinController.text
          .substring(0, _confirmPinController.text.length - 1);
    }
    return;
  }

  Future<void> _confirmPinMatch() async {
    if (widget.pin == _confirmPinController.text) {
      await _lockscreenSetting.setPin(_confirmPinController.text);

      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
      return;
    }
    await HapticFeedback.vibrate();
    _confirmPinController.clear();
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

  Widget _getBody(colorTheme, textTheme, {required bool isPortrait}) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                            backgroundColor: colorTheme.fillStrong,
                            value: value,
                            color: colorTheme.primary400,
                            strokeWidth: 1.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: IconButtonWidget(
                    size: 30,
                    icon: Icons.lock,
                    iconButtonType: IconButtonType.primary,
                    iconColor: colorTheme.tabIcon,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Re-enter PIN',
            style: textTheme.bodyBold,
          ),
          const Padding(padding: EdgeInsets.all(12)),
          Pinput(
            length: 4,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            controller: _confirmPinController,
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
                  color: colorTheme.fillBase,
                ),
              ),
              textStyle:
                  textTheme.h3Bold.copyWith(color: colorTheme.warning400),
            ),
            errorText: '',
            obscureText: true,
            obscuringCharacter: '*',
            validator: (value) {
              if (value == widget.pin) {
                return null;
              }
              return 'PIN does not match';
            },
            onCompleted: (value) async {
              await _confirmPinMatch();
            },
          ),
          isPortrait
              ? const Spacer()
              : const Padding(padding: EdgeInsets.all(12)),
          CustomPinKeypad(controller: _confirmPinController),
        ],
      ),
    );
  }
}
