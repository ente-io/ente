import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
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
    _focusNode.dispose();
    // print("CONFIRM DISPOSE");
    super.dispose();
  }

  Future<void> _confirmPasswordMatch() async {
    if (widget.password == _confirmPasswordController.text) {
      await _configuration.savePassword(_confirmPasswordController.text);
      await showDialogWidget(
        context: context,
        title: 'Password has been set',
        icon: Icons.lock,
        body: 'Hereafter password has been required while opening the app.',
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
        title: 'Password does not match',
        icon: Icons.lock,
        body: 'Please re-enter the password.',
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
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
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
              'Enter the password to lock the app',
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(24)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextInputWidget(
                hintText: S.of(context).confirmPassword,
                borderRadius: 2,
                focusNode: _focusNode,
                isClearable: true,
                textCapitalization: TextCapitalization.words,
                textEditingController: _confirmPasswordController,
                prefixIcon: Icons.lock_outline,
                isPasswordInput: true,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ButtonWidget(
                labelText: 'Next',
                buttonType: ButtonType.secondary,
                buttonSize: ButtonSize.large,
                onTap: () => _confirmPasswordMatch(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
