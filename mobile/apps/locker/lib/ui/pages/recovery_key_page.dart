import 'package:ente_ui/components/text_input_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import "package:locker/ui/components/gradient_button.dart";

class RecoveryKeyPage extends StatefulWidget {
  const RecoveryKeyPage({super.key});

  @override
  State<RecoveryKeyPage> createState() => _RecoveryKeyPageState();
}

class _RecoveryKeyPageState extends State<RecoveryKeyPage> {
  String? _recoveryKey;
  final ValueNotifier<bool> _submitNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _submitNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // TODO: Implement actual recovery key validation and login logic
    // For now, just simulate a delay
    await Future.delayed(const Duration(seconds: 1));
  }

  void _handleForgotRecoveryKey() {
    // TODO: Implement forgot recovery key logic
  }

  void _handleSignUp() {
    // TODO: Implement sign up navigation or dialog
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Locker",
          style: textTheme.h3.copyWith(
            color: colorScheme.primary700,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      TextInputWidget(
                        label: "Recovery key",
                        hintText: "Enter your recovery key",
                        initialValue: _recoveryKey,
                        autoFocus: true,
                        textCapitalization: TextCapitalization.none,
                        onChange: (value) {
                          setState(() {
                            _recoveryKey = value;
                          });
                        },
                        submitNotifier: _submitNotifier,
                        onSubmit: (value) async {
                          _recoveryKey = value;
                          await _handleLogin();
                        },
                        shouldSurfaceExecutionStates: false,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotRecoveryKey,
                          child: Text(
                            "Forgot Recovery key?",
                            style: textTheme.bodyBold.copyWith(
                              color: colorScheme.primary700,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _recoveryKey != null && _recoveryKey!.isNotEmpty
                      ? () async {
                          _submitNotifier.value = !_submitNotifier.value;
                        }
                      : null,
                  text: "Log In",
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _handleSignUp,
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.body.copyWith(
                        color: colorScheme.textBase,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign up",
                          style: textTheme.bodyBold.copyWith(
                            color: colorScheme.primary700,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
