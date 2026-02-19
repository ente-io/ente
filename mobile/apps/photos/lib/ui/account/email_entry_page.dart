import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:password_strength/password_strength.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import 'package:photos/ui/common/web_page.dart';
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/models/text_input_type_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import "package:styled_text/styled_text.dart";

class EmailEntryPage extends StatefulWidget {
  const EmailEntryPage({super.key});

  @override
  State<EmailEntryPage> createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  static const kMildPasswordStrengthThreshold = 0.4;
  static const kStrongPasswordStrengthThreshold = 0.7;

  final _config = Configuration.instance;
  final _emailController = TextEditingController();
  final _passwordController1 = TextEditingController();
  final _passwordController2 = TextEditingController();

  String? _email;
  String? _password;
  String _cnfPassword = '';
  String _referralSource = '';
  double _passwordStrength = 0.0;
  bool _emailIsValid = false;
  bool _showEmailValidation = false;
  bool _hasAgreedToTOS = false;
  bool _passwordsMatch = false;
  bool _passwordIsValid = false;
  bool _showPasswordStrength = false;
  bool _showConfirmPasswordValidation = false;
  Timer? _emailValidationTimer;
  Timer? _passwordStrengthTimer;
  Timer? _confirmPasswordTimer;

  @override
  void initState() {
    super.initState();
    final storedEmail = _config.getEmail();
    if (storedEmail != null && storedEmail.isNotEmpty) {
      _email = storedEmail;
      _emailController.text = storedEmail;
      _emailIsValid = EmailValidator.validate(storedEmail);
    }
  }

