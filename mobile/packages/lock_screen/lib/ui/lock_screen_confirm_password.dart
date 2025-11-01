import "package:ente_lock_screen/lock_screen_config.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/buttons/dynamic_fab.dart";
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
    final config = LockScreenConfig.current;
    final isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

    FloatingActionButtonLocation? fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      backgroundColor: config.getBackgroundColor(colorTheme),
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        backgroundColor: config.getBackgroundColor(colorTheme),
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
        centerTitle: config.showTitle,
        title: config.titleWidget,
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: config.showTitle ? 16.0 : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: config.showTitle ? 40 : 0),
                config.iconBuilder(context, null),
                SizedBox(height: config.showTitle ? 24 : 0),
                Text(
                  context.strings.reEnterPassword,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyBold,
                ),
                const Padding(padding: EdgeInsets.all(12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextInputWidget(
                    hintText: context.strings.password,
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
      ),
    );
  }
}
