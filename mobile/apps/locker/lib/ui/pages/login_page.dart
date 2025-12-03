import 'package:dio/dio.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_accounts/models/errors.dart';
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/ui/components/gradient_button.dart";
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
      final enteErrCode = e.response?.data is Map<String, dynamic>
          ? e.response?.data["code"]
          : null;
      if (e.response != null && e.response!.statusCode == 401) {
        _logger.severe('Server reject, failed verify SRP login', e, s);
        await showErrorDialog(
          context,
          context.l10n.incorrectPassword,
          context.l10n.pleaseTryAgain,
        );
      } else {
        _logger.severe('API failure during SRP login ${e.type}', e, s);
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          await showErrorDialog(
            context,
            context.l10n.noInternetConnection,
            context.l10n.checkInternetConnection,
          );
        } else if (enteErrCode != null &&
            enteErrCode == 'LOCKER_REGISTRATION_DISABLED') {
          await showErrorDialog(
            context,
            context.l10n.oops,
            context.l10n.unlockLockerNewUserBody,
          );
        } else if (enteErrCode != null &&
            enteErrCode == 'LOCKER_ROLLOUT_LIMIT') {
          await showErrorDialog(
            context,
            "We're out of beta seats for now",
            "This preview access has reached capacity. We'll be opening it to more users soon.",
          );
        } else {
          await showErrorDialog(
            context,
            context.l10n.somethingWentWrong,
            context.l10n.verificationFailedTryAgain,
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
          title: context.l10n.recreatePassword,
          body: context.l10n.deviceCannotVerifyPassword,
          firstButtonLabel: context.l10n.useRecoveryKey,
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
          context.l10n.oops,
          context.l10n.verificationFailedTryAgain,
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
      firstButtonLabel: context.l10n.contactSupport,
      secondButtonLabel: context.l10n.ok,
    );
    if (dialogChoice!.action == ButtonAction.first) {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@ente.io',
        query:
            'subject=${Uri.encodeComponent(context.l10n.lockerLoginIssueSubject)}',
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
        context.l10n.invalidEmail,
        context.l10n.enterValidEmailFirst,
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
      title: context.l10n.unlockLockerNewUserTitle,
      body: context.l10n.unlockLockerNewUserBody,
      buttonLabel: context.l10n.okay,
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
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        title: Image.asset(
          'assets/locker-logo-blue.png',
          height: 28,
        ),
        centerTitle: true,
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
                          l10n.emailIdLabel,
                          style: textTheme.bodyBold.copyWith(
                            color: colorScheme.textBase,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey("emailInputField"),
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: l10n.emailIdHint,
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
                          l10n.loginPasswordLabel,
                          style: textTheme.bodyBold.copyWith(
                            color: colorScheme.textBase,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey("passwordInputField"),
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            hintText: l10n.loginPasswordHint,
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
                              l10n.forgotPassword,
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
                  text: l10n.logInAction,
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
                        TextSpan(text: '${l10n.dontHaveAccount} '),
                        TextSpan(
                          text: l10n.signUp,
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