  @override
  void dispose() {
    _emailValidationTimer?.cancel();
    _passwordStrengthTimer?.cancel();
    _confirmPasswordTimer?.cancel();
    _emailController.dispose();
    _passwordController1.dispose();
    _passwordController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.content,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context).createAccount,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _getBody(colorScheme, textTheme),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ButtonWidgetV2(
          key: const ValueKey("createAccountButton"),
          buttonType: ButtonTypeV2.primary,
          labelText: AppLocalizations.of(context).createAccount,
          isDisabled: !_isFormValid(),
          onTap: _isFormValid()
              ? () async {
                  _config.setVolatilePassword(_passwordController1.text);
                  await UserService.instance.setEmail(_email!);
                  await UserService.instance.setRefSource(_referralSource);
                  await UserService.instance.sendOtt(
                    context,
                    _email!,
                    isCreateAccountScreen: true,
                    purpose: "signup",
                  );
                  FocusScope.of(context).unfocus();
                }
              : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _getBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    String? passwordMessage;
    TextInputMessageType passwordMessageType = TextInputMessageType.guide;

    if (_password != null && _password!.isNotEmpty && _showPasswordStrength) {
      if (_passwordStrength > kStrongPasswordStrengthThreshold) {
        passwordMessage = AppLocalizations.of(context).strongPassword;
        passwordMessageType = TextInputMessageType.success;
      } else if (_passwordStrength <= kMildPasswordStrengthThreshold) {
        passwordMessage = AppLocalizations.of(context).weakStrength;
        passwordMessageType = TextInputMessageType.alert;
      }
    }

    String? confirmPasswordMessage;
    TextInputMessageType confirmPasswordMessageType =
        TextInputMessageType.guide;

    if (_cnfPassword.isNotEmpty &&
        _password != null &&
        _password!.isNotEmpty &&
        _showConfirmPasswordValidation) {
      if (_passwordsMatch) {
        confirmPasswordMessage = AppLocalizations.of(context).passwordsMatch;
        confirmPasswordMessageType = TextInputMessageType.success;
      } else {
        confirmPasswordMessage =
            AppLocalizations.of(context).passwordsDontMatch;
        confirmPasswordMessageType = TextInputMessageType.error;
      }
    }

    return AutofillGroup(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 24),
          TextInputWidgetV2(
            label: AppLocalizations.of(context).email,
            hintText: AppLocalizations.of(context).email,
            textEditingController: _emailController,
            keyboardType: TextInputType.emailAddress,
            autoCorrect: false,
            isRequired: true,
            onChange: _onEmailChanged,
            message: _showEmailValidation && !_emailIsValid
                ? AppLocalizations.of(context).invalidEmailAddress
                : null,
            messageType: _showEmailValidation && !_emailIsValid
                ? TextInputMessageType.alert
                : TextInputMessageType.guide,
          ),
          const SizedBox(height: 24),
          TextInputWidgetV2(
            label: AppLocalizations.of(context).password,
            hintText: AppLocalizations.of(context).password,
            textEditingController: _passwordController1,
            isPasswordInput: true,
            isRequired: true,
            autoCorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            message: passwordMessage,
            messageType: passwordMessageType,
            onChange: (password) {
              if (password != _password) {
                _passwordStrengthTimer?.cancel();
                setState(() {
                  _password = password;
                  _passwordStrength = estimatePasswordStrength(password);
                  _passwordIsValid =
                      _passwordStrength >= kMildPasswordStrengthThreshold;
                  _passwordsMatch = _password == _cnfPassword;
                  _showPasswordStrength = false;
                });
                _passwordStrengthTimer = Timer(
                  const Duration(seconds: 1),
                  () {
                    if (mounted) {
                      setState(() {
                        _showPasswordStrength = true;
                      });
                    }
                  },
                );
              }
            },
          ),
          const SizedBox(height: 24),
          TextInputWidgetV2(
            label: AppLocalizations.of(context).confirmPassword,
            hintText: AppLocalizations.of(context).confirmPassword,
            textEditingController: _passwordController2,
            isPasswordInput: true,
            isRequired: true,
            autoCorrect: false,
            autofillHints: const [],
            finishAutofillContextOnEditingComplete: true,
            message: confirmPasswordMessage,
            messageType: confirmPasswordMessageType,
            onChange: (cnfPassword) {
              _confirmPasswordTimer?.cancel();
              setState(() {
                _cnfPassword = cnfPassword;
                _showConfirmPasswordValidation = false;
                if (_password != null && _password!.isNotEmpty) {
                  _passwordsMatch = _password == _cnfPassword;
                }
              });
              _confirmPasswordTimer = Timer(
                const Duration(seconds: 1),
                () {
                  if (mounted) {
                    setState(() {
                      _showConfirmPasswordValidation = true;
                    });
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
          TextInputWidgetV2(
            label: AppLocalizations.of(context).hearUsWhereTitle,
            autoCorrect: false,
            onChange: (value) {
              _referralSource = value.trim();
            },
          ),
          const SizedBox(height: 16),
          _getTOSAgreement(colorScheme, textTheme),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onEmailChanged(String value) {
    _emailValidationTimer?.cancel();

    final trimmed = value.trim();
    final isValid = EmailValidator.validate(trimmed);

    setState(() {
      _email = trimmed;
      _emailIsValid = isValid;
      _showEmailValidation = false;
    });

    if (trimmed.isNotEmpty) {
      _emailValidationTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showEmailValidation = true;
          });
        }
      });
    }
  }

  Widget _getTOSAgreement(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasAgreedToTOS = !_hasAgreedToTOS;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Checkbox(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.greenBase;
              }
              return null;
            }),
            value: _hasAgreedToTOS,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: CheckboxTheme.of(context).side,
            visualDensity: VisualDensity.compact,
            onChanged: (value) {
              setState(() {
                _hasAgreedToTOS = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StyledText(
              text: AppLocalizations.of(context).signUpTerms,
              style: textTheme.small.copyWith(color: colorScheme.textMuted),
              tags: {
                'u-terms': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) =>
                      Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return WebPage(
                          AppLocalizations.of(context).termsOfServicesTitle,
                          "https://ente.io/terms",
                        );
                      },
                    ),
                  ),
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: colorScheme.textMuted,
                  ),
                ),
                'u-policy': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) =>
                      Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return WebPage(
                          AppLocalizations.of(context).privacyPolicyTitle,
                          "https://ente.io/privacy",
                        );
                      },
                    ),
                  ),
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: colorScheme.textMuted,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _emailIsValid &&
        _passwordsMatch &&
        _hasAgreedToTOS &&
        _passwordIsValid;
  }
}
