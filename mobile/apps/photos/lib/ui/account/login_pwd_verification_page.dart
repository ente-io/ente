import "package:dio/dio.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/user/srp.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/dynamic_fab.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/email_util.dart";

// LoginPasswordVerificationPage is a page that allows the user to enter their password to verify their identity.
// If the password is correct, then the user is either directed to
// PasswordReentryPage (if the user has not yet set up 2FA) or TwoFactorAuthenticationPage (if the user has set up 2FA).
// In the PasswordReentryPage, the password is auto-filled based on the
// volatile password.
class LoginPasswordVerificationPage extends StatefulWidget {
  final SrpAttributes srpAttributes;

  const LoginPasswordVerificationPage({super.key, required this.srpAttributes});

  @override
  State<LoginPasswordVerificationPage> createState() =>
      _LoginPasswordVerificationPageState();
}

class _LoginPasswordVerificationPageState
    extends State<LoginPasswordVerificationPage> {
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String? email;
  bool _passwordInFocus = false;
  bool _passwordVisible = false;
  final Logger _logger = Logger("LoginPasswordVerificationPage");

  @override
  void initState() {
    super.initState();
    email = Configuration.instance.getEmail();
    if (kDebugMode) {
      _passwordController.text = const String.fromEnvironment("password");
    }
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordInFocus = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

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
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        key: const ValueKey("verifyPasswordButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _passwordController.text.isNotEmpty,
        buttonText: AppLocalizations.of(context).logInLabel,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          await verifyPassword(context, _passwordController.text);
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Future<void> verifyPassword(BuildContext context, String password) async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).pleaseWait,
      isDismissible: true,
    );
    await dialog.show();
    try {
      await UserService.instance.verifyEmailViaPassword(
        context,
        widget.srpAttributes,
        password,
        dialog,
      );
    } on DioException catch (e, s) {
      await dialog.hide();
      if (e.response != null && e.response!.statusCode == 401) {
        _logger.severe('server reject, failed verify SRP login', e, s);
        await _showContactSupportDialog(
          context,
          AppLocalizations.of(context).incorrectPasswordTitle,
          AppLocalizations.of(context).pleaseTryAgain,
        );
      } else {
        _logger.severe('API failure during SRP login ${e.type}', e, s);
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          await _showContactSupportDialog(
            context,
            AppLocalizations.of(context).noInternetConnection,
            AppLocalizations.of(context)
                .pleaseCheckYourInternetConnectionAndTryAgain,
          );
        } else {
          await _showContactSupportDialog(
            context,
            AppLocalizations.of(context).somethingWentWrong,
            AppLocalizations.of(context).verificationFailedPleaseTryAgain,
          );
        }
      }
    } catch (e, s) {
      _logger.info('error during loginViaPassword', e);
      await dialog.hide();
      if (e is LoginKeyDerivationError) {
        _logger.severe('loginKey derivation error', e, s);
        // LoginKey err, perform regular login via ott verification
        await UserService.instance.sendOtt(
          context,
          email!,
          isCreateAccountScreen: true,
        );
        return;
      } else if (e is KeyDerivationError) {
        // device is not powerful enough to perform derive key
        final dialogChoice = await showChoiceDialog(
          context,
          title: AppLocalizations.of(context).recreatePasswordTitle,
          body: AppLocalizations.of(context).recreatePasswordBody,
          firstButtonLabel: AppLocalizations.of(context).useRecoveryKey,
        );
        if (dialogChoice!.action == ButtonAction.first) {
          await UserService.instance.sendOtt(
            context,
            email!,
            isResetPasswordScreen: true,
          );
        }
        return;
      } else {
        _logger.severe('unexpected error while verifying password', e, s);
        await _showContactSupportDialog(
          context,
          AppLocalizations.of(context).oops,
          AppLocalizations.of(context).verificationFailedPleaseTryAgain,
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
      firstButtonLabel: AppLocalizations.of(context).contactSupport,
      secondButtonLabel: AppLocalizations.of(context).ok,
    );
    if (dialogChoice!.action == ButtonAction.first) {
      await sendLogs(
        context,
        AppLocalizations.of(context).contactSupport,
        "support@ente.io",
        postShare: () {},
      );
    }
  }

  Widget _getBody() {
    return Column(
      children: [
        Expanded(
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: Text(
                    AppLocalizations.of(context).enterPassword,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 30,
                    left: 22,
                    right: 20,
                  ),
                  child: Text(
                    email ?? '',
                    style: getEnteTextTheme(context).smallMuted,
                  ),
                ),
                Visibility(
                  // hidden textForm for suggesting auto-fill service for saving
                  // password
                  visible: false,
                  child: TextFormField(
                    autofillHints: const [
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    initialValue: email,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    key: const ValueKey("passwordInputField"),
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).enterYourPassword,
                      filled: true,
                      contentPadding: const EdgeInsets.all(20),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      fillColor: getEnteColorScheme(context).fillFaint,
                      suffixIcon: _passwordInFocus
                          ? IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Theme.of(context).iconTheme.color,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    controller: _passwordController,
                    autofocus: true,
                    autocorrect: false,
                    obscureText: !_passwordVisible,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: _passwordFocusNode,
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    thickness: 1,
                    color: getEnteColorScheme(context).strokeFaint,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await UserService.instance.sendOtt(
                            context,
                            email!,
                            isResetPasswordScreen: true,
                          );
                        },
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).forgotPassword,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final dialog = createProgressDialog(
                            context,
                            AppLocalizations.of(context).pleaseWait,
                          );
                          await dialog.show();
                          await Configuration.instance.logout();
                          await dialog.hide();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).changeEmail,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
