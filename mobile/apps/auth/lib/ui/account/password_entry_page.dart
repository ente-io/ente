import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/key_gen_result.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/ui/account/recovery_key_page.dart';
import 'package:ente_auth/ui/common/dynamic_fab.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/home_page.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:password_strength/password_strength.dart';
import 'package:styled_text/styled_text.dart';

enum PasswordEntryMode {
  set,
  update,
  reset,
}

class PasswordEntryPage extends StatefulWidget {
  final PasswordEntryMode mode;

  const PasswordEntryPage({required this.mode, super.key});

  @override
  State<PasswordEntryPage> createState() => _PasswordEntryPageState();
}

class _PasswordEntryPageState extends State<PasswordEntryPage> {
  static const kMildPasswordStrengthThreshold = 0.4;
  static const kStrongPasswordStrengthThreshold = 0.7;

  final _logger = Logger((_PasswordEntryPageState).toString());
  final _passwordController1 = TextEditingController(),
      _passwordController2 = TextEditingController();
  final Color _validFieldValueColor = const Color.fromRGBO(45, 194, 98, 0.2);
  String? _volatilePassword;
  String _passwordInInputBox = '';
  String _passwordInInputConfirmationBox = '';
  double _passwordStrength = 0.0;
  bool _password1Visible = false;
  bool _password2Visible = false;
  final _password1FocusNode = FocusNode();
  final _password2FocusNode = FocusNode();
  bool _password1InFocus = false;
  bool _password2InFocus = false;

  bool _passwordsMatch = false;
  bool _isPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _volatilePassword = Configuration.instance.getVolatilePassword();
    if (_volatilePassword != null) {
      Future.delayed(
        Duration.zero,
        () => _showRecoveryCodeDialog(
          _volatilePassword!,
          usingVolatilePassword: true,
        ),
      );
    }
    _password1FocusNode.addListener(() {
      setState(() {
        _password1InFocus = _password1FocusNode.hasFocus;
      });
    });
    _password2FocusNode.addListener(() {
      setState(() {
        _password2InFocus = _password2FocusNode.hasFocus;
      });
    });
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

