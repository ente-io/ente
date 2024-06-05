import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_confirm_password.dart";

class LockScreenOptionPassword extends StatefulWidget {
  const LockScreenOptionPassword({super.key});

  @override
  State<LockScreenOptionPassword> createState() =>
      _LockScreenOptionPasswordState();
}

class _LockScreenOptionPasswordState extends State<LockScreenOptionPassword> {
  final _passwordController = TextEditingController(text: null);
  String password = "";
  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmPassword() async {
    if (password.length > 8) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => LockScreenOptionConfirmPassword(
            password: password,
          ),
        ),
      );
    } else {
      await showDialogWidget(
        context: context,
        title: 'Password must have at least 8 characters',
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
              S.of(context).enterPasswordToLockApp,
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(24)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextInputWidget(
                hintText: S.of(context).password,
                borderRadius: 2,
                isClearable: true,
                textCapitalization: TextCapitalization.words,
                textEditingController: _passwordController,
                prefixIcon: Icons.lock_outline,
                isPasswordInput: true,
                onChange: (String p0) {
                  setState(() {
                    password = p0;
                  });
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ButtonWidget(
                labelText: S.of(context).next,
                buttonType: password.length > 8
                    ? ButtonType.primary
                    : ButtonType.secondary,
                buttonSize: ButtonSize.large,
                onTap: () => _confirmPassword(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
