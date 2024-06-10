import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_confirm_password.dart";

class LockScreenOptionPassword extends StatefulWidget {
  const LockScreenOptionPassword({
    super.key,
    this.isAuthenticating = false,
    this.authPass,
  });
  final bool isAuthenticating;
  final String? authPass;
  @override
  State<LockScreenOptionPassword> createState() =>
      _LockScreenOptionPasswordState();
}

class _LockScreenOptionPasswordState extends State<LockScreenOptionPassword> {
  final _passwordController = TextEditingController(text: null);
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
    super.dispose();
    _focusNode.dispose();
  }

  Future<bool> confirmPasswordAuth(String code) async {
    if (widget.authPass == code) {
      Navigator.of(context).pop(true);
      return true;
    }
    Navigator.of(context).pop(false);
    return false;
  }

  Future<void> _confirmPassword() async {
    if (widget.isAuthenticating) {
      await confirmPasswordAuth(_passwordController.text);
      return;
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => LockScreenOptionConfirmPassword(
            password: _passwordController.text,
          ),
        ),
      );
      _passwordController.clear();
    }
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
              widget.isAuthenticating ? 'Enter Password' : 'Set new Password',
              textAlign: TextAlign.center,
              style: textTheme.bodyBold,
            ),
            const Padding(padding: EdgeInsets.all(24)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextInputWidget(
                hintText: S.of(context).password,
                borderRadius: 2,
                isClearable: true,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.words,
                textEditingController: _passwordController,
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
