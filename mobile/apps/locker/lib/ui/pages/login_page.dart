import 'package:dio/dio.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_accounts/models/errors.dart';
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/ui/components/new_account_dialog.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Logger _logger = Logger('LoginPageState');
  String? _email;
  bool _emailIsValid = false;
  bool _passwordVisible = false;
  bool _isLoggingIn = false;
  Color? _emailInputFieldColor;
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _email = Configuration.instance.getEmail();
    if (_email != null) {
      _emailIsValid = EmailValidator.validate(_email!);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Prevent multiple simultaneous login attempts
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
    });

    FocusScope.of(context).unfocus();
    final dialog = createProgressDialog(
      context,
      context.l10n.pleaseWait,
      isDismissible: true,
    );
    await dialog.show();

    try {
      await UserService.instance.setEmail(_email!);
      Configuration.instance.resetVolatilePassword();
      SrpAttributes? attr;
      bool isEmailVerificationEnabled = true;
      try {
        attr = await UserService.instance.getSrpAttributes(_email!);
        isEmailVerificationEnabled = attr.isEmailMFAEnabled;
      } catch (e) {
        if (e is! SrpSetupNotCompleteError) {
          _logger.severe('Error getting SRP attributes', e);
        }
      }

      await dialog.hide();

      final password = _passwordController.text;
      if (attr != null && !isEmailVerificationEnabled && password.isNotEmpty) {
        await _verifyPassword(attr, password);
      } else {
        await UserService.instance.sendOtt(
          context,
          _email!,
          isCreateAccountScreen: false,
          purpose: 'login',
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe('Login error', e);
      await showGenericErrorDialog(context: context, error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _verifyPassword(
    SrpAttributes srpAttributes,
    String password,
  ) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.pleaseWait,
      isDismissible: true,
    );
    await dialog.show();

    try {
      await UserService.instance.verifyEmailViaPassword(
        context,
        srpAttributes,
        password,
        dialog,
      );
    } on DioException catch (e, s) {
      await dialog.hide();
      if (e.response != null && e.response!.statusCode == 401) {
        _logger.severe('Server reject, failed verify SRP login', e, s);
        await showErrorDialog(
          context,
          'Incorrect Password',
          'Please try again',
        );
      } else {
        _logger.severe('API failure during SRP login ${e.type}', e, s);
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          await showErrorDialog(
            context,
            'No Internet Connection',
            'Please check your internet connection and try again',
          );
        } else {
          await showErrorDialog(
            context,
            'Something went wrong',
            'Verification failed, please try again',
          );
        }
      }
    } catch (e, s) {
      _logger.info('error during loginViaPassword', e);
      await dialog.hide();
      if (e is LoginKeyDerivationError) {
        _logger.severe('loginKey derivation error', e, s);
        await UserService.instance.sendOtt(
          context,
          _email!,
          isCreateAccountScreen: true,
        );
        return;
      } else if (e is KeyDerivationError) {
        final dialogChoice = await showChoiceDialog(
          context,
          title: 'Recreate password',
          body:
              'Your device does not have enough memory to verify your password',
          firstButtonLabel: 'Use recovery key',
        );
        if (dialogChoice!.action == ButtonAction.first) {
          await UserService.instance.sendOtt(
            context,
            _email!,
            isResetPasswordScreen: true,
          );
        }
        return;
      } else {
        _logger.severe('unexpected error while verifying password', e, s);
        await _showContactSupportDialog(
          context,
          'Oops',
          'Verification failed, please try again',
        );
      }
    }
  }

  Future<void> _showContactSupportDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final dialogChoice = await showChoiceDialog(
      context,
      title: title,
      body: message,
      firstButtonLabel: 'Contact support',
      secondButtonLabel: 'OK',
    );
    if (dialogChoice!.action == ButtonAction.first) {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@ente.io',
        query: 'subject=Locker Login Issue',
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    }
  }

  void _handleForgotPassword() async {
    if (_email == null || !_emailIsValid) {
      await showErrorDialog(
        context,
        'Invalid Email',
        'Please enter a valid email address first',
      );
      return;
    }

    await UserService.instance.sendOtt(
      context,
      _email!,
      isResetPasswordScreen: true,
    );
  }

  void _handleSignUp() {
    showCreateNewAccountDialog(
      context,
      title: "Unlock locker with a paid plan",
      body:
          "Locker is available only to Ente photos paid users. Upgrade to a paid plan from Photos to use Locker",
      buttonLabel: "Checkout Ente Photos",
      assetPath: "assets/file_lock.png",
      icon: const SizedBox.shrink(),
    );
  }

  void updateEmail(String value) {
    _email = value.trim();
    _emailIsValid = EmailValidator.validate(_email!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        title: Text(
          "Locker",
          style: textTheme.h3Bold.copyWith(
            color: colorScheme.primary700,
          ),
        ),
        backgroundColor: colorScheme.backgroundBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.primary700,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AutofillGroup(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          "Email id",
                          style: textTheme.bodyBold.copyWith(
                            color: colorScheme.textBase,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey("emailInputField"),
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: "Enter your email id",
                            hintStyle: textTheme.body.copyWith(
                              color: colorScheme.textMuted,
                            ),
                            fillColor:
                                _emailInputFieldColor ?? colorScheme.fillFaint,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: _emailIsValid
                                ? Icon(
                                    Icons.check,
                                    size: 20,
                                    color: colorScheme.primary700,
                                  )
                                : null,
                          ),
                          style: textTheme.body.copyWith(
                            color: colorScheme.textBase,
                          ),
                          onChanged: (value) {
                            setState(() {
                              updateEmail(value);
                              if (_emailIsValid) {
                                _emailInputFieldColor = colorScheme.primary300
                                    .withValues(alpha: 0.1);
                              } else {
                                _emailInputFieldColor = null;
                              }
                            });
                          },
                          onFieldSubmitted: _emailIsValid
                              ? (value) => _passwordFocusNode.requestFocus()
                              : null,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          initialValue: _email,
                          autofocus: true,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Password",
                          style: textTheme.bodyBold.copyWith(
                            color: colorScheme.textBase,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey("passwordInputField"),
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: textTheme.body.copyWith(
                              color: colorScheme.textMuted,
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: colorScheme.fillFaint,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colorScheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          style: textTheme.body.copyWith(
                            color: colorScheme.textBase,
                          ),
                          controller: _passwordController,
                          autofocus: false,
                          autocorrect: false,
                          obscureText: !_passwordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          focusNode: _passwordFocusNode,
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              "Forgot Password?",
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
              ),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _emailIsValid &&
                          _passwordController.text.isNotEmpty &&
                          !_isLoggingIn
                      ? () async {
                          await _handleLogin();
                        }
                      : null,
                  text: "Log in",
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