    String title = context.l10n.setPasswordTitle;
    if (widget.mode == PasswordEntryMode.update) {
      title = context.l10n.changePasswordTitle;
    } else if (widget.mode == PasswordEntryMode.reset) {
      title = context.l10n.resetPasswordTitle;
    } else if (_volatilePassword != null) {
      title = context.l10n.encryptionKeys;
    }
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        leading: widget.mode == PasswordEntryMode.reset
            ? Container()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Theme.of(context).iconTheme.color,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
        elevation: 0,
      ),
      body: _getBody(title),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _passwordsMatch && _isPasswordValid,
        buttonText: title,
        onPressedFunction: () {
          if (widget.mode == PasswordEntryMode.set) {
            _showRecoveryCodeDialog(_passwordController1.text);
          } else {
            _updatePassword();
          }
          FocusScope.of(context).unfocus();
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody(String buttonTextAndHeading) {
    final email = Configuration.instance.getEmail();
    var passwordStrengthText = context.l10n.weakStrength;
    var passwordStrengthColor = Colors.redAccent;
    if (_passwordStrength > kStrongPasswordStrengthThreshold) {
      passwordStrengthText = context.l10n.strongStrength;
      passwordStrengthColor = Colors.greenAccent;
    } else if (_passwordStrength > kMildPasswordStrengthThreshold) {
      passwordStrengthText = context.l10n.moderateStrength;
      passwordStrengthColor = Colors.orangeAccent;
    }
    if (_volatilePassword != null) {
      return Container();
    }
    return Column(
      children: [
        Expanded(
          child: AutofillGroup(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    child: Text(
                      buttonTextAndHeading,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.mode == PasswordEntryMode.set
                          ? context.l10n.enterPasswordToEncrypt
                          : context.l10n.enterNewPasswordToEncrypt,
                      textAlign: TextAlign.start,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontSize: 14),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: StyledText(
                      text: context.l10n.passwordWarning,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontSize: 14),
                      tags: {
                        'underline': StyledTextTag(
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      },
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(12)),
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextFormField(
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) {
                        do {
                          FocusScope.of(context).nextFocus();
                        } while (FocusScope.of(context).focusedChild!.context ==
                            null);
                      },
                      decoration: InputDecoration(
                        fillColor:
                            _isPasswordValid ? _validFieldValueColor : null,
                        filled: true,
                        hintText: context.l10n.password,
                        contentPadding: const EdgeInsets.all(20),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        suffixIcon: _password1InFocus
                            ? IconButton(
                                icon: Icon(
                                  _password1Visible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Theme.of(context).iconTheme.color,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _password1Visible = !_password1Visible;
                                  });
                                },
                              )
                            : _isPasswordValid
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(context)
                                        .inputDecorationTheme
                                        .focusedBorder!
                                        .borderSide
                                        .color,
                                  )
                                : null,
                      ),
                      obscureText: !_password1Visible,
                      controller: _passwordController1,
                      autofocus: false,
                      autocorrect: false,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (password) {
                        setState(() {
                          _passwordInInputBox = password;
                          _passwordStrength =
                              estimatePasswordStrength(password);
                          _isPasswordValid = _passwordStrength >=
                              kMildPasswordStrengthThreshold;
                          _passwordsMatch = _passwordInInputBox ==
                              _passwordInInputConfirmationBox;
                        });
                      },
                      textInputAction: TextInputAction.next,
                      focusNode: _password1FocusNode,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      controller: _passwordController2,
                      obscureText: !_password2Visible,
                      autofillHints: const [AutofillHints.newPassword],
                      onEditingComplete: () =>
                          TextInput.finishAutofillContext(),
                      decoration: InputDecoration(
                        fillColor:
                            _passwordsMatch ? _validFieldValueColor : null,
                        filled: true,
                        hintText: context.l10n.confirmPassword,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        suffixIcon: _password2InFocus
                            ? IconButton(
                                icon: Icon(
                                  _password2Visible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Theme.of(context).iconTheme.color,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _password2Visible = !_password2Visible;
                                  });
                                },
                              )
                            : _passwordsMatch
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(context)
                                        .inputDecorationTheme
                                        .focusedBorder!
                                        .borderSide
                                        .color,
                                  )
                                : null,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      focusNode: _password2FocusNode,
                      onChanged: (cnfPassword) {
                        setState(() {
                          _passwordInInputConfirmationBox = cnfPassword;
                          if (_passwordInInputBox != '') {
                            _passwordsMatch = _passwordInInputBox ==
                                _passwordInInputConfirmationBox;
                          }
                        });
                      },
                    ),
                  ),
                  Opacity(
                    opacity: (_passwordInInputBox != '') && _password1InFocus
                        ? 1
                        : 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        context.l10n.passwordStrength(passwordStrengthText),
                        style: TextStyle(
                          color: passwordStrengthColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      PlatformUtil.openWebView(
                        context,
                        context.l10n.howItWorks,
                        "https://ente.io/architecture",
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RichText(
                        text: TextSpan(
                          text: context.l10n.howItWorks,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(20)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updatePassword() async {
    final logOutFromOthers = await logOutFromOtherDevices(context);
    final dialog =
        createProgressDialog(context, context.l10n.generatingEncryptionKeys);
    await dialog.show();
    try {
      final result = await Configuration.instance
          .getAttributesForNewPassword(_passwordController1.text);
      await UserService.instance.updateKeyAttributes(
        result.item1,
        result.item2,
        logoutOtherDevices: logOutFromOthers,
      );
      await dialog.hide();
      showShortToast(context, context.l10n.passwordChangedSuccessfully);
      Navigator.of(context).pop();
      if (widget.mode == PasswordEntryMode.reset) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      // ignore: unawaited_futures
      showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<bool> logOutFromOtherDevices(BuildContext context) async {
    bool logOutFromOther = true;
    await showChoiceDialog(
      context,
      title: context.l10n.signOutFromOtherDevices,
      body: context.l10n.signOutOtherBody,
      isDismissible: false,
      firstButtonLabel: context.l10n.signOutOtherDevices,
      firstButtonType: ButtonType.critical,
      firstButtonOnTap: () async {
        logOutFromOther = true;
      },
      secondButtonLabel: context.l10n.doNotSignOut,
      secondButtonOnTap: () async {
        logOutFromOther = false;
      },
    );
    return logOutFromOther;
  }

  Future<void> _showRecoveryCodeDialog(
    String password, {
    bool usingVolatilePassword = false,
  }) async {
    final l10n = context.l10n;
    final dialog =
        createProgressDialog(context, l10n.generatingEncryptionKeysTitle);
    await dialog.show();
    try {
      if (usingVolatilePassword) {
        _logger.info('Using volatile password');
      }
      final KeyGenResult result =
          await Configuration.instance.generateKey(password);
      Configuration.instance.resetVolatilePassword();
      await dialog.hide();
      onDone() async {
        final dialog = createProgressDialog(context, l10n.pleaseWait);
        await dialog.show();
        try {
          await UserService.instance.setAttributes(result);
          await dialog.hide();
          Configuration.instance.resetVolatilePassword();
          // ignore: unawaited_futures
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return const HomePage();
              },
            ),
            (route) => route.isFirst,
          );
        } catch (e, s) {
          _logger.severe(e, s);
          await dialog.hide();
          // ignore: unawaited_futures
          showGenericErrorDialog(
            context: context,
            error: e,
          );
        }
      }

      // ignore: unawaited_futures
      routeToPage(
        context,
        RecoveryKeyPage(
          result.privateKeyAttributes.recoveryKey,
          context.l10n.continueLabel,
          showAppBar: false,
          isDismissible: false,
          onDone: onDone,
          showProgressBar: true,
        ),
      );
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      if (e is UnsupportedError) {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          context.l10n.insecureDevice,
          context.l10n.sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease,
        );
      } else {
        // ignore: unawaited_futures
        showGenericErrorDialog(
          context: context,
          error: e,
        );
      }
    }
  }
}
