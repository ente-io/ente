import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_sodium/flutter_sodium.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/settings/lockscreen/lockscreen_confirm_password.dart";
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/lockscreen_setting.dart";

class LockScreenPassword extends StatefulWidget {
  const LockScreenPassword({
    super.key,
    this.isAuthenticating = false,
    this.isLockscreenAuth = false,
    this.authPass,
  });

  /// If [isLockscreenAuth] is true then we are authenticating the user at Lock screen
  /// If [isAuthenticating] is true then we are authenticating the user at Setting screen
  final bool isAuthenticating;
  final bool isLockscreenAuth;
  final String? authPass;
  @override
  State<LockScreenPassword> createState() => _LockScreenPasswordState();
}

class _LockScreenPasswordState extends State<LockScreenPassword> {
  /// _passwordController is disposed by the [TextInputWidget]
  final _passwordController = TextEditingController(text: null);
  final _focusNode = FocusNode();
  final _isFormValid = ValueNotifier<bool>(false);
  final _submitNotifier = ValueNotifier(false);
  int invalidAttemptsCount = 0;

  final LockscreenSetting _lockscreenSetting = LockscreenSetting.instance;
  late String enteredHashedPassword;
  @override
  void initState() {
    super.initState();
    invalidAttemptsCount = _lockscreenSetting.getInvalidAttemptCount();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _submitNotifier.dispose();
    _focusNode.dispose();
    _isFormValid.dispose();
  }

  Future<bool> confirmPasswordAuth(String code) async {
    final Uint8List? salt = await _lockscreenSetting.getSalt();
    final hash = cryptoPwHash({
      "password": utf8.encode(code),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

    enteredHashedPassword = base64Encode(hash);
    if (widget.authPass == enteredHashedPassword) {
      await _lockscreenSetting.setInvalidAttemptCount(0);
      Navigator.of(context).pop(true);
      return true;
    } else {
      if (widget.isLockscreenAuth) {
        invalidAttemptsCount++;
        if (invalidAttemptsCount > 4) {
          await _lockscreenSetting.setInvalidAttemptCount(invalidAttemptsCount);
          Navigator.of(context).pop(false);
        }
      }

      await HapticFeedback.vibrate();
      throw Exception("Incorrect password");
    }
  }

  Future<void> _confirmPassword() async {
    if (widget.isAuthenticating) {
      await confirmPasswordAuth(_passwordController.text);
      return;
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => LockScreenConfirmPassword(
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
    final isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

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
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFormValid,
        builder: (context, isFormValid, child) {
          return DynamicFAB(
            isKeypadOpen: isKeypadOpen,
            buttonText: S.of(context).ok,
            isFormValid: isFormValid,
            onPressedFunction: () async {
              _submitNotifier.value = !_submitNotifier.value;
            },
          );
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
      body: SingleChildScrollView(
        child: Center(
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
                        icon: Icons.lock,
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
              const Padding(padding: EdgeInsets.all(12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextInputWidget(
                  hintText: S.of(context).password,
                  focusNode: _focusNode,
                  enableFillColor: false,
                  textCapitalization: TextCapitalization.none,
                  textEditingController: _passwordController,
                  isPasswordInput: true,
                  shouldSurfaceExecutionStates: false,
                  onChange: (p0) {
                    _isFormValid.value = _passwordController.text.isNotEmpty;
                  },
                  onSubmit: (p0) {
                    return _confirmPassword();
                  },
                  submitNotifier: _submitNotifier,
                ),
              ),
              const Padding(padding: EdgeInsets.all(12)),
            ],
          ),
        ),
      ),
    );
  }
}
