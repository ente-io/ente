import "dart:convert";

import 'package:ente_crypto/ente_crypto.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_sodium/flutter_sodium.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/dynamic_fab.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_confirm_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_options.dart";
import "package:photos/utils/lock_screen_settings.dart";

class LockScreenPassword extends StatefulWidget {
  const LockScreenPassword({
    super.key,
    this.isChangingLockScreenSettings = false,
    this.isAuthenticatingOnAppLaunch = false,
    this.isAuthenticatingForInAppChange = false,
    this.authPass,
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

  final _lockscreenSetting = LockScreenSettings.instance;
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
            buttonText: S.of(context).next,
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
                      child: CircularProgressIndicator(
                        color: colorTheme.fillFaintPressed,
                        value: 1,
                        strokeWidth: 1.5,
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
                    ? S.of(context).enterPassword
                    : S.of(context).setNewPassword,
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

  Future<bool> _confirmPasswordAuth(String inputtedPassword) async {
    final Uint8List? salt = await _lockscreenSetting.getSalt();
    final hash = cryptoPwHash({
      "password": utf8.encode(inputtedPassword),
      "salt": salt,
      "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
      "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
    });

    if (widget.authPass == base64Encode(hash)) {
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
      if (widget.isAuthenticatingOnAppLaunch) {
        invalidAttemptsCount++;
        await _lockscreenSetting.setInvalidAttemptCount(invalidAttemptsCount);
        if (invalidAttemptsCount > 4) {
          Navigator.of(context).pop(false);
        }
      }

      await HapticFeedback.vibrate();
      throw Exception("Incorrect password");
    }
  }

  Future<void> _confirmPassword() async {
    if (widget.isChangingLockScreenSettings) {
      await _confirmPasswordAuth(_passwordController.text);
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
}
