import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:pinput/pin_put/pin_put.dart";

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
  String _confirmPin = "";
  final Configuration _configuration = Configuration.instance;
  final _focusNode = FocusNode();

  final _pinPutDecoration = BoxDecoration(
    border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
    borderRadius: BorderRadius.circular(15.0),
  );

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
    _focusNode.dispose();
    _confirmPinController.dispose();
  }

  Future<void> _confirmPinMatch() async {
    if (widget.pin == _confirmPin) {
      await _configuration.savePin(_confirmPin);
      await showDialogWidget(
        context: context,
        title: 'Pin has been set',
        icon: Icons.lock,
        body: 'Hereafter pin has been required while opening the app.',
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: S.of(context).ok,
            isInAlert: true,
            buttonAction: ButtonAction.first,
          ),
        ],
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      await showDialogWidget(
        context: context,
        title: 'Pin does not match',
        icon: Icons.lock,
        body: 'Please re-enter the pin.',
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: S.of(context).ok,
            isInAlert: true,
            buttonAction: ButtonAction.first,
          ),
        ],
      );
    }
    _confirmPinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 120,
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
                          return CircularProgressIndicator(
                            backgroundColor: colorTheme.fillStrong,
                            value: _confirmPinController.text.length / 4,
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
              'Re-enter to confirm the pin',
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: PinPut(
                fieldsCount: 4,
                controller: _confirmPinController,
                focusNode: _focusNode,
                submittedFieldDecoration: _pinPutDecoration.copyWith(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                selectedFieldDecoration: _pinPutDecoration,
                followingFieldDecoration: _pinPutDecoration.copyWith(
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    color: const Color.fromRGBO(45, 194, 98, 0.5),
                  ),
                ),
                inputDecoration: const InputDecoration(
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none,
                  counterText: '',
                ),
                textStyle: textTheme.h3,
                obscureText: '*',
                onChanged: (String pin) {
                  setState(() {
                    _confirmPin = pin;
                  });
                },
                onSubmit: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ButtonWidget(
                labelText: S.of(context).confirm,
                buttonType: _confirmPin.length == 4
                    ? ButtonType.primary
                    : ButtonType.secondary,
                buttonSize: ButtonSize.large,
                onTap: () => _confirmPinMatch(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
