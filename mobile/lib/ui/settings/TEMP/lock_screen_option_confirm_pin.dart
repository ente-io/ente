import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:pinput/pinput.dart";

class LockScreenOptionConfirmPin extends StatefulWidget {
  const LockScreenOptionConfirmPin({super.key, required this.pin});
  final String pin;
  @override
  State<LockScreenOptionConfirmPin> createState() =>
      _LockScreenOptionConfirmPinState();
}

class _LockScreenOptionConfirmPinState
    extends State<LockScreenOptionConfirmPin> {
  final _confirmPinController = TextEditingController(text: null);
  final Configuration _configuration = Configuration.instance;
  final _focusNode = FocusNode();
  final _pinPutDecoration = PinTheme(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
      borderRadius: BorderRadius.circular(15.0),
    ),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _confirmPinController.dispose();
  }

  Future<void> _confirmPinMatch() async {
    if (widget.pin == _confirmPinController.text) {
      await _configuration.setPin(_confirmPinController.text);

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
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    FloatingActionButtonLocation? fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
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
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        buttonText: S.of(context).confirm,
        isFormValid: _confirmPinController.text.isNotEmpty,
        onPressedFunction: () async {
          await _confirmPinMatch();
          FocusScope.of(context).unfocus();
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
      body: Center(
        child: Column(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(70, 0, 70, 0),
              child: Pinput(
                length: 4,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                controller: _confirmPinController,
                focusNode: _focusNode,
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
                  } else {
                    return 'PIN does not match';
                  }
                },
                onSubmitted: (value) {
                  _confirmPinMatch();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
