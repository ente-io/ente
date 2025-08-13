import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/buttons/dynamic_fab.dart";
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/components/text_input_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class LockScreenConfirmPassword extends StatefulWidget {
  const LockScreenConfirmPassword({
    super.key,
    required this.password,
  });
  final String password;

  @override
  State<LockScreenConfirmPassword> createState() =>
      _LockScreenConfirmPasswordState();
}

class _LockScreenConfirmPasswordState extends State<LockScreenConfirmPassword> {
  final _confirmPasswordController = TextEditingController(text: null);
  final LockScreenSettings _lockscreenSetting = LockScreenSettings.instance;
  final _focusNode = FocusNode();
  final _isFormValid = ValueNotifier<bool>(false);
  final _submitNotifier = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _submitNotifier.dispose();
    _focusNode.dispose();
    _isFormValid.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirmPasswordMatch() async {
    if (widget.password == _confirmPasswordController.text) {
      await _lockscreenSetting.setPassword(_confirmPasswordController.text);

      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
      return;
    }
    await HapticFeedback.vibrate();
    throw Exception("Incorrect password");
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
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            color: colorTheme.textBase,
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFormValid,
        builder: (context, isFormValid, child) {
          return DynamicFAB(
            isKeypadOpen: isKeypadOpen,
            buttonText: context.strings.confirm,
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
                      icon: Icons.lock,
                      iconButtonType: IconButtonType.primary,
                      iconColor: colorTheme.textBase,
                    ),
                  ],
                ),
              ),
              Text(
                context.strings.reEnterPassword,
                style: textTheme.bodyBold,
              ),
              const Padding(padding: EdgeInsets.all(12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextInputWidget(
                  hintText: context.strings.confirmPassword,
                  autoFocus: true,
                  textCapitalization: TextCapitalization.none,
                  isPasswordInput: true,
                  shouldSurfaceExecutionStates: false,
                  onChange: (p0) {
                    _confirmPasswordController.text = p0;
                    _isFormValid.value =
                        _confirmPasswordController.text.isNotEmpty;
                  },
                  onSubmit: (p0) {
                    return _confirmPasswordMatch();
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
