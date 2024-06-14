import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";

class LockScreenOptionConfirmPassword extends StatefulWidget {
  const LockScreenOptionConfirmPassword({
    super.key,
    required this.password,
  });
  final String password;

  @override
  State<LockScreenOptionConfirmPassword> createState() =>
      _LockScreenOptionConfirmPasswordState();
}

class _LockScreenOptionConfirmPasswordState
    extends State<LockScreenOptionConfirmPassword> {
  final _confirmPasswordController = TextEditingController(text: null);
  final Configuration _configuration = Configuration.instance;
  final _focusNode = FocusNode();
  final _isFormValid = ValueNotifier<bool>(false);

  final _submitNotifier = ValueNotifier(false);
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
    _submitNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _confirmPasswordMatch() async {
    if (widget.password == _confirmPasswordController.text) {
      await _configuration.setPassword(_confirmPasswordController.text);

      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
      return;
    }
    await HapticFeedback.vibrate();
    _confirmPasswordController.clear();
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
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            color: colorTheme.tabIcon,
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFormValid,
        builder: (context, isFormValid, child) {
          return DynamicFAB(
            isKeypadOpen: isKeypadOpen,
            buttonText: S.of(context).confirm,
            isFormValid: isFormValid,
            onPressedFunction: () async {
              await _confirmPasswordMatch();
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
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
                      child: CircularProgressIndicator(
                        backgroundColor: colorTheme.fillStrong,
                        value: 1,
                        strokeWidth: 1.5,
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
              'Re-enter Password',
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(24)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextInputWidget(
                hintText: S.of(context).confirmPassword,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.words,
                textEditingController: _confirmPasswordController,
                isPasswordInput: true,
                onChange: (p0) {
                  _isFormValid.value =
                      _confirmPasswordController.text.isNotEmpty;
                  _submitNotifier.value = !_submitNotifier.value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
