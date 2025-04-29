import 'package:email_validator/email_validator.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/common/dynamic_fab.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_strength/password_strength.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
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
  final _passwordController1 = TextEditingController();
  final _passwordController2 = TextEditingController();
  final Color _validFieldValueColor = const Color.fromARGB(51, 157, 45, 194);

  String? _email;
  String? _password;
  String _cnfPassword = '';
  String _referralSource = '';
  double _passwordStrength = 0.0;
  bool _emailIsValid = false;
  bool _hasAgreedToTOS = true;
  bool _hasAgreedToE2E = false;
  bool _password1Visible = false;
  bool _password2Visible = false;
  bool _passwordsMatch = false;

  final _password1FocusNode = FocusNode();
  final _password2FocusNode = FocusNode();
  bool _password1InFocus = false;
  bool _password2InFocus = false;
  bool _passwordIsValid = false;

  @override
  void initState() {
    _email = _config.getEmail();
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
    super.initState();
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

    final appBar = AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Theme.of(context).iconTheme.color,
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Material(
        type: MaterialType.transparency,
        child: StepProgressIndicator(
          totalSteps: 4,
          currentStep: 1,
          selectedColor: Theme.of(context).colorScheme.alternativeColor,
          roundedEdges: const Radius.circular(10),
          unselectedColor:
              Theme.of(context).colorScheme.stepProgressUnselectedColor,
        ),
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: appBar,
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _isFormValid(),
        buttonText: context.l10n.createAccount,
        onPressedFunction: () {
          UserService.instance.setEmail(_email!);
          _config.setVolatilePassword(_passwordController1.text);
          UserService.instance.setRefSource(_referralSource);
          UserService.instance.sendOtt(
            context,
            _email!,
            isCreateAccountScreen: true,
            purpose: "signup",
          );
          FocusScope.of(context).unfocus();
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    var passwordStrengthText = context.l10n.weakStrength;
    var passwordStrengthColor = Colors.redAccent;
    if (_passwordStrength > kStrongPasswordStrengthThreshold) {
      passwordStrengthText = context.l10n.strongStrength;
      passwordStrengthColor = Colors.greenAccent;
    } else if (_passwordStrength > kMildPasswordStrengthThreshold) {
      passwordStrengthText = context.l10n.moderateStrength;
      passwordStrengthColor = Colors.orangeAccent;
    }
    return Column(
      children: [
        Expanded(
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Text(
                    context.l10n.createNewAccount,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.titleMedium,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      fillColor: _emailIsValid ? _validFieldValueColor : null,
                      filled: true,
                      hintText: context.l10n.email,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixIcon: _emailIsValid
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: Theme.of(context)
                                  .inputDecorationTheme
                                  .focusedBorder!
                                  .borderSide
                                  .color,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _email = value.trim();
                      if (_emailIsValid != EmailValidator.validate(_email!)) {
                        setState(() {
                          _emailIsValid = EmailValidator.validate(_email!);
                        });
                      }
                    },
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    //initialValue: _email,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(4)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    controller: _passwordController1,
                    obscureText: !_password1Visible,
                    enableSuggestions: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      fillColor:
                          _passwordIsValid ? _validFieldValueColor : null,
                      filled: true,
                      hintText: context.l10n.password,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
                          : _passwordIsValid
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
                    focusNode: _password1FocusNode,
                    onChanged: (password) {
                      if (password != _password) {
                        setState(() {
                          _password = password;
                          _passwordStrength =
                              estimatePasswordStrength(password);
                          _passwordIsValid = _passwordStrength >=
                              kMildPasswordStrengthThreshold;
                          _passwordsMatch = _password == _cnfPassword;
                        });
                      }
                    },
                    onEditingComplete: () {
                      _password1FocusNode.unfocus();
                      _password2FocusNode.requestFocus();
                      TextInput.finishAutofillContext();
                    },
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
                    onEditingComplete: () => TextInput.finishAutofillContext(),
                    decoration: InputDecoration(
                      fillColor: _passwordsMatch && _passwordIsValid
                          ? _validFieldValueColor
                          : null,
                      filled: true,
                      hintText: context.l10n.confirmPassword,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
                        _cnfPassword = cnfPassword;
                        if (_password != null || _password != '') {
                          _passwordsMatch = _password == _cnfPassword;
                        }
                      });
                    },
                  ),
                ),
                Opacity(
                  opacity: (_password != '') && _password1InFocus ? 1 : 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      context.l10n.passwordStrength(passwordStrengthText),
                      style: TextStyle(
                        color: passwordStrengthColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: Text(
                    context.l10n.hearUsWhereTitle,
                    style: getEnteTextTheme(context).smallFaint,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: InputDecoration(
                      fillColor: null,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixIcon: InkWell(
                        onTap: () {
                          showToast(
                            context,
                            context.l10n.hearUsExplanation,
                          );
                        },
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: getEnteColorScheme(context).strokeMuted,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _referralSource = value.trim();
                    },
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const Divider(thickness: 1),
                const SizedBox(height: 12),
                _getAgreement(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container _getAgreement() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          _getTOSAgreement(),
          _getPasswordAgreement(),
        ],
      ),
    );
  }

  Widget _getTOSAgreement() {
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
            value: _hasAgreedToTOS,
            side: CheckboxTheme.of(context).side,
            onChanged: (value) {
              setState(() {
                _hasAgreedToTOS = value!;
              });
            },
          ),
          Expanded(
            child: StyledText(
              text: context.l10n.signUpTerms,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontSize: 12),
              tags: {
                'u-terms': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) =>
                      PlatformUtil.openWebView(
                    context,
                    context.l10n.termsOfServicesTitle,
                    "https://ente.io/terms",
                  ),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                'u-policy': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) =>
                      PlatformUtil.openWebView(
                    context,
                    context.l10n.privacyPolicyTitle,
                    "https://ente.io/privacy",
                  ),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPasswordAgreement() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasAgreedToE2E = !_hasAgreedToE2E;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Checkbox(
            value: _hasAgreedToE2E,
            side: CheckboxTheme.of(context).side,
            onChanged: (value) {
              setState(() {
                _hasAgreedToE2E = value!;
              });
            },
          ),
          Expanded(
            child: StyledText(
              text: context.l10n.ackPasswordLostWarning,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontSize: 12),
              tags: {
                'underline': StyledTextActionTag(
                  (String? text, Map<String?, String?> attrs) =>
                      PlatformUtil.openWebView(
                    context,
                    context.l10n.encryption,
                    "https://ente.io/architecture",
                  ),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
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
        _hasAgreedToE2E &&
        _passwordIsValid;
  }
}
